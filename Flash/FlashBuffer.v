`default_nettype none

module FlashBuffer #(
		parameter SRAM_ADDRESS_SIZE = 9,
		parameter PAGE_INDEX_ADDRESS_SIZE = 3
	)(
		input wire clk,
		input wire rst,

		// Peripheral Bus
		input wire peripheralBus_we,
		input wire peripheralBus_oe,
		input wire[23:0] peripheralBus_address,
		input wire[3:0] peripheralBus_byteSelect,
		input wire[31:0] peripheralBus_dataWrite,
		output reg[31:0] peripheralBus_dataRead,
		output wire peripheralBus_busy,

		// QSPI device
		output wire qspi_enable,
		output wire[23:0] qspi_address,
		output wire qspi_changeAddress,
		output wire qspi_requestData,
		input wire[31:0] qspi_readData,
		input wire qspi_readDataValid,
		input wire qspi_initialised,
		input wire qspi_busy,

		// Flash controller SRAM rw port
		output wire sram_clk0,
		output wire sram_csb0,
		output wire sram_web0,
		output wire[3:0] sram_wmask0,
		output wire[SRAM_ADDRESS_SIZE-1:0] sram_addr0,
		output wire[31:0] sram_din0,
		input wire[31:0] sram_dout0,

		// Wishbone SRAM r port
		output wire sram_clk1,
		output wire sram_csb1,
		output wire[SRAM_ADDRESS_SIZE-1:0] sram_addr1,
		input wire[31:0] sram_dout1
	);

	localparam PAGE_DATA_ADDRESS_SIZE = (SRAM_ADDRESS_SIZE - PAGE_INDEX_ADDRESS_SIZE);
	localparam PAGE_COUNT = (1 << PAGE_INDEX_ADDRESS_SIZE);

	wire automaticPaging;

	wire sramEnable = peripheralBus_oe && (peripheralBus_address[23] == 1'b0) && ((peripheralBus_address[22:SRAM_ADDRESS_SIZE+2] == {(21-SRAM_ADDRESS_SIZE){1'b0}}) || automaticPaging);
	wire registersEnable = peripheralBus_address[23:12] == 12'h800;
	wire[11:0] localAddress = peripheralBus_address[11:0];

	// Register
	// Configuration register 	Default 0x0
	// b00: enable				Default 0x0
	// b00: automatic paging	Default 0x0
	wire[31:0] configurationRegisterOutputData;
	wire configurationRegisterOutputRequest;
	wire[1:0] configuration;
	ConfigurationRegister #(.WIDTH(2), .ADDRESS(12'h000), .DEFAULT(1'b0)) configurationRegister(
		.clk(clk),
		.rst(rst),
		.enable(registersEnable),
		.peripheralBus_we(peripheralBus_we),
		.peripheralBus_oe(peripheralBus_oe),
		.peripheralBus_address(localAddress),
		.peripheralBus_byteSelect(peripheralBus_byteSelect),
		.peripheralBus_dataWrite(peripheralBus_dataWrite),
		.peripheralBus_dataRead(configurationRegisterOutputData),
		.requestOutput(configurationRegisterOutputRequest),
		.currentValue(configuration));

	assign qspi_enable = configuration[0];
	assign automaticPaging = configuration[1];

	// Status register
	// b00: QSPI initialised
	// b01: loading page
	wire[1:0] statusRegisterValue = { qspi_requestData, qspi_initialised };
	wire[31:0] statusRegisterOutputData;
	wire statusRegisterOutputRequest;
	wire statusRegisterBusBusy_nc;
	wire[1:0] statusRegisterWriteData_nc;
	wire statusRegisterWriteDataEnable_nc;
	wire statusRegisterReadDataEnable_nc;
	DataRegister #(.WIDTH(2), .ADDRESS(12'h004)) statusRegister(
		.clk(clk),
		.rst(rst),
		.enable(registersEnable),
		.peripheralBus_we(peripheralBus_we),
		.peripheralBus_oe(peripheralBus_oe),
		.peripheralBus_busy(statusRegisterBusBusy_nc),
		.peripheralBus_address(localAddress),
		.peripheralBus_byteSelect(peripheralBus_byteSelect),
		.peripheralBus_dataWrite(peripheralBus_dataWrite),
		.peripheralBus_dataRead(statusRegisterOutputData),
		.requestOutput(statusRegisterOutputRequest),
		.writeData(statusRegisterWriteData_nc),
		.writeData_en(statusRegisterWriteDataEnable_nc),
		.writeData_busy(1'b0),
		.readData(statusRegisterValue),
		.readData_en(statusRegisterReadDataEnable_nc),
		.readData_busy(1'b0));

	// Current page address 	 Default 0x0
	reg[23:0] currentManualPageAddress;
	wire[31:0] currentPageAddressRegisterOutputData;
	wire currentPageAddressRegisterOutputRequest;
	wire currentPageAddressRegisterBusBusy;
	wire[23:0] currentPageAddressRegisterWriteData;
	wire currentPageAddressRegisterWriteDataEnable;
	wire currentPageAddressRegisterReadDataEnable_nc;
	DataRegister #(.WIDTH(24), .ADDRESS(12'h008)) currentPageAddressRegister(
		.clk(clk),
		.rst(rst),
		.enable(registersEnable),
		.peripheralBus_we(peripheralBus_we),
		.peripheralBus_oe(peripheralBus_oe),
		.peripheralBus_busy(currentPageAddressRegisterBusBusy),
		.peripheralBus_address(localAddress),
		.peripheralBus_byteSelect(peripheralBus_byteSelect),
		.peripheralBus_dataWrite(peripheralBus_dataWrite),
		.peripheralBus_dataRead(currentPageAddressRegisterOutputData),
		.requestOutput(currentPageAddressRegisterOutputRequest),
		.writeData(currentPageAddressRegisterWriteData),
		.writeData_en(currentPageAddressRegisterWriteDataEnable),
		.writeData_busy(!automaticPaging && qspi_busy),
		.readData(currentManualPageAddress),
		.readData_en(currentPageAddressRegisterReadDataEnable_nc),
		.readData_busy(1'b0));

	wire[23:0] nextManualPageAddress = {currentPageAddressRegisterWriteData[23-SRAM_ADDRESS_SIZE-2:0], {(SRAM_ADDRESS_SIZE){1'b0}}, 2'b00};

	always @(posedge clk) begin
		if (rst) begin
			currentManualPageAddress <= 24'b0;
		end else begin
			if (automaticPaging) currentManualPageAddress <= ~24'b0;
			else if (currentPageAddressRegisterWriteDataEnable) currentManualPageAddress <= nextManualPageAddress;
		end
	end

	// Cache status register
	// PAGE_INDEX_ADDRESS_SIZE == 3:
	// 	b00-b07: pageAddressSet
	// 	b08-b15: pageRequestLoad
	// PAGE_INDEX_ADDRESS_SIZE == 4:
	// 	b00-b15: pageAddressSet
	// 	b16-b31: pageRequestLoad
	wire[PAGE_COUNT-1:0] pageAddressSet;
	wire[PAGE_COUNT-1:0] pageRequestLoad;
	wire[31:0] cacheStatusRegisterOutputData;
	wire cacheStatusRegisterOutputRequest;
	wire cacheStatusRegisterBusBusy_nc;
	wire[PAGE_COUNT+PAGE_COUNT-1:0] cacheStatusRegisterWriteData_nc;
	wire cacheStatusRegisterWriteDataEnable_nc;
	wire cacheStatusRegisterReadDataEnable_nc;
	DataRegister #(.WIDTH(PAGE_COUNT + PAGE_COUNT), .ADDRESS(12'h00C)) cacheStatusRegister(
		.clk(clk),
		.rst(rst),
		.enable(registersEnable),
		.peripheralBus_we(peripheralBus_we),
		.peripheralBus_oe(peripheralBus_oe),
		.peripheralBus_busy(cacheStatusRegisterBusBusy_nc),
		.peripheralBus_address(localAddress),
		.peripheralBus_byteSelect(peripheralBus_byteSelect),
		.peripheralBus_dataWrite(peripheralBus_dataWrite),
		.peripheralBus_dataRead(cacheStatusRegisterOutputData),
		.requestOutput(cacheStatusRegisterOutputRequest),
		.writeData(cacheStatusRegisterWriteData_nc),
		.writeData_en(cacheStatusRegisterWriteDataEnable_nc),
		.writeData_busy(1'b0),
		.readData({ pageRequestLoad, pageAddressSet }),
		.readData_en(cacheStatusRegisterReadDataEnable_nc),
		.readData_busy(1'b0));

	// Cache controller
	wire flashCacheReadReady;
	wire sramReadEnable;
	wire sramWriteEnable;
	wire[SRAM_ADDRESS_SIZE-1:0] sramReadAddress;
	wire[SRAM_ADDRESS_SIZE-1:0] sramWriteAddress;
	FlashCache #(
		.ADDRESS_SIZE(24),
		.SRAM_ADDRESS_SIZE(SRAM_ADDRESS_SIZE),
		.PAGE_INDEX_ADDRESS_SIZE(PAGE_INDEX_ADDRESS_SIZE)
	) flashCache (
		.clk(clk),
		.rst(rst),
		.automaticPaging(automaticPaging),
		.manualPageAddressSet(currentPageAddressRegisterWriteDataEnable && !automaticPaging),
		.manualPageAddress(currentPageAddressRegisterWriteData[23-SRAM_ADDRESS_SIZE-2:0]),
		.readEnable(sramEnable),
		.readAddress(peripheralBus_address),
		.readReady(flashCacheReadReady),
		.sramReadEnable(sramReadEnable),
		.sramWriteEnable(sramWriteEnable),
		.sramReadAddress(sramReadAddress),
		.sramWriteAddress(sramWriteAddress),
		.qspi_enable(qspi_enable),
		.qspi_address(qspi_address),
		.qspi_changeAddress(qspi_changeAddress),
		.qspi_requestData(qspi_requestData),
		.qspi_readDataValid(qspi_readDataValid),
		.qspi_initialised(qspi_initialised),
		.qspi_busy(qspi_busy),
		.pageAddressSet(pageAddressSet),
		.pageRequestLoad(pageRequestLoad));

	// Assign peripheral read
	always @(*) begin
		case (1'b1)
			configurationRegisterOutputRequest: peripheralBus_dataRead <= configurationRegisterOutputData;
			statusRegisterOutputRequest: peripheralBus_dataRead <= statusRegisterOutputData;
			currentPageAddressRegisterOutputRequest: peripheralBus_dataRead <= currentPageAddressRegisterOutputData;
			cacheStatusRegisterOutputRequest: peripheralBus_dataRead <= cacheStatusRegisterOutputData;
			flashCacheReadReady: peripheralBus_dataRead <= sram_dout1;
			default: peripheralBus_dataRead <= ~32'b0;
		endcase
	end

	assign peripheralBus_busy = sramEnable ? !flashCacheReadReady : currentPageAddressRegisterBusBusy;

	// Assign sram port
	// Read/write port
	assign sram_clk0 = clk;
	assign sram_csb0 = !sramWriteEnable;	// Active low chip enable
	assign sram_web0 = 1'b0;	// Active low write enable (probably keep as always write)
	assign sram_wmask0 = 4'b1111;
	assign sram_addr0 = sramWriteAddress;
	assign sram_din0 = qspi_readData;

	// Read port
	assign sram_clk1 = clk;
	assign sram_csb1 = !sramReadEnable;
	assign sram_addr1 = sramReadAddress;

endmodule
