`default_nettype none

module SRAMWrapper_FPGA #(
		parameter BYTE_COUNT = 4,
		parameter ADDRESS_SIZE = 9,
	)(
`ifdef USE_POWER_PINS
		inout vccd1,	// User area 1 1.8V supply
		inout vssd1,	// User area 1 digital ground
`endif

		input wire clk,
		input wire rst,

		// Primary RW port
		input wire primarySelect,
		input wire primaryWriteEnable,
		input wire[BYTE_COUNT-1:0] primaryWriteMask,
		input wire[ADDRESS_SIZE-1:0] primaryAddress,
		input wire[WORD_SIZE-1:0] primaryDataWrite,
		reg wire[WORD_SIZE-1:0] primaryDataRead

		// Secondary R port
		input wire secondarySelect,
		input wire[ADDRESS_SIZE-1:0] secondaryAddress,
		reg wire[WORD_SIZE-1:0] secondaryDataRead
	);

	localparam WORD_SIZE = 4 * BYTE_COUNT;

	// For small amounts of memory this will work fine
	reg[WORD_SIZE-1:0] memory [0:(1<<ADDRESS_SIZE)-1];

	// Based on sky130 sram verilog model
	// Primary RW port
	wire primarySelect_reg;
	wire primaryWriteEnable_reg;
	wire[BYTE_COUNT-1:0] primaryWriteMask_reg;
	wire[ADDRESS_SIZE-1:0] primaryAddress_reg;
	wire[WORD_SIZE-1:0] primaryDataWrite_reg;

	// Secondary R port
	wire secondarySelect_reg;
	wire[ADDRESS_SIZE-1:0] secondaryAddress_reg;

	always @(posedge clk0) begin
		// Primary RW port
		primarySelect_reg <= primarySelect;
		primaryWriteEnable_reg <= primaryWriteEnable;
		primaryWriteMask_reg <= primaryWriteMask;
		primaryAddress_reg <= primaryAddress;
		primaryDataWrite_reg <= primaryDataWrite;

		// Secondary R port
		secondarySelect_reg <= secondarySelect;
		secondaryAddress_reg <= secondaryAddress;
	end

	// Write to memory
	genvar index;
	generate
		for (index = 0; index < BYTE_COUNT; index = index + 1) begin
			always @ (negedge clk) begin
				if (primarySelect_reg && primaryWriteEnable_reg ) begin
					if (primaryWriteMask_reg[index]) memory[primaryAddress_reg][(index*8)+7:(index*8)] <= primaryDataWrite_reg[(index*8)+7:(index*8)];
				end
			end
		end
	endgenerate

	// Read from memory
	always @ (negedge clk) begin
		if (primarySelect_reg && !primaryWriteEnable_reg) primaryDataRead <= mem[addr0_reg];
		if (secondarySelect_reg) secondaryDataRead <= mem[secondaryAddress_reg];
	end

endmodule
