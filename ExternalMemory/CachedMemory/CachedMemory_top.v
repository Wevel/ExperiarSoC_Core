`default_nettype none

module CachedMemory (
	`ifdef USE_POWER_PINS
		inout vccd1,	// User area 1 1.8V supply
		inout vssd1,	// User area 1 digital ground
`endif
		input wire wb_clk_i,
		input wire wb_rst_i,

		// Wishbone interface
		input wire wb_cyc_i,
		input wire wb_stb_i,
		input wire wb_we_i,
		input wire[3:0] wb_sel_i,
		input wire[31:0] wb_data_i,
		input wire[23:0] wb_adr_i,
		output wire wb_ack_o,
		output wire wb_stall_o,
		output wire wb_error_o,
		output wire[31:0] wb_data_o,

		// RAM QSPI
		output wire qspi_enable,
		output wire qspi_csb,
		output wire qspi_sck,
		output wire qspi_io0_we,
		output wire qspi_io0_write,
		input wire qspi_io0_read,
		output wire qspi_io1_we,
		output wire qspi_io1_write,
		input wire qspi_io1_read,

		// SRAM rw port
		output wire sram_clk0,
		output wire sram_csb0,
		output wire sram_web0,
		output wire[3:0] sram_wmask0,
		output wire[SRAM_ADDRESS_SIZE-1:0] sram_addr0,
		output wire[31:0] sram_din0,
		input wire[31:0] sram_dout0,

		// SRAM r port
		output wire sram_clk1,
		output wire sram_csb1,
		output wire[SRAM_ADDRESS_SIZE-1:0] sram_addr1,
		input wire[31:0] sram_dout1
	);

	localparam ADDRESS_SIZE = 24;
	localparam SRAM_ADDRESS_SIZE = 9;
	localparam PAGE_INDEX_ADDRESS_SIZE = 4;

	localparam PAGE_COUNT = (1 << PAGE_INDEX_ADDRESS_SIZE);

	// Memory cache
	wire qspi_interruptOperation;
	wire[23:0] qspi_address;
	wire qspi_changeAddress;
	wire qspi_requestData;
	wire qspi_storeData;
	wire[31:0] qspi_writeData;
	wire[31:0] qspi_readData;
	wire qspi_wordComplete;
	wire qspi_initialised;
	wire qspi_busy;

	// Wishbone interface
	wire peripheralBus_we;
	wire peripheralBus_oe;
	wire peripheralBus_busy;
	wire[23:0] peripheralBus_address;
	wire[3:0] peripheralBus_byteSelect;
	wire[31:0] peripheralBus_dataRead;
	wire[31:0] peripheralBus_dataWrite;
	WBPeripheralBusInterface wbPeripheralBusInterface(
	`ifdef USE_POWER_PINS
		.vccd1(vccd1),	// User area 1 1.8V power
		.vssd1(vssd1),	// User area 1 digital ground
	`endif
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.wb_stb_i(wb_stb_i),
		.wb_cyc_i(wb_cyc_i),
		.wb_we_i(wb_we_i),
		.wb_sel_i(wb_sel_i),
		.wb_data_i(wb_data_i),
		.wb_adr_i(wb_adr_i),
		.wb_ack_o(wb_ack_o),
		.wb_stall_o(wb_stall_o),
		.wb_error_o(wb_error_o),
		.wb_data_o(wb_data_o),
		.peripheralBus_we(peripheralBus_we),
		.peripheralBus_oe(peripheralBus_oe),
		.peripheralBus_address(peripheralBus_address),
		.peripheralBus_byteSelect(peripheralBus_byteSelect),
		.peripheralBus_dataWrite(peripheralBus_dataWrite),
		.peripheralBus_dataRead(peripheralBus_dataRead),
		.peripheralBus_busy(peripheralBus_busy));

	wire busMemoryEnable;
	wire busMemoryWriteEnable;
	wire[ADDRESS_SIZE-1:0] busMemoryVirtualAddress;
	wire[SRAM_ADDRESS_SIZE+1:0] busMemoryPhysicalAddress;
	wire[3:0] busMemoryByteSelect;
	wire[31:0] busMemoryDataWrite;
	wire[31:0] busMemoryDataRead;
	wire busMemoryCacheBusy;
	wire busMemoryBusy;

	wire cacheEnable;
	wire automaticPaging;
	wire manualPageAddressSet;
	wire[23-SRAM_ADDRESS_SIZE-2:0] manualPageAddress;
	wire writeEnable;
	wire[3:0] clockScale;
	wire modeChanged;
	CacheManagement #(
		.SRAM_ADDRESS_SIZE(SRAM_ADDRESS_SIZE),
		.PAGE_INDEX_ADDRESS_SIZE(PAGE_INDEX_ADDRESS_SIZE)
	) cacheManagement (
		.clk(wb_clk_i),
		.rst(wb_rst_i),
		.peripheralBus_we(peripheralBus_we),
		.peripheralBus_oe(peripheralBus_oe),
		.peripheralBus_address(peripheralBus_address),
		.peripheralBus_byteSelect(peripheralBus_byteSelect),
		.peripheralBus_dataWrite(peripheralBus_dataWrite),
		.peripheralBus_dataRead(peripheralBus_dataRead),
		.peripheralBus_busy(peripheralBus_busy),
		.busMemoryEnable(busMemoryEnable),	
		.busMemoryWriteEnable(busMemoryWriteEnable),	
		.busMemoryAddress(busMemoryVirtualAddress),	
		.busMemoryByteSelect(busMemoryByteSelect),	
		.busMemoryDataWrite(busMemoryDataWrite),
		.busMemoryDataRead(busMemoryDataRead),	
		.busMemoryBusy(busMemoryCacheBusy || busMemoryBusy),	
		.cacheEnable(cacheEnable),
		.automaticPaging(automaticPaging),
		.manualPageAddressSet(manualPageAddressSet),
		.manualPageAddress(manualPageAddress),
		.writeEnable(writeEnable),
		.clockScale(clockScale),
		.modeChanged(modeChanged),
		.cacheInitialised(qspi_initialised),
		.cacheRequestData(qspi_requestData),
		.cacheStoreData(qspi_storeData),
		.cacheBusy(busMemoryBusy),
		.pageAddressSet(pageAddressSet),
		.pageRequestLoad(pageRequestLoad)
	);

	assign qspi_enable = cacheEnable;

	// Cache controller
	wire[PAGE_COUNT-1:0] pageAddressSet;
	wire[PAGE_COUNT-1:0] pageRequestLoad;
	wire cacheSRAMEnable;
	wire cacheSRAMWriteEnable;
	wire[SRAM_ADDRESS_SIZE+1:0] cacheSRAMAddress;
	wire cacheSRAMBusy;
	MemoryCache #(
		.ADDRESS_SIZE(ADDRESS_SIZE),
		.SRAM_ADDRESS_SIZE(SRAM_ADDRESS_SIZE),
		.PAGE_INDEX_ADDRESS_SIZE(PAGE_INDEX_ADDRESS_SIZE)
	) memoryCache (
		.clk(wb_clk_i),
		.rst(wb_rst_i),
		.writeEnable(writeEnable),
		.automaticPaging(automaticPaging),
		.manualPageAddressSet(manualPageAddressSet),
		.manualPageAddress(manualPageAddress),
		.busEnable(busMemoryEnable),
		.busWriteEnable(busMemoryWriteEnable),
		.busVirtualAddress(busMemoryVirtualAddress),
		.busPhysicalAddress(busMemoryPhysicalAddress),
		.busBusy(busMemoryCacheBusy),
		.cacheSRAMEnable(cacheSRAMEnable),
		.cacheSRAMWriteEnable(cacheSRAMWriteEnable),
		.cacheSRAMAddress(cacheSRAMAddress),
		.cacheSRAMBusy(cacheSRAMBusy),
		.qspi_enable(qspi_enable),
		.qspi_interruptOperation(qspi_interruptOperation),
		.qspi_address(qspi_address),
		.qspi_changeAddress(qspi_changeAddress),
		.qspi_requestData(qspi_requestData),
		.qspi_storeData(qspi_storeData),
		.qspi_wordComplete(qspi_wordComplete),
		.qspi_initialised(qspi_initialised),
		.qspi_busy(qspi_busy),
		.pageAddressSet(pageAddressSet),
		.pageRequestLoad(pageRequestLoad));

	// QSPI controller
	QSPIDevice qspiDevice (
		.clk(wb_clk_i),
		.rst(wb_rst_i),
		.clockScale(clockScale),
		.qspi_enable(qspi_enable),
		.qspi_interruptOperation(qspi_interruptOperation),
		.qspi_address(qspi_address),
		.qspi_changeAddress(qspi_changeAddress),
		.qspi_requestData(qspi_requestData),
		.qspi_storeData(qspi_storeData),
		.qspi_writeData(qspi_writeData),
		.qspi_readData(qspi_readData),
		.qspi_wordComplete(qspi_wordComplete),
		.qspi_initialised(qspi_initialised),
		.qspi_busy(qspi_busy),
		.device_csb(qspi_csb),
		.device_sck(qspi_sck),
		.device_io0_we(qspi_io0_we),
		.device_io0_write(qspi_io0_write),
		.device_io0_read(qspi_io0_read),
		.device_io1_we(qspi_io1_we),
		.device_io1_write(qspi_io1_write),
		.device_io1_read(qspi_io1_read));

	// Two port SRAM controller
	LocalMemoryInterface #(
		.ADDRESS_SIZE(SRAM_ADDRESS_SIZE+2),
		.SRAM_ADDRESS_SIZE(SRAM_ADDRESS_SIZE),
		.BLOCK_ADDRESS_SIZE(0)
	) localMemoryInterface (
		.clk(wb_clk_i),
		.rst(wb_rst_i),
		.primaryEnable(cacheSRAMEnable),
		.primaryWriteEnable(cacheSRAMWriteEnable),
		.primaryAddress(cacheSRAMAddress),
		.primaryByteSelect(4'b1111),
		.primaryDataWrite(qspi_readData),
		.primaryDataRead(qspi_writeData),
		.primaryBusy(cacheSRAMBusy),
		.secondaryEnable(busMemoryEnable && !busMemoryCacheBusy),
		.secondaryWriteEnable(busMemoryWriteEnable),
		.secondaryAddress(busMemoryPhysicalAddress),
		.secondaryByteSelect(busMemoryByteSelect),
		.secondaryDataWrite(busMemoryDataWrite),
		.secondaryDataRead(busMemoryDataRead),
		.secondaryBusy(busMemoryBusy),
		.clk0(sram_clk0),
		.csb0(sram_csb0),
		.web0(sram_web0),
		.wmask0(sram_wmask0),
		.addr0(sram_addr0),
		.din0(sram_din0),
		.dout0(sram_dout0),
		.clk1(sram_clk1),
		.csb1(sram_csb1),
		.addr1(sram_addr1),
		.dout1(sram_dout1));

endmodule
