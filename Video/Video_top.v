`default_nettype none

module Video_top (
`ifdef USE_POWER_PINS
		inout VPWR,
		inout VGND,
`endif

		input wire wb_clk_i,
		input wire wb_rst_i,

		// Wishbone device ports
		input wire wb_stb_i,
		input wire wb_cyc_i,
		input wire wb_we_i,
		input wire[3:0] wb_sel_i,
		input wire[31:0] wb_data_i,
		input wire[23:0] wb_adr_i,
		output wire wb_ack_o,
		output wire wb_stall_o,
		output wire wb_error_o,
		output wire[31:0] wb_data_o,

		// IRQ
		output wire[1:0] video_irq,

		// Pixel data memory
		// Pixel SRAM rw bus port
		output reg sram_pixel_primarySelect,
		output wire sram_pixel_primaryWriteEnable,
		output wire[3:0] sram_pixel_primaryWriteMask,
		output wire[SRAM_ADDRESS_SIZE-1:0] sram_pixel_primaryAddress,
		output wire[31:0] sram_pixel_primaryDataWrite,
		input wire[31:0] sram_pixel_primaryDataRead,

		// pixel SRAM r draw port
		output reg sram_pixel_secondarySelect,
		output reg[SRAM_ADDRESS_SIZE-1:0] sram_pixel_secondaryAddress,
		input wire[31:0] sram_pixel_secondaryDataRead,

		// Pixel data memory or tilemap memory depending on mode
		// Tilemap SRAM rw bus port
		output reg sram_tileMap_primarySelect,
		output wire sram_tileMap_primaryWriteEnable,
		output wire[3:0] sram_tileMap_primaryWriteMask,
		output wire[SRAM_ADDRESS_SIZE-1:0] sram_tileMap_primaryAddress,
		output wire[31:0] sram_tileMap_primaryDataWrite,
		input wire[31:0] sram_tileMap_primaryDataRead,

		// Tilemap SRAM r draw port
		output reg sram_tileMap_secondarySelect,
		output reg[SRAM_ADDRESS_SIZE-1:0] sram_tileMap_secondaryAddress,
		input wire[31:0] sram_tileMap_secondaryDataRead,

		// VGA
		//input wire vga_clk,
		output wire[1:0] vga_r,
		output wire[1:0] vga_g,
		output wire[1:0] vga_b,
		output wire vga_vsync,
		output wire vga_hsync
	);

	localparam SRAM_ADDRESS_SIZE = 10;
	localparam TOTAL_SRAM_ADDRESS_SIZE = (SRAM_ADDRESS_SIZE + 3);

	localparam HORIZONTAL_BITS = 6;
	localparam VERTICAL_BITS = (TOTAL_SRAM_ADDRESS_SIZE - HORIZONTAL_BITS);

	wire vga_clk = wb_clk_i;

	wire peripheralBus_we;
	wire peripheralBus_oe;
	wire peripheralBus_busy;
	wire[23:0] peripheralBus_address;
	wire[3:0] peripheralBus_byteSelect;
	wire[31:0] peripheralBus_dataRead;
	wire[31:0] peripheralBus_dataWrite;

	WBPeripheralBusInterface wbPeripheralBusInterface(
`ifdef USE_POWER_PINS
		.VPWR(VPWR),
		.VGND(VGND),
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
		.peripheralBus_busy(peripheralBus_busy),
		.peripheralBus_address(peripheralBus_address),
		.peripheralBus_byteSelect(peripheralBus_byteSelect),
		.peripheralBus_dataRead(peripheralBus_dataRead),
		.peripheralBus_dataWrite(peripheralBus_dataWrite));

	wire vga_spriteMode;
	wire vga_fetchData;
	wire[TOTAL_SRAM_ADDRESS_SIZE-1:0] vga_address;
	wire[31:0] vga_data;

	wire videoMemoryBusBusy;
	wire[31:0] videoMemoryDataRead;
	wire videoMemoryRequestOutput;
	VideoMemory videoMemory(
`ifdef USE_POWER_PINS
		.VPWR(VPWR),
		.VGND(VGND),
`endif
		.clk(wb_clk_i),
		.rst(wb_rst_i),
		.peripheralBus_we(peripheralBus_we),
		.peripheralBus_oe(peripheralBus_oe),
		.peripheralBus_busy(videoMemoryBusBusy),
		.peripheralBus_address(peripheralBus_address),
		.peripheralBus_byteSelect(peripheralBus_byteSelect),
		.peripheralBus_dataRead(videoMemoryDataRead),
		.peripheralBus_dataWrite(peripheralBus_dataWrite),
		.requestOutput(videoMemoryRequestOutput),
		.pixel_spriteMode(vga_spriteMode),
		.pixel_fetchData(vga_fetchData),
		.pixel_address(vga_address),
		.pixel_data(vga_data),
		.sram_pixel_primarySelect(sram_pixel_primarySelect),
		.sram_pixel_primaryWriteEnable(sram_pixel_primaryWriteEnable),
		.sram_pixel_primaryWriteMask(sram_pixel_primaryWriteMask),
		.sram_pixel_primaryAddress(sram_pixel_primaryAddress),
		.sram_pixel_primaryDataWrite(sram_pixel_primaryDataWrite),
		.sram_pixel_primaryDataRead(sram_pixel_primaryDataRead),
		.sram_pixel_secondarySelect(sram_pixel_secondarySelect),
		.sram_pixel_secondaryAddress(sram_pixel_secondaryAddress),
		.sram_pixel_secondaryDataRead(sram_pixel_secondaryDataRead),
		.sram_tileMap_primarySelect(sram_tileMap_primarySelect),
		.sram_tileMap_primaryWriteEnable(sram_tileMap_primaryWriteEnable),
		.sram_tileMap_primaryWriteMask(sram_tileMap_primaryWriteMask),
		.sram_tileMap_primaryAddress(sram_tileMap_primaryAddress),
		.sram_tileMap_primaryDataWrite(sram_tileMap_primaryDataWrite),
		.sram_tileMap_primaryDataRead(sram_tileMap_primaryDataRead),
		.sram_tileMap_secondarySelect(sram_tileMap_secondarySelect),
		.sram_tileMap_secondaryAddress(sram_tileMap_secondaryAddress),
		.sram_tileMap_secondaryDataRead(sram_tileMap_secondaryDataRead));

	wire vgaBusBusy;
	wire[31:0] vgaDataRead;
	wire vgaRequestOutput;
	VGA #(.HORIZONTAL_BITS(HORIZONTAL_BITS), .VERTICAL_BITS(VERTICAL_BITS)) vga(
`ifdef USE_POWER_PINS
		.VPWR(VPWR),
		.VGND(VGND),
`endif
		.clk(wb_clk_i),
		.rst(wb_rst_i),
		.peripheralBus_we(peripheralBus_we),
		.peripheralBus_oe(peripheralBus_oe),
		.peripheralBus_busy(vgaBusBusy),
		.peripheralBus_address(peripheralBus_address),
		.peripheralBus_byteSelect(peripheralBus_byteSelect),
		.peripheralBus_dataRead(vgaDataRead),
		.peripheralBus_dataWrite(peripheralBus_dataWrite),
		.requestOutput(vgaRequestOutput),
		.vga_clk(vga_clk),
		.vga_spriteMode(vga_spriteMode),
		.vga_fetchData(vga_fetchData),
		.vga_address(vga_address),
		.vga_data(vga_data),
		.vga_r(vga_r),
		.vga_g(vga_g),
		.vga_b(vga_b),
		.vga_vsync(vga_vsync),
		.vga_hsync(vga_hsync),
		.vga_irq(video_irq));

	assign peripheralBus_busy = videoMemoryBusBusy || vgaBusBusy;
	assign peripheralBus_dataRead = videoMemoryRequestOutput ? videoMemoryDataRead :
									vgaRequestOutput ? vgaDataRead : ~32'b0;

endmodule
