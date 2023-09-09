`default_nettype none

module ExperiarSoC (
`ifdef USE_POWER_PINS
		inout vccd1,	// User area 1 1.8V supply
		inout vssd1,	// User area 1 digital ground
`endif

		input wire wb_clk_i,
		input wire wb_rst_i,

		// Caravel wishbone master
		input wire caravel_wb_cyc_o,
		input wire caravel_wb_stb_o,
		input wire caravel_wb_we_o,
		input wire[3:0] caravel_wb_sel_o,
		input wire[31:0] caravel_wb_data_o,
		input wire[27:0] caravel_wb_adr_o,
		output wire caravel_wb_ack_i,
		output wire caravel_wb_stall_i,
		output wire caravel_wb_error_i,
		output wire[31:0] caravel_wb_data_i,

		// IOs
		input  wire[`MPRJ_IO_PADS-1:0] io_in,
		output wire[`MPRJ_IO_PADS-1:0] io_out,
		output wire[`MPRJ_IO_PADS-1:0] io_oeb,
		
		// Caravel
		input wire caravel_uart_rx,
		output wire caravel_uart_tx,
		input wire[3:0] caravel_irq,

		// Logic Analyzer Signals
		//input wire[127:0] probe_in,
		output wire[97:0] probe_out,

		// Configuration constants
		input wire[7:0] core0Index,
		input wire[7:0] core1Index,
		input wire[10:0] manufacturerID,
		input wire[15:0] partID,
		input wire[3:0] versionID
	);
	
	localparam SRAM_ADDRESS_SIZE = 9;
	
	// JTAG
	wire jtag_tck;
	wire jtag_tms;
	wire jtag_tdi;
	wire jtag_tdo;

	// Cached Memory
	wire[1:0] cachedMemory_en;
	wire[1:0] cachedMemory_csb;
	wire[1:0] cachedMemory_sck;
	wire[1:0] cachedMemory_io0_we;
	wire[1:0] cachedMemory_io0_write;
	wire[1:0] cachedMemory_io0_read;
	wire[1:0] cachedMemory_io1_we;
	wire[1:0] cachedMemory_io1_write;
	wire[1:0] cachedMemory_io1_read;

	// IRQ
	// wire irq_en;
	// wire irq_in;
	wire[15:0] irq;

	// Wishbone wires
	// Master 0: Caravel

	// Master 1: Core 0
	wire core0_wb_cyc_o;
	wire core0_wb_stb_o;
	wire core0_wb_we_o;
	wire[3:0] core0_wb_sel_o;
	wire[31:0] core0_wb_data_o;
	wire[27:0] core0_wb_adr_o;
	wire core0_wb_ack_i;
	wire core0_wb_stall_i;
	wire core0_wb_error_i;
	wire[31:0] core0_wb_data_i;

	// Master 2: Core 1
	wire core1_wb_cyc_o;
	wire core1_wb_stb_o;
	wire core1_wb_we_o;
	wire[3:0] core1_wb_sel_o;
	wire[31:0] core1_wb_data_o;
	wire[27:0] core1_wb_adr_o;
	wire core1_wb_ack_i;
	wire core1_wb_stall_i;
	wire core1_wb_error_i;
	wire[31:0] core1_wb_data_i;

	// Master 3: dma
	// wire dma_wb_cyc_o = 1'b0;
	// wire dma_wb_stb_o = 1'b0;
	// wire dma_wb_we_o = 1'b0;
	// wire[3:0] dma_wb_sel_o = 4'b0;
	// wire[31:0] dma_wb_data_o = 32'b0;
	// wire[27:0] dma_wb_adr_o = 28'b0;
	// wire dma_wb_ack_i;
	// wire dma_wb_stall_i;
	// wire dma_wb_error_i;
	// wire[31:0] dma_wb_data_i;

	// Slave 0
	wire core0Memory_wb_cyc_i;
	wire core0Memory_wb_stb_i;
	wire core0Memory_wb_we_i;
	wire[3:0] core0Memory_wb_sel_i;
	wire[31:0] core0Memory_wb_data_i;
	wire[23:0] core0Memory_wb_adr_i;
	wire core0Memory_wb_ack_o;
	wire core0Memory_wb_stall_o;
	wire core0Memory_wb_error_o;
	wire[31:0] core0Memory_wb_data_o;

	// Slave 1
	wire core1Memory_wb_cyc_i;
	wire core1Memory_wb_stb_i;
	wire core1Memory_wb_we_i;
	wire[3:0] core1Memory_wb_sel_i;
	wire[31:0] core1Memory_wb_data_i;
	wire[23:0] core1Memory_wb_adr_i;
	wire core1Memory_wb_ack_o;
	wire core1Memory_wb_stall_o;
	wire core1Memory_wb_error_o;
	wire[31:0] core1Memory_wb_data_o;

	// Slave 2
	wire videoMemory_wb_cyc_i;
	wire videoMemory_wb_stb_i;
	wire videoMemory_wb_we_i;
	wire[3:0] videoMemory_wb_sel_i;
	wire[31:0] videoMemory_wb_data_i;
	wire[23:0] videoMemory_wb_adr_i;
	wire videoMemory_wb_ack_o;
	wire videoMemory_wb_stall_o;
	wire videoMemory_wb_error_o;
	wire[31:0] videoMemory_wb_data_o;

	// Slave 3
	wire peripherals_wb_cyc_i;
	wire peripherals_wb_stb_i;
	wire peripherals_wb_we_i;
	wire[3:0] peripherals_wb_sel_i;
	wire[31:0] peripherals_wb_data_i;
	wire[23:0] peripherals_wb_adr_i;
	wire peripherals_wb_ack_o;
	wire peripherals_wb_stall_o;
	wire peripherals_wb_error_o;
	wire[31:0] peripherals_wb_data_o;

	// Slave 4/5
	wire[1:0] cachedMemory_wb_cyc_i;
	wire[1:0] cachedMemory_wb_stb_i;
	wire[1:0] cachedMemory_wb_we_i;
	wire[3:0] cachedMemory_wb_sel_i [0:1];
	wire[31:0] cachedMemory_wb_data_i [0:1];
	wire[23:0] cachedMemory_wb_adr_i [0:1];
	wire[1:0] cachedMemory_wb_ack_o;
	wire[1:0] cachedMemory_wb_stall_o;
	wire[1:0] cachedMemory_wb_error_o;
	wire[31:0] cachedMemory_wb_data_o [0:1];

	wire[3:0] probe_master0_currentSlave;
	wire[3:0] probe_master1_currentSlave;
	wire[3:0] probe_master2_currentSlave;
	wire[3:0] probe_master3_currentSlave;
	wire[1:0] probe_slave0_currentMaster;
	wire[1:0] probe_slave1_currentMaster;
	wire[1:0] probe_slave2_currentMaster;
	wire[1:0] probe_slave3_currentMaster;
	wire[1:0] probe_slave4_currentMaster;
	wire[1:0] probe_slave5_currentMaster;


	wire[15:0] probe_wishboneInterconnect = {
		// probe_slave5_currentMaster,
		// probe_slave4_currentMaster,
		// probe_slave3_currentMaster,
		// probe_slave2_currentMaster,
		// probe_slave1_currentMaster,
		// probe_slave0_currentMaster,
		probe_master3_currentSlave,
		probe_master2_currentSlave,
		probe_master1_currentSlave,
		probe_master0_currentSlave
	};

	//-------------------------------------------------//
	//---------------------Wishbone--------------------//
	//-------------------------------------------------//

	WishboneInterconnect wishboneInterconnect(
`ifdef USE_POWER_PINS
		.vccd1(vccd1),	// User area 1 1.8V power
		.vssd1(vssd1),	// User area 1 digital ground
`endif
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.master0_wb_cyc_o(caravel_wb_cyc_o),
		.master0_wb_stb_o(caravel_wb_stb_o),
		.master0_wb_we_o(caravel_wb_we_o),
		.master0_wb_sel_o(caravel_wb_sel_o),
		.master0_wb_data_o(caravel_wb_data_o),
		.master0_wb_adr_o(caravel_wb_adr_o),
		.master0_wb_ack_i(caravel_wb_ack_i),
		.master0_wb_stall_i(caravel_wb_stall_i),
		.master0_wb_error_i(caravel_wb_error_i),
		.master0_wb_data_i(caravel_wb_data_i),
		.master1_wb_cyc_o(core0_wb_cyc_o),
		.master1_wb_stb_o(core0_wb_stb_o),
		.master1_wb_we_o(core0_wb_we_o),
		.master1_wb_sel_o(core0_wb_sel_o),
		.master1_wb_data_o(core0_wb_data_o),
		.master1_wb_adr_o(core0_wb_adr_o),
		.master1_wb_ack_i(core0_wb_ack_i),
		.master1_wb_stall_i(core0_wb_stall_i),
		.master1_wb_error_i(core0_wb_error_i),
		.master1_wb_data_i(core0_wb_data_i),
		.master2_wb_cyc_o(core1_wb_cyc_o),
		.master2_wb_stb_o(core1_wb_stb_o),
		.master2_wb_we_o(core1_wb_we_o),
		.master2_wb_sel_o(core1_wb_sel_o),
		.master2_wb_data_o(core1_wb_data_o),
		.master2_wb_adr_o(core1_wb_adr_o),
		.master2_wb_ack_i(core1_wb_ack_i),
		.master2_wb_stall_i(core1_wb_stall_i),
		.master2_wb_error_i(core1_wb_error_i),
		.master2_wb_data_i(core1_wb_data_i),
		// .master3_wb_cyc_o(dma_wb_cyc_o),
		// .master3_wb_stb_o(dma_wb_stb_o),
		// .master3_wb_we_o(dma_wb_we_o),
		// .master3_wb_sel_o(dma_wb_sel_o),
		// .master3_wb_data_o(dma_wb_data_o),
		// .master3_wb_adr_o(dma_wb_adr_o),
		// .master3_wb_ack_i(dma_wb_ack_i),
		// .master3_wb_stall_i(dma_wb_stall_i),
		// .master3_wb_error_i(dma_wb_error_i),
		// .master3_wb_data_i(dma_wb_data_i),
		.slave0_wb_cyc_i(core0Memory_wb_cyc_i),
		.slave0_wb_stb_i(core0Memory_wb_stb_i),
		.slave0_wb_we_i(core0Memory_wb_we_i),
		.slave0_wb_sel_i(core0Memory_wb_sel_i),
		.slave0_wb_data_i(core0Memory_wb_data_i),
		.slave0_wb_adr_i(core0Memory_wb_adr_i),
		.slave0_wb_ack_o(core0Memory_wb_ack_o),
		.slave0_wb_stall_o(core0Memory_wb_stall_o),
		.slave0_wb_error_o(core0Memory_wb_error_o),
		.slave0_wb_data_o(core0Memory_wb_data_o),
		.slave1_wb_cyc_i(core1Memory_wb_cyc_i),
		.slave1_wb_stb_i(core1Memory_wb_stb_i),
		.slave1_wb_we_i(core1Memory_wb_we_i),
		.slave1_wb_sel_i(core1Memory_wb_sel_i),
		.slave1_wb_data_i(core1Memory_wb_data_i),
		.slave1_wb_adr_i(core1Memory_wb_adr_i),
		.slave1_wb_ack_o(core1Memory_wb_ack_o),
		.slave1_wb_stall_o(core1Memory_wb_stall_o),
		.slave1_wb_error_o(core1Memory_wb_error_o),
		.slave1_wb_data_o(core1Memory_wb_data_o),
		.slave2_wb_cyc_i(videoMemory_wb_cyc_i),
		.slave2_wb_stb_i(videoMemory_wb_stb_i),
		.slave2_wb_we_i(videoMemory_wb_we_i),
		.slave2_wb_sel_i(videoMemory_wb_sel_i),
		.slave2_wb_data_i(videoMemory_wb_data_i),
		.slave2_wb_adr_i(videoMemory_wb_adr_i),
		.slave2_wb_ack_o(videoMemory_wb_ack_o),
		.slave2_wb_stall_o(videoMemory_wb_stall_o),
		.slave2_wb_error_o(videoMemory_wb_error_o),
		.slave2_wb_data_o(videoMemory_wb_data_o),
		.slave3_wb_cyc_i(peripherals_wb_cyc_i),
		.slave3_wb_stb_i(peripherals_wb_stb_i),
		.slave3_wb_we_i(peripherals_wb_we_i),
		.slave3_wb_sel_i(peripherals_wb_sel_i),
		.slave3_wb_data_i(peripherals_wb_data_i),
		.slave3_wb_adr_i(peripherals_wb_adr_i),
		.slave3_wb_ack_o(peripherals_wb_ack_o),
		.slave3_wb_stall_o(peripherals_wb_stall_o),
		.slave3_wb_error_o(peripherals_wb_error_o),
		.slave3_wb_data_o(peripherals_wb_data_o),
		.slave4_wb_cyc_i(cachedMemory_wb_cyc_i[0]),
		.slave4_wb_stb_i(cachedMemory_wb_stb_i[0]),
		.slave4_wb_we_i(cachedMemory_wb_we_i[0]),
		.slave4_wb_sel_i(cachedMemory_wb_sel_i[0]),
		.slave4_wb_data_i(cachedMemory_wb_data_i[0]),
		.slave4_wb_adr_i(cachedMemory_wb_adr_i[0]),
		.slave4_wb_ack_o(cachedMemory_wb_ack_o[0]),
		.slave4_wb_stall_o(cachedMemory_wb_stall_o[0]),
		.slave4_wb_error_o(cachedMemory_wb_error_o[0]),
		.slave4_wb_data_o(cachedMemory_wb_data_o[0]),
		.slave5_wb_cyc_i(cachedMemory_wb_cyc_i[1]),
		.slave5_wb_stb_i(cachedMemory_wb_stb_i[1]),
		.slave5_wb_we_i(cachedMemory_wb_we_i[1]),
		.slave5_wb_sel_i(cachedMemory_wb_sel_i[1]),
		.slave5_wb_data_i(cachedMemory_wb_data_i[1]),
		.slave5_wb_adr_i(cachedMemory_wb_adr_i[1]),
		.slave5_wb_ack_o(cachedMemory_wb_ack_o[1]),
		.slave5_wb_stall_o(cachedMemory_wb_stall_o[1]),
		.slave5_wb_error_o(cachedMemory_wb_error_o[1]),
		.slave5_wb_data_o(cachedMemory_wb_data_o[1]),
		.probe_master0_currentSlave(probe_master0_currentSlave),
		.probe_master1_currentSlave(probe_master1_currentSlave),
		.probe_master2_currentSlave(probe_master2_currentSlave),
		.probe_master3_currentSlave(probe_master3_currentSlave),
		.probe_slave0_currentMaster(probe_slave0_currentMaster),
		.probe_slave1_currentMaster(probe_slave1_currentMaster),
		.probe_slave2_currentMaster(probe_slave2_currentMaster),
		.probe_slave3_currentMaster(probe_slave3_currentMaster),
		.probe_slave4_currentMaster(probe_slave4_currentMaster),
		.probe_slave5_currentMaster(probe_slave5_currentMaster));

	//-------------------------------------------------//
	//----------------------CORE0----------------------//
	//-------------------------------------------------//
	
	// JTAG interface
	wire core0_tdi;
	wire core0_tdo;

	// SRAM rw port
	wire core0SRAM_clk0;
	wire[1:0] core0SRAM_csb0;
	wire core0SRAM_web0;
	wire[3:0] core0SRAM_wmask0;
	wire[SRAM_ADDRESS_SIZE-1:0] core0SRAM_addr0;
	wire[31:0] core0SRAM_din0;
	wire[63:0] core0SRAM_dout0;

	// SRAM r port
	wire core0SRAM_clk1;
	wire[1:0] core0SRAM_csb1;
	wire[SRAM_ADDRESS_SIZE-1:0] core0SRAM_addr1;
	wire[63:0] core0SRAM_dout1;

	// Logic probes
	wire probe_core0_state;
	wire[1:0] probe_core0_env;
	wire[31:0] probe_core0_programCounter;
	wire[4:0] probe_core0_jtagInstruction;

	wire[39:0] probe_core0 = {
		probe_core0_state,
		probe_core0_env,
		probe_core0_programCounter,
		probe_core0_jtagInstruction
	};

	ExperiarCore core0 (
`ifdef USE_POWER_PINS
		.vccd1(vccd1),	// User area 1 1.8V power
		.vssd1(vssd1),	// User area 1 digital ground
`endif
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.coreIndex(core0Index),
		.manufacturerID(manufacturerID),
		.partID(partID),
		.versionID(versionID),
		.jtag_tck(jtag_tck),
		.jtag_tms(jtag_tms),
		.jtag_tdi(core0_tdi),
		.jtag_tdo(core0_tdo),
		.irq(irq),
		.core_wb_cyc_o(core0_wb_cyc_o),
		.core_wb_stb_o(core0_wb_stb_o),
		.core_wb_we_o(core0_wb_we_o),
		.core_wb_sel_o(core0_wb_sel_o),
		.core_wb_data_o(core0_wb_data_o),
		.core_wb_adr_o(core0_wb_adr_o),
		.core_wb_ack_i(core0_wb_ack_i),
		.core_wb_stall_i(core0_wb_stall_i),
		.core_wb_error_i(core0_wb_error_i),
		.core_wb_data_i(core0_wb_data_i),
		.localMemory_wb_cyc_i(core0Memory_wb_cyc_i),
		.localMemory_wb_stb_i(core0Memory_wb_stb_i),
		.localMemory_wb_we_i(core0Memory_wb_we_i),
		.localMemory_wb_sel_i(core0Memory_wb_sel_i),
		.localMemory_wb_data_i(core0Memory_wb_data_i),
		.localMemory_wb_adr_i(core0Memory_wb_adr_i),
		.localMemory_wb_ack_o(core0Memory_wb_ack_o),
		.localMemory_wb_stall_o(core0Memory_wb_stall_o),
		.localMemory_wb_error_o(core0Memory_wb_error_o),
		.localMemory_wb_data_o(core0Memory_wb_data_o),
		.clk0(core0SRAM_clk0),
		.csb0(core0SRAM_csb0),
		.web0(core0SRAM_web0),
		.wmask0(core0SRAM_wmask0),
		.addr0(core0SRAM_addr0),
		.din0(core0SRAM_din0),
		.dout0(core0SRAM_dout0),
		.clk1(core0SRAM_clk1),
		.csb1(core0SRAM_csb1),
		.addr1(core0SRAM_addr1),
		.dout1(core0SRAM_dout1),
		.probe_state(probe_core0_state),
		.probe_env(probe_core0_env),
		.probe_programCounter(probe_core0_programCounter),
		.probe_jtagInstruction(probe_core0_jtagInstruction));

	wire[31:0] core0SRAM0_dout0;
	wire[31:0] core0SRAM0_dout1;
	sky130_sram_2kbyte_1rw1r_32x512_8 core0SRAM0(
`ifdef USE_POWER_PINS
		.vccd1(vccd1),	// User area 1 1.8V power
		.vssd1(vssd1),	// User area 1 digital ground
`endif
		.clk0(core0SRAM_clk0),
		.csb0(core0SRAM_csb0[0]),
		.web0(core0SRAM_web0),
		.wmask0(core0SRAM_wmask0),
		.addr0(core0SRAM_addr0),
		.din0(core0SRAM_din0),
		.dout0(core0SRAM0_dout0),
		.clk1(core0SRAM_clk1),
		.csb1(core0SRAM_csb1[0]),
		.addr1(core0SRAM_addr1),
		.dout1(core0SRAM0_dout1));

	wire[31:0] core0SRAM1_dout0;
	wire[31:0] core0SRAM1_dout1;
	sky130_sram_2kbyte_1rw1r_32x512_8 core0SRAM1(
`ifdef USE_POWER_PINS
		.vccd1(vccd1),	// User area 1 1.8V power
		.vssd1(vssd1),	// User area 1 digital ground
`endif
		.clk0(core0SRAM_clk0),
		.csb0(core0SRAM_csb0[1]),
		.web0(core0SRAM_web0),
		.wmask0(core0SRAM_wmask0),
		.addr0(core0SRAM_addr0),
		.din0(core0SRAM_din0),
		.dout0(core0SRAM1_dout0),
		.clk1(core0SRAM_clk1),
		.csb1(core0SRAM_csb1[1]),
		.addr1(core0SRAM_addr1),
		.dout1(core0SRAM1_dout1));

	assign core0SRAM_dout0 = { core0SRAM1_dout0, core0SRAM0_dout0 };
	assign core0SRAM_dout1 = { core0SRAM1_dout1, core0SRAM0_dout1 };

	//-------------------------------------------------//
	//----------------------CORE1----------------------//
	//-------------------------------------------------//
	
	// JTAG interface
	wire core1_tdi;
	wire core1_tdo;
	
	// SRAM rw port
	wire core1SRAM_clk0;
	wire[1:0] core1SRAM_csb0;
	wire core1SRAM_web0;
	wire[3:0] core1SRAM_wmask0;
	wire[SRAM_ADDRESS_SIZE-1:0] core1SRAM_addr0;
	wire[31:0] core1SRAM_din0;
	wire[63:0] core1SRAM_dout0;

	// SRAM r port
	wire core1SRAM_clk1;
	wire[1:0] core1SRAM_csb1;
	wire[SRAM_ADDRESS_SIZE-1:0] core1SRAM_addr1;
	wire[63:0] core1SRAM_dout1;

	// Logic probes
	wire probe_core1_state;
	wire[1:0] probe_core1_env;
	wire[31:0] probe_core1_programCounter;
	wire[4:0] probe_core1_jtagInstruction;

	wire[39:0] probe_core1 = {
		probe_core1_state,
		probe_core1_env,
		probe_core1_programCounter,
		probe_core1_jtagInstruction
	};

	ExperiarCore core1 (
`ifdef USE_POWER_PINS
		.vccd1(vccd1),	// User area 1 1.8V power
		.vssd1(vssd1),	// User area 1 digital ground
`endif
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.coreIndex(core1Index),
		.manufacturerID(manufacturerID),
		.partID(partID),
		.versionID(versionID),
		.jtag_tck(jtag_tck),
		.jtag_tms(jtag_tms),
		.jtag_tdi(core1_tdi),
		.jtag_tdo(core1_tdo),
		.irq(irq),
		.core_wb_cyc_o(core1_wb_cyc_o),
		.core_wb_stb_o(core1_wb_stb_o),
		.core_wb_we_o(core1_wb_we_o),
		.core_wb_sel_o(core1_wb_sel_o),
		.core_wb_data_o(core1_wb_data_o),
		.core_wb_adr_o(core1_wb_adr_o),
		.core_wb_ack_i(core1_wb_ack_i),
		.core_wb_stall_i(core1_wb_stall_i),
		.core_wb_error_i(core1_wb_error_i),
		.core_wb_data_i(core1_wb_data_i),
		.localMemory_wb_cyc_i(core1Memory_wb_cyc_i),
		.localMemory_wb_stb_i(core1Memory_wb_stb_i),
		.localMemory_wb_we_i(core1Memory_wb_we_i),
		.localMemory_wb_sel_i(core1Memory_wb_sel_i),
		.localMemory_wb_data_i(core1Memory_wb_data_i),
		.localMemory_wb_adr_i(core1Memory_wb_adr_i),
		.localMemory_wb_ack_o(core1Memory_wb_ack_o),
		.localMemory_wb_stall_o(core1Memory_wb_stall_o),
		.localMemory_wb_error_o(core1Memory_wb_error_o),
		.localMemory_wb_data_o(core1Memory_wb_data_o),
		.clk0(core1SRAM_clk0),
		.csb0(core1SRAM_csb0),
		.web0(core1SRAM_web0),
		.wmask0(core1SRAM_wmask0),
		.addr0(core1SRAM_addr0),
		.din0(core1SRAM_din0),
		.dout0(core1SRAM_dout0),
		.clk1(core1SRAM_clk1),
		.csb1(core1SRAM_csb1),
		.addr1(core1SRAM_addr1),
		.dout1(core1SRAM_dout1),
		.probe_state(probe_core1_state),
		.probe_env(probe_core1_env),
		.probe_programCounter(probe_core1_programCounter),
		.probe_jtagInstruction(probe_core1_jtagInstruction));

	wire[31:0] core1SRAM0_dout0;
	wire[31:0] core1SRAM0_dout1;
	sky130_sram_2kbyte_1rw1r_32x512_8 core1SRAM0(
`ifdef USE_POWER_PINS
		.vccd1(vccd1),	// User area 1 1.8V power
		.vssd1(vssd1),	// User area 1 digital ground
`endif
		.clk0(core1SRAM_clk0),
		.csb0(core1SRAM_csb0[0]),
		.web0(core1SRAM_web0),
		.wmask0(core1SRAM_wmask0),
		.addr0(core1SRAM_addr0),
		.din0(core1SRAM_din0),
		.dout0(core1SRAM0_dout0),
		.clk1(core1SRAM_clk1),
		.csb1(core1SRAM_csb1[0]),
		.addr1(core1SRAM_addr1),
		.dout1(core1SRAM0_dout1));

	wire[31:0] core1SRAM1_dout0;
	wire[31:0] core1SRAM1_dout1;
	sky130_sram_2kbyte_1rw1r_32x512_8 core1SRAM1(
`ifdef USE_POWER_PINS
		.vccd1(vccd1),	// User area 1 1.8V power
		.vssd1(vssd1),	// User area 1 digital ground
`endif
		.clk0(core1SRAM_clk0),
		.csb0(core1SRAM_csb0[1]),
		.web0(core1SRAM_web0),
		.wmask0(core1SRAM_wmask0),
		.addr0(core1SRAM_addr0),
		.din0(core1SRAM_din0),
		.dout0(core1SRAM1_dout0),
		.clk1(core1SRAM_clk1),
		.csb1(core1SRAM_csb1[1]),
		.addr1(core1SRAM_addr1),
		.dout1(core1SRAM1_dout1));

	assign core1SRAM_dout0 = { core1SRAM1_dout0, core1SRAM0_dout0 };
	assign core1SRAM_dout1 = { core1SRAM1_dout1, core1SRAM0_dout1 };

	//-------------------------------------------------//
	//------------------Cached Memory------------------//
	//-------------------------------------------------//

	// Cache SRAM rw port
	wire cachedMemorySRAM_clk0 [0:1];
	wire cachedMemorySRAM_csb0 [0:1];
	wire cachedMemorySRAM_web0 [0:1];
	wire[3:0] cachedMemorySRAM_wmask0 [0:1];
	wire[SRAM_ADDRESS_SIZE-1:0] cachedMemorySRAM_addr0 [0:1];
	wire[31:0] cachedMemorySRAM_din0 [0:1];
	wire[31:0] cachedMemorySRAM_dout0 [0:1];

	// Cache SRAM r port
	wire cachedMemorySRAM_clk1 [0:1];
	wire cachedMemorySRAM_csb1 [0:1];
	wire[SRAM_ADDRESS_SIZE-1:0] cachedMemorySRAM_addr1 [0:1];
	wire[31:0] cachedMemorySRAM_dout1 [0:1];

	genvar cachedMemoryIndex;
	generate
		for (cachedMemoryIndex = 0; cachedMemoryIndex < 2; cachedMemoryIndex = cachedMemoryIndex + 1) begin	
			CachedMemory cachedMemory(
`ifdef USE_POWER_PINS
				.vccd1(vccd1),	// User area 1 1.8V power
				.vssd1(vssd1),	// User area 1 digital ground
`endif
				.wb_clk_i(wb_clk_i),
				.wb_rst_i(wb_rst_i),
				.wb_stb_i(cachedMemory_wb_stb_i[cachedMemoryIndex]),
				.wb_cyc_i(cachedMemory_wb_cyc_i[cachedMemoryIndex]),
				.wb_we_i(cachedMemory_wb_we_i[cachedMemoryIndex]),
				.wb_sel_i(cachedMemory_wb_sel_i[cachedMemoryIndex]),
				.wb_data_i(cachedMemory_wb_data_i[cachedMemoryIndex]),
				.wb_adr_i(cachedMemory_wb_adr_i[cachedMemoryIndex]),
				.wb_ack_o(cachedMemory_wb_ack_o[cachedMemoryIndex]),
				.wb_stall_o(cachedMemory_wb_stall_o[cachedMemoryIndex]),
				.wb_error_o(cachedMemory_wb_error_o[cachedMemoryIndex]),
				.wb_data_o(cachedMemory_wb_data_o[cachedMemoryIndex]),
				.qspi_enable(cachedMemory_en[cachedMemoryIndex]),
				.qspi_csb(cachedMemory_csb[cachedMemoryIndex]),
				.qspi_sck(cachedMemory_sck[cachedMemoryIndex]),
				.qspi_io0_we(cachedMemory_io0_we[cachedMemoryIndex]),
				.qspi_io0_write(cachedMemory_io0_write[cachedMemoryIndex]),
				.qspi_io0_read(cachedMemory_io0_read[cachedMemoryIndex]),
				.qspi_io1_we(cachedMemory_io1_we[cachedMemoryIndex]),
				.qspi_io1_write(cachedMemory_io1_write[cachedMemoryIndex]),
				.qspi_io1_read(cachedMemory_io1_read[cachedMemoryIndex]),
				.sram_clk0(cachedMemorySRAM_clk0[cachedMemoryIndex]),
				.sram_csb0(cachedMemorySRAM_csb0[cachedMemoryIndex]),
				.sram_web0(cachedMemorySRAM_web0[cachedMemoryIndex]),
				.sram_wmask0(cachedMemorySRAM_wmask0[cachedMemoryIndex]),
				.sram_addr0(cachedMemorySRAM_addr0[cachedMemoryIndex]),
				.sram_din0(cachedMemorySRAM_din0[cachedMemoryIndex]),
				.sram_dout0(cachedMemorySRAM_dout0[cachedMemoryIndex]),
				.sram_clk1(cachedMemorySRAM_clk1[cachedMemoryIndex]),
				.sram_csb1(cachedMemorySRAM_csb1[cachedMemoryIndex]),
				.sram_addr1(cachedMemorySRAM_addr1[cachedMemoryIndex]),
				.sram_dout1(cachedMemorySRAM_dout1[cachedMemoryIndex]));

				sky130_sram_2kbyte_1rw1r_32x512_8 cachedMemorySRAM(
`ifdef USE_POWER_PINS
				.vccd1(vccd1),	// User area 1 1.8V power
				.vssd1(vssd1),	// User area 1 digital ground
`endif
				.clk0(cachedMemorySRAM_clk0[cachedMemoryIndex]),
				.csb0(cachedMemorySRAM_csb0[cachedMemoryIndex]),
				.web0(cachedMemorySRAM_web0[cachedMemoryIndex]),
				.wmask0(cachedMemorySRAM_wmask0[cachedMemoryIndex]),
				.addr0(cachedMemorySRAM_addr0[cachedMemoryIndex]),
				.din0(cachedMemorySRAM_din0[cachedMemoryIndex]),
				.dout0(cachedMemorySRAM_dout0[cachedMemoryIndex]),
				.clk1(cachedMemorySRAM_clk1[cachedMemoryIndex]),
				.csb1(cachedMemorySRAM_csb1[cachedMemoryIndex]),
				.addr1(cachedMemorySRAM_addr1[cachedMemoryIndex]),
				.dout1(cachedMemorySRAM_dout1[cachedMemoryIndex])
			);
		end
	endgenerate

	//-------------------------------------------------//
	//----------------------Video----------------------//
	//-------------------------------------------------//

	// VGA
	wire[1:0] vga_r;
	wire[1:0] vga_g;
	wire[1:0] vga_b;
	wire vga_vsync;
	wire vga_hsync;

	// Left Video SRAM rw port
	wire videoSRAMLeft_clk0;
	wire[1:0] videoSRAMLeft_csb0;
	wire videoSRAMLeft_web0;
	wire[3:0] videoSRAMLeft_wmask0;
	wire[SRAM_ADDRESS_SIZE-1:0] videoSRAMLeft_addr0;
	wire[31:0] videoSRAMLeft_din0;
	wire[63:0] videoSRAMLeft_dout0;

	// Left Video SRAM r port
	wire videoSRAMLeft_clk1;
	wire[1:0] videoSRAMLeft_csb1;
	wire[SRAM_ADDRESS_SIZE-1:0] videoSRAMLeft_addr1;
	wire[63:0] videoSRAMLeft_dout1;

	// Right Video SRAM rw port
	wire videoSRAMRight_clk0;
	wire[1:0] videoSRAMRight_csb0;
	wire videoSRAMRight_web0;
	wire[3:0] videoSRAMRight_wmask0;
	wire[SRAM_ADDRESS_SIZE-1:0] videoSRAMRight_addr0;
	wire[31:0] videoSRAMRight_din0;
	wire[63:0] videoSRAMRight_dout0;

	// Right Video SRAM r port
	wire videoSRAMRight_clk1;
	wire[1:0] videoSRAMRight_csb1;
	wire[SRAM_ADDRESS_SIZE-1:0] videoSRAMRight_addr1;
	wire[63:0] videoSRAMRight_dout1;

	wire[1:0] video_irq;
	Video video(
`ifdef USE_POWER_PINS
		.vccd1(vccd1),	// User area 1 1.8V power
		.vssd1(vssd1),	// User area 1 digital ground
`endif
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.wb_stb_i(videoMemory_wb_stb_i),
		.wb_cyc_i(videoMemory_wb_cyc_i),
		.wb_we_i(videoMemory_wb_we_i),
		.wb_sel_i(videoMemory_wb_sel_i),
		.wb_data_i(videoMemory_wb_data_i),
		.wb_adr_i(videoMemory_wb_adr_i),
		.wb_ack_o(videoMemory_wb_ack_o),
		.wb_stall_o(videoMemory_wb_stall_o),
		.wb_error_o(videoMemory_wb_error_o),
		.wb_data_o(videoMemory_wb_data_o),
		.video_irq(video_irq),
		.sram0_clk0(videoSRAMLeft_clk0),
		.sram0_csb0(videoSRAMLeft_csb0),
		.sram0_web0(videoSRAMLeft_web0),
		.sram0_wmask0(videoSRAMLeft_wmask0),
		.sram0_addr0(videoSRAMLeft_addr0),
		.sram0_din0(videoSRAMLeft_din0),
		.sram0_dout0(videoSRAMLeft_dout0),
		.sram0_clk1(videoSRAMLeft_clk1),
		.sram0_csb1(videoSRAMLeft_csb1),
		.sram0_addr1(videoSRAMLeft_addr1),
		.sram0_dout1(videoSRAMLeft_dout1),
		.sram1_clk0(videoSRAMRight_clk0),
		.sram1_csb0(videoSRAMRight_csb0),
		.sram1_web0(videoSRAMRight_web0),
		.sram1_wmask0(videoSRAMRight_wmask0),
		.sram1_addr0(videoSRAMRight_addr0),
		.sram1_din0(videoSRAMRight_din0),
		.sram1_dout0(videoSRAMRight_dout0),
		.sram1_clk1(videoSRAMRight_clk1),
		.sram1_csb1(videoSRAMRight_csb1),
		.sram1_addr1(videoSRAMRight_addr1),
		.sram1_dout1(videoSRAMRight_dout1),
		//.vga_clk(wb_clk_i),
		.vga_r(vga_r),
		.vga_g(vga_g),
		.vga_b(vga_b),
		.vga_vsync(vga_vsync),
		.vga_hsync(vga_hsync));

	wire[31:0] videoSRAM0_dout0;
	wire[31:0] videoSRAM0_dout1;
	sky130_sram_2kbyte_1rw1r_32x512_8 videoSRAM0(
`ifdef USE_POWER_PINS
		.vccd1(vccd1),	// User area 1 1.8V power
		.vssd1(vssd1),	// User area 1 digital ground
`endif
		.clk0(videoSRAMLeft_clk0),
		.csb0(videoSRAMLeft_csb0[0]),
		.web0(videoSRAMLeft_web0),
		.wmask0(videoSRAMLeft_wmask0),
		.addr0(videoSRAMLeft_addr0),
		.din0(videoSRAMLeft_din0),
		.dout0(videoSRAM0_dout0),
		.clk1(videoSRAMLeft_clk1),
		.csb1(videoSRAMLeft_csb1[0]),
		.addr1(videoSRAMLeft_addr1),
		.dout1(videoSRAM0_dout1)
	);

	wire[31:0] videoSRAM1_dout0;
	wire[31:0] videoSRAM1_dout1;
	sky130_sram_2kbyte_1rw1r_32x512_8 videoSRAM1(
`ifdef USE_POWER_PINS
		.vccd1(vccd1),	// User area 1 1.8V power
		.vssd1(vssd1),	// User area 1 digital ground
`endif
		.clk0(videoSRAMLeft_clk0),
		.csb0(videoSRAMLeft_csb0[1]),
		.web0(videoSRAMLeft_web0),
		.wmask0(videoSRAMLeft_wmask0),
		.addr0(videoSRAMLeft_addr0),
		.din0(videoSRAMLeft_din0),
		.dout0(videoSRAM1_dout0),
		.clk1(videoSRAMLeft_clk1),
		.csb1(videoSRAMLeft_csb1[1]),
		.addr1(videoSRAMLeft_addr1),
		.dout1(videoSRAM1_dout1)
	);

	assign videoSRAMLeft_dout0 = { videoSRAM1_dout0, videoSRAM0_dout0 };
	assign videoSRAMLeft_dout1 = { videoSRAM1_dout1, videoSRAM0_dout1 };

	wire[31:0] videoSRAM2_dout0;
	wire[31:0] videoSRAM2_dout1;
	sky130_sram_2kbyte_1rw1r_32x512_8 videoSRAM2(
`ifdef USE_POWER_PINS
		.vccd1(vccd1),	// User area 1 1.8V power
		.vssd1(vssd1),	// User area 1 digital ground
`endif
		.clk0(videoSRAMRight_clk0),
		.csb0(videoSRAMRight_csb0[0]),
		.web0(videoSRAMRight_web0),
		.wmask0(videoSRAMRight_wmask0),
		.addr0(videoSRAMRight_addr0),
		.din0(videoSRAMRight_din0),
		.dout0(videoSRAM2_dout0),
		.clk1(videoSRAMRight_clk1),
		.csb1(videoSRAMRight_csb1[0]),
		.addr1(videoSRAMRight_addr1),
		.dout1(videoSRAM2_dout1)
	);

	wire[31:0] videoSRAM3_dout0;
	wire[31:0] videoSRAM3_dout1;
	sky130_sram_2kbyte_1rw1r_32x512_8 videoSRAM3(
`ifdef USE_POWER_PINS
		.vccd1(vccd1),	// User area 1 1.8V power
		.vssd1(vssd1),	// User area 1 digital ground
`endif
		.clk0(videoSRAMRight_clk0),
		.csb0(videoSRAMRight_csb0[1]),
		.web0(videoSRAMRight_web0),
		.wmask0(videoSRAMRight_wmask0),
		.addr0(videoSRAMRight_addr0),
		.din0(videoSRAMRight_din0),
		.dout0(videoSRAM3_dout0),
		.clk1(videoSRAMRight_clk1),
		.csb1(videoSRAMRight_csb1[1]),
		.addr1(videoSRAMRight_addr1),
		.dout1(videoSRAM3_dout1)
	);

	assign videoSRAMRight_dout0 = { videoSRAM3_dout0, videoSRAM2_dout0 };
	assign videoSRAMRight_dout1 = { videoSRAM3_dout1, videoSRAM2_dout1 };

	//-------------------------------------------------//
	//-------------------Peripherals-------------------//
	//-------------------------------------------------//
	wire[1:0] probe_blink;
	wire[9:0] peripheral_irq;
	Peripherals peripherals(
`ifdef USE_POWER_PINS
		.vccd1(vccd1),	// User area 1 1.8V power
		.vssd1(vssd1),	// User area 1 digital ground
`endif
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.wb_stb_i(peripherals_wb_stb_i),
		.wb_cyc_i(peripherals_wb_cyc_i),
		.wb_we_i(peripherals_wb_we_i),
		.wb_sel_i(peripherals_wb_sel_i),
		.wb_data_i(peripherals_wb_data_i),
		.wb_adr_i(peripherals_wb_adr_i),
		.wb_ack_o(peripherals_wb_ack_o),
		.wb_stall_o(peripherals_wb_stall_o),
		.wb_error_o(peripherals_wb_error_o),
		.wb_data_o(peripherals_wb_data_o),
		.io_in(io_in),
		.io_out(io_out),
		.io_oeb(io_oeb),
		.internal_uart_rx(caravel_uart_rx),
		.internal_uart_tx(caravel_uart_tx),
		.jtag_tck(jtag_tck),
		.jtag_tms(jtag_tms),
		.jtag_tdi(jtag_tdi),
		.jtag_tdo(jtag_tdo),
		.cachedMemory_en(cachedMemory_en),
		.cachedMemory_csb(cachedMemory_csb),
		.cachedMemory_sck(cachedMemory_sck),
		.cachedMemory_io0_we(cachedMemory_io0_we),
		.cachedMemory_io0_write(cachedMemory_io0_write),
		.cachedMemory_io0_read(cachedMemory_io0_read),
		.cachedMemory_io1_we(cachedMemory_io1_we),
		.cachedMemory_io1_write(cachedMemory_io1_write),
		.cachedMemory_io1_read(cachedMemory_io1_read),
		//.irq_en(irq_en),
		//.irq_in(irq_in),
		.peripheral_irq(peripheral_irq),
		.vga_r(vga_r),
		.vga_g(vga_g),
		.vga_b(vga_b),
		.vga_vsync(vga_vsync),
		.vga_hsync(vga_hsync),
		.probe_blink(probe_blink));

	//-------------------------------------------------//
	//-----------------------DMA-----------------------//
	//-------------------------------------------------//

	//DMA dma();

	assign core0_tdi = jtag_tdi;
	assign core1_tdi = core0_tdo;
	assign jtag_tdo = core1_tdo;

	assign probe_out = {
		probe_core1,				// 40
		probe_core0,				// 40
		probe_wishboneInterconnect,	// 16
		probe_blink					// 2
	};

	//-------------------------------------------------//
	//-----------------------IRQ-----------------------//
	//-------------------------------------------------//

	assign irq = { caravel_irq, video_irq, peripheral_irq };

endmodule