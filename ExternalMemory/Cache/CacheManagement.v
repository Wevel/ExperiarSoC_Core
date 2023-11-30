`default_nettype none

`ifndef CACHE_MANAGEMENT_V
`define CACHE_MANAGEMENT_V

`include "../../Peripherals/Registers/ConfigurationRegister.v"
`include "../../Peripherals/Registers/DataRegister.v"

module CacheManagement #(
		parameter ADDRESS_SIZE = 24,
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

		// Peripheral Bus
		output wire busMemoryEnable,
		output wire busMemoryWriteEnable,
		output wire[23:0] busMemoryAddress,
		output wire[3:0] busMemoryByteSelect,
		output wire[31:0] busMemoryDataWrite,
		input wire[31:0] busMemoryDataRead,
		input wire busMemoryBusy,

		// Configuration
		output wire cacheEnable,
		output wire automaticPaging,
		output wire manualPageAddressSet,
		output wire[MANUAL_PAGE_ADDRESS_SIZE-1:0] manualPageAddress,
		output wire writeEnable,
		output wire[3:0] clockScale,

		// Status
		input wire cacheInitialised,
		input wire cacheRequestData,
		input wire cacheStoreData,
		input wire cacheBusy,
		input wire[PAGE_COUNT-1:0] pageAddressSet,
		input wire[PAGE_COUNT-1:0] pageRequestLoad,
		input wire[PAGE_COUNT-1:0] pageRequestFlush
	);

	localparam PAGE_NUMBER_ADDRESS_SIZE = (ADDRESS_SIZE - PAGE_DATA_ADDRESS_SIZE - 2);
	localparam PAGE_DATA_ADDRESS_SIZE = (SRAM_ADDRESS_SIZE - PAGE_INDEX_ADDRESS_SIZE);
	localparam MANUAL_PAGE_ADDRESS_SIZE = (PAGE_NUMBER_ADDRESS_SIZE - PAGE_INDEX_ADDRESS_SIZE);
	localparam PAGE_COUNT = (1 << PAGE_INDEX_ADDRESS_SIZE);

	wire sramEnable = peripheralBus_oe && (peripheralBus_address[23] == 1'b0) && ((peripheralBus_address[22:SRAM_ADDRESS_SIZE+2] == {(21-SRAM_ADDRESS_SIZE){1'b0}}) || automaticPaging);
	wire registersEnable = peripheralBus_address[23:12] == 12'h800;
	wire[11:0] localAddress = peripheralBus_address[11:0];

	// Register
	// Configuration register 	Default 0x0
	// b00: enable				Default 0x0
	// b01: automaticPaging		Default 0x0
	// b02: writeEnable			Default 0x0
	// b03-b06: clockScale		Default 0x0
	wire[31:0] configurationRegisterOutputData;
	wire configurationRegisterOutputRequest;
	wire[6:0] configuration;
	ConfigurationRegister #(.WIDTH(7), .ADDRESS(12'h000), .DEFAULT(7'h00)) configurationRegister(
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

	assign cacheEnable = configuration[0];
	assign automaticPaging = configuration[1];
	assign writeEnable = configuration[2];
	assign clockScale = configuration[6:3];

	// Status register
	// b00: initialised
	// b01: loading page
	// b02: saving page
	wire[2:0] statusRegisterValue = { cacheStoreData, cacheRequestData, cacheInitialised };
	wire[31:0] statusRegisterOutputData;
	wire statusRegisterOutputRequest;
	wire _unused_statusRegisterBusBusy;
	wire[2:0] _unused_statusRegisterWriteData;
	wire _unused_statusRegisterWriteDataEnable;
	wire _unused_statusRegisterReadDataEnable;
	DataRegister #(.WIDTH(3), .ADDRESS(12'h004)) statusRegister(
		.enable(registersEnable),
		.peripheralBus_we(peripheralBus_we),
		.peripheralBus_oe(peripheralBus_oe),
		.peripheralBus_busy(_unused_statusRegisterBusBusy),
		.peripheralBus_address(localAddress),
		.peripheralBus_byteSelect(peripheralBus_byteSelect),
		.peripheralBus_dataWrite(peripheralBus_dataWrite),
		.peripheralBus_dataRead(statusRegisterOutputData),
		.requestOutput(statusRegisterOutputRequest),
		.writeData(_unused_statusRegisterWriteData),
		.writeData_en(_unused_statusRegisterWriteDataEnable),
		.writeData_busy(1'b0),
		.readData(statusRegisterValue),
		.readData_en(_unused_statusRegisterReadDataEnable),
		.readData_busy(1'b0));


	// Current page address 	 Default 0x0
	reg[MANUAL_PAGE_ADDRESS_SIZE-1:0] currentManualPageAddress;
	wire[31:0] currentPageAddressRegisterOutputData;
	wire currentPageAddressRegisterOutputRequest;
	wire currentPageAddressRegisterBusBusy;
	wire[MANUAL_PAGE_ADDRESS_SIZE-1:0] currentPageAddressRegisterWriteData;
	wire currentPageAddressRegisterWriteDataEnable;
	wire _unused_currentPageAddressRegisterReadDataEnable;
	DataRegister #(.WIDTH(MANUAL_PAGE_ADDRESS_SIZE), .ADDRESS(12'h008)) currentPageAddressRegister(
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
		.writeData_busy(!automaticPaging && cacheBusy),
		.readData(currentManualPageAddress),
		.readData_en(_unused_currentPageAddressRegisterReadDataEnable),
		.readData_busy(1'b0));

	always @(posedge clk) begin
		if (rst) begin
			currentManualPageAddress <= ~{MANUAL_PAGE_ADDRESS_SIZE{1'b0}};
		end else begin
			if (automaticPaging) currentManualPageAddress <= ~{MANUAL_PAGE_ADDRESS_SIZE{1'b0}};
			else if (currentPageAddressRegisterWriteDataEnable) currentManualPageAddress <= currentPageAddressRegisterWriteData;
		end
	end

	assign manualPageAddressSet  = currentPageAddressRegisterWriteDataEnable && !automaticPaging;
	assign manualPageAddress  = currentPageAddressRegisterWriteData[23-SRAM_ADDRESS_SIZE-2:0];

	// Cache status register
	// PAGE_INDEX_ADDRESS_SIZE == 3:
	// 	b00-b07: pageAddressSet
	// 	b08-b15: pageRequestLoad
	// PAGE_INDEX_ADDRESS_SIZE == 4:
	// 	b00-b15: pageAddressSet
	// 	b16-b31: pageRequestLoad
	wire[31:0] cacheStatusRegisterOutputData;
	wire cacheStatusRegisterOutputRequest;
	wire _unused_cacheStatusRegisterBusBusy;
	wire[PAGE_COUNT+PAGE_COUNT-1:0] _unused_cacheStatusRegisterWriteData;
	wire _unused_cacheStatusRegisterWriteDataEnable;
	wire _unused_cacheStatusRegisterReadDataEnable;
	DataRegister #(.WIDTH(PAGE_COUNT + PAGE_COUNT), .ADDRESS(12'h00C)) cacheStatusRegister(
		.enable(registersEnable),
		.peripheralBus_we(peripheralBus_we),
		.peripheralBus_oe(peripheralBus_oe),
		.peripheralBus_busy(_unused_cacheStatusRegisterBusBusy),
		.peripheralBus_address(localAddress),
		.peripheralBus_byteSelect(peripheralBus_byteSelect),
		.peripheralBus_dataWrite(peripheralBus_dataWrite),
		.peripheralBus_dataRead(cacheStatusRegisterOutputData),
		.requestOutput(cacheStatusRegisterOutputRequest),
		.writeData(_unused_cacheStatusRegisterWriteData),
		.writeData_en(_unused_cacheStatusRegisterWriteDataEnable),
		.writeData_busy(1'b0),
		.readData({ pageRequestLoad, pageAddressSet }),
		.readData_en(_unused_cacheStatusRegisterReadDataEnable),
		.readData_busy(1'b0));

	// Cache status register 2
	// PAGE_INDEX_ADDRESS_SIZE == 3:
	// 	b00-b07: pageRequestFlush
	// PAGE_INDEX_ADDRESS_SIZE == 4:
	// 	b00-b15: pageRequestFlush
	wire[31:0] cacheStatusRegister2OutputData;
	wire cacheStatusRegister2OutputRequest;
	wire _unused_cacheStatusRegister2BusBusy;
	wire[PAGE_COUNT-1:0] _unused_cacheStatusRegister2WriteData;
	wire _unused_cacheStatusRegister2WriteDataEnable;
	wire _unused_cacheStatusRegister2ReadDataEnable;
	DataRegister #(.WIDTH(PAGE_COUNT), .ADDRESS(12'h010)) cacheStatusRegister2(
		.enable(registersEnable),
		.peripheralBus_we(peripheralBus_we),
		.peripheralBus_oe(peripheralBus_oe),
		.peripheralBus_busy(_unused_cacheStatusRegister2BusBusy),
		.peripheralBus_address(localAddress),
		.peripheralBus_byteSelect(peripheralBus_byteSelect),
		.peripheralBus_dataWrite(peripheralBus_dataWrite),
		.peripheralBus_dataRead(cacheStatusRegister2OutputData),
		.requestOutput(cacheStatusRegister2OutputRequest),
		.writeData(_unused_cacheStatusRegister2WriteData),
		.writeData_en(_unused_cacheStatusRegister2WriteDataEnable),
		.writeData_busy(1'b0),
		.readData({ pageRequestFlush }),
		.readData_en(_unused_cacheStatusRegister2ReadDataEnable),
		.readData_busy(1'b0));

	// Assign peripheral read
	always @(*) begin
		case (1'b1)
			configurationRegisterOutputRequest: peripheralBus_dataRead = configurationRegisterOutputData;
			statusRegisterOutputRequest: peripheralBus_dataRead = statusRegisterOutputData;
			currentPageAddressRegisterOutputRequest: peripheralBus_dataRead = currentPageAddressRegisterOutputData;
			cacheStatusRegisterOutputRequest: peripheralBus_dataRead = cacheStatusRegisterOutputData;
			cacheStatusRegister2OutputRequest: peripheralBus_dataRead = cacheStatusRegister2OutputData;
			sramEnable: peripheralBus_dataRead = busMemoryDataRead;
			default: peripheralBus_dataRead = ~32'b0;
		endcase
	end

	assign peripheralBus_busy = sramEnable ? busMemoryBusy : currentPageAddressRegisterBusBusy;

	assign busMemoryEnable = ((peripheralBus_we && writeEnable) || peripheralBus_oe) && sramEnable;
	assign busMemoryWriteEnable = ((peripheralBus_we && writeEnable) && !peripheralBus_oe) && sramEnable;
	assign busMemoryAddress = peripheralBus_address;
	assign busMemoryByteSelect = peripheralBus_byteSelect;
	assign busMemoryDataWrite = peripheralBus_dataWrite;

endmodule

`endif
