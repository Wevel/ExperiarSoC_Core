`default_nettype none

module VideoMemory (
`ifdef USE_POWER_PINS
		inout VPWR,
		inout VGND,
`endif

		input wire clk,
		input wire rst,

		// Peripheral bus interface
		input wire peripheralBus_we,
		input wire peripheralBus_oe,
		output wire peripheralBus_busy,
		input wire[23:0] peripheralBus_address,
		input wire[3:0] peripheralBus_byteSelect,
		input wire[31:0] peripheralBus_dataWrite,
		output wire[31:0] peripheralBus_dataRead,
		output wire requestOutput,

		// Video interface
		input wire pixel_spriteMode,
		input wire pixel_fetchData,
		input wire[SRAM_ADDRESS_SIZE+3-1:0] pixel_address,
		output reg[31:0] pixel_data,

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
		input wire[31:0] sram_tileMap_secondaryDataRead
	);

	localparam SRAM_ADDRESS_SIZE = 10;
	localparam SRAM_PERIPHERAL_BUS_ADDRESS = 11'h000;

	// ---------------------------------------------------------------- //
	// ----------------------- Primary Bus Port ----------------------- //
	// ---------------------------------------------------------------- //

	wire peripheralBusValidAddress = peripheralBus_address[23:SRAM_ADDRESS_SIZE+3] == SRAM_PERIPHERAL_BUS_ADDRESS;
	wire peripheralBusReadEnable = peripheralBus_oe && peripheralBusValidAddress;
	wire peripheralBusWriteEnable = peripheralBus_we && peripheralBusValidAddress;
	wire peripheralBusEnableSRAM = peripheralBusReadEnable || peripheralBusWriteEnable;
	wire peripheralBusSRAMBank = peripheralBus_address[SRAM_ADDRESS_SIZE+2];

	// Set enable bit for peripheral bus port
	always @(*) begin
		sram_pixel_primarySelect = 1'b0;
		sram_tileMap_primarySelect = 1'b0;

		if (peripheralBusEnableSRAM) begin
			case (peripheralBusSRAMBank)
				1'b0: sram_pixel_primarySelect = 1'b1;
				1'b1: sram_tileMap_primarySelect = 1'b1;
			endcase
		end
	end

	// Read data only valid the clock cycle after the address is sent
	reg wbReadReady = 1'b0;
	always @(posedge clk) begin
		if (rst) wbReadReady <= 1'b0;
		else if (peripheralBusReadEnable) wbReadReady <= 1'b1;
		else wbReadReady <= 1'b0;
	end

	reg[31:0] readData;
	assign peripheralBus_dataRead = {
		peripheralBus_byteSelect[3] && wbReadReady ? readData[31:24] : 8'h00,
		peripheralBus_byteSelect[2] && wbReadReady ? readData[23:16] : 8'h00,
		peripheralBus_byteSelect[1] && wbReadReady ? readData[15:8]  : 8'h00,
		peripheralBus_byteSelect[0] && wbReadReady ? readData[7:0]   : 8'h00
	};

	assign peripheralBus_busy = peripheralBusReadEnable && !wbReadReady;
	assign requestOutput = peripheralBusReadEnable;

	assign sram_pixel_primaryWriteEnable = peripheralBusWriteEnable;
	assign sram_pixel_primaryWriteMask = peripheralBus_byteSelect;
	assign sram_pixel_primaryAddress = peripheralBus_address[SRAM_ADDRESS_SIZE+1:2];
	assign sram_pixel_primaryDataWrite = peripheralBus_dataWrite;

	assign sram_tileMap_primaryWriteEnable = peripheralBusWriteEnable;
	assign sram_tileMap_primaryWriteMask = peripheralBus_byteSelect;
	assign sram_tileMap_primaryAddress = peripheralBus_address[SRAM_ADDRESS_SIZE+1:2];
	assign sram_tileMap_primaryDataWrite = peripheralBus_dataWrite;

	// Select return data for peripheral bus port
	always @(*) begin
		if (peripheralBusReadEnable) begin
			case (peripheralBusSRAMBank)
				1'b0: readData = sram_pixel_primaryDataRead;
				1'b1: readData = sram_tileMap_primaryDataRead;
			endcase
		end else begin
			readData = ~32'b0;
		end
	end

	// ---------------------------------------------------------------- //
	// -------------------- Secondary Display Data -------------------- //
	// ---------------------------------------------------------------- //

	// Set enable bit for video port
	always @(*) begin
		sram_pixel_secondarySelect = 1'b0;
		sram_tileMap_secondarySelect = 1'b0;

		if (pixel_fetchData) begin
			if (pixel_spriteMode) begin
				sram_pixel_secondarySelect = 1'b1;
				sram_tileMap_secondarySelect = 1'b1;
			end else begin
				case (pixel_address[SRAM_ADDRESS_SIZE+2])
					1'b0: sram_pixel_secondarySelect = 1'b1;
					1'b1: sram_tileMap_secondarySelect = 1'b1;
				endcase
			end
		end
	end

	// Address for video port
	always @(*) begin
		if (pixel_spriteMode) begin
			sram_pixel_secondaryAddress = sram_tileMap_secondaryDataRead[SRAM_ADDRESS_SIZE-1:0];
			sram_tileMap_secondaryAddress = pixel_address[SRAM_ADDRESS_SIZE+1:2];
		end else begin
			sram_pixel_secondaryAddress = pixel_address[SRAM_ADDRESS_SIZE+1:2];
			sram_tileMap_secondaryAddress = pixel_address[SRAM_ADDRESS_SIZE+1:2];
		end
	end

	// Select return data for video port
	always @(*) begin
		pixel_data = 32'b0;

		if (pixel_fetchData) begin
			if (pixel_spriteMode) begin
				pixel_data = sram_pixel_secondaryDataRead;
			end else begin
				case (pixel_address[SRAM_ADDRESS_SIZE+2])
					1'b0: pixel_data = sram_pixel_secondaryDataRead;
					1'b1: pixel_data = sram_tileMap_secondaryDataRead;
				endcase
			end
		end
	end

	wire[1:0] _unused_peripheralBus_address = peripheralBus_address[1:0];

endmodule
