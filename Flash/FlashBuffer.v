module FlashBuffer #(
		parameter SRAM_ADDRESS_SIZE = 9
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
		output reg qspi_requestData,
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

	reg[23:0] loadAddress;
	reg[23:0] currentPageAddress;
	reg pageAddressSet;

	reg[SRAM_ADDRESS_SIZE:0] cachedCount;
	wire[SRAM_ADDRESS_SIZE:0] nextCachedCount = cachedCount + 1;
	wire[SRAM_ADDRESS_SIZE:0] cachedCountFinal = { 1'b1, {(SRAM_ADDRESS_SIZE){1'b0}} };

	// Select
	wire sramEnable = peripheralBus_address[23:SRAM_ADDRESS_SIZE+2] == {(22-SRAM_ADDRESS_SIZE){1'b0}};
	wire registersEnable = peripheralBus_address[23:12] == 12'h800;
	wire[11:0] localAddress = peripheralBus_address[11:0];

	wire loadingPage = qspi_enable && qspi_initialised && pageAddressSet && (cachedCount < cachedCountFinal);
	wire wordReady = qspi_enable && qspi_initialised && pageAddressSet && ((peripheralBus_address[SRAM_ADDRESS_SIZE+1:0] < cachedCount) || !loadingPage);

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
	wire automaticPaging = configuration[1];

	// Status register
	// b00: QSPI initialised
	// b00: loading page
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
		.readData({ loadingPage, qspi_initialised }),
		.readData_en(statusRegisterReadDataEnable_nc),
		.readData_busy(1'b0));

	// Current page address 	 Default 0x0
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
		.readData(currentPageAddress),
		.readData_en(currentPageAddressRegisterReadDataEnable_nc),
		.readData_busy(1'b0));

	wire[23:0] currentPageAddressLoadAddress = { currentPageAddressRegisterWriteData[23 - SRAM_ADDRESS_SIZE - 2:0], {SRAM_ADDRESS_SIZE{1'b0}}, 2'b00};

	always @(posedge clk) begin
		if (rst) begin
			currentPageAddress <= 24'b0;
			pageAddressSet <= 1'b0;
		end else if (currentPageAddressRegisterWriteDataEnable && !qspi_busy && !automaticPaging) begin
			currentPageAddress <= currentPageAddressLoadAddress;
			pageAddressSet <= 1'b1;
		end
	end

	// Cached address register
	wire[31:0] loadAddressRegisterOutputData;
	wire loadAddressRegisterOutputRequest;
	wire loadAddressRegisterBusBusy_nc;
	wire[23:0] loadAddressRegisterWriteData_nc;
	wire loadAddressRegisterWriteDataEnable_nc;
	wire loadAddressRegisterReadDataEnable_nc;
	DataRegister #(.WIDTH(24), .ADDRESS(12'h00C)) loadAddressRegister(
		.clk(clk),
		.rst(rst),
		.enable(registersEnable),
		.peripheralBus_we(peripheralBus_we),
		.peripheralBus_oe(peripheralBus_oe),
		.peripheralBus_busy(loadAddressRegisterBusBusy_nc),
		.peripheralBus_address(localAddress),
		.peripheralBus_byteSelect(peripheralBus_byteSelect),
		.peripheralBus_dataWrite(peripheralBus_dataWrite),
		.peripheralBus_dataRead(loadAddressRegisterOutputData),
		.requestOutput(loadAddressRegisterOutputRequest),
		.writeData(loadAddressRegisterWriteData_nc),
		.writeData_en(loadAddressRegisterWriteDataEnable_nc),
		.writeData_busy(1'b0),
		.readData(loadAddress),
		.readData_en(loadAddressRegisterReadDataEnable_nc),
		.readData_busy(1'b0));

	// Remember that the read data is only valid on the next clock cycle
	reg flashCacheReadReady = 1'b0;
	always @(posedge clk) begin
		if (rst) flashCacheReadReady <= 1'b0;
		else if (peripheralBus_oe && sramEnable && wordReady) flashCacheReadReady <= 1'b1;
		else flashCacheReadReady <= 1'b0;
	end

	// Assign peripheral read
	always @(*) begin
		case (1'b1)
			configurationRegisterOutputRequest: peripheralBus_dataRead <= configurationRegisterOutputData;
			statusRegisterOutputRequest: peripheralBus_dataRead <= statusRegisterOutputData;
			currentPageAddressRegisterOutputRequest: peripheralBus_dataRead <= currentPageAddressRegisterOutputData;
			loadAddressRegisterOutputRequest: peripheralBus_dataRead <= loadAddressRegisterOutputData;
			flashCacheReadReady: peripheralBus_dataRead <= sram_dout1;
			default: peripheralBus_dataRead <= 32'b0;
		endcase
	end

	assign peripheralBus_busy = sramEnable ? peripheralBus_oe && !flashCacheReadReady : currentPageAddressRegisterBusBusy;

	// QSPI interface
	always @(posedge clk) begin
		if (rst) begin
			loadAddress <= 32'b0;
			cachedCount <= {SRAM_ADDRESS_SIZE{1'b0}};
			qspi_requestData <= 1'b0;
		end	else if (currentPageAddressRegisterWriteDataEnable && !qspi_busy) begin
			loadAddress <= currentPageAddressLoadAddress;
			cachedCount <= {SRAM_ADDRESS_SIZE{1'b0}};
			qspi_requestData <= 1'b1;
		end else if (qspi_requestData && qspi_readDataValid) begin
			loadAddress <= loadAddress + 4;
			cachedCount <= nextCachedCount;
			qspi_requestData <= nextCachedCount != cachedCountFinal;
		end
	end

	assign qspi_address = currentPageAddressLoadAddress;
	assign qspi_changeAddress = currentPageAddressRegisterWriteDataEnable && !qspi_busy;

	// Assign sram port
	// Read/write port
	assign sram_clk0 = clk;
	assign sram_csb0 = !(qspi_requestData && qspi_readDataValid);	// Active low chip enable
	assign sram_web0 = 1'b0;	// Active low write enable (probably keep as always write)
	assign sram_wmask0 = 4'b1111;
	assign sram_addr0 = loadAddress[SRAM_ADDRESS_SIZE+1:2];
	assign sram_din0 = qspi_readData;

	// Read port
	assign sram_clk1 = clk;
	assign sram_csb1 = !(sramEnable && peripheralBus_oe && wordReady);
	assign sram_addr1 = peripheralBus_address[SRAM_ADDRESS_SIZE+1:2];

endmodule