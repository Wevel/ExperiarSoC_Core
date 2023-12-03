`default_nettype none

`define DFFRAM_ADDRESS_SIZE 6

module SRAM_Wrapper_DFF_RW #(
		parameter BYTE_COUNT = 4,
		parameter ADDRESS_SIZE = 9
	)(
`ifdef USE_POWER_PINS
		inout VPWR,
		inout VGND,
`endif

		input wire clk,
		input wire rst,

		// Primary RW port
		input wire primarySelect,
		input wire primaryWriteEnable,
		input wire[BYTE_COUNT-1:0] primaryWriteMask,
		input wire[ADDRESS_SIZE-1:0] primaryAddress,
		input wire[WORD_SIZE-1:0] primaryDataWrite,
		output reg[WORD_SIZE-1:0] primaryDataRead
	);

	localparam WORD_SIZE = 8 * BYTE_COUNT;

generate

	if (BYTE_COUNT == 4) begin

		if (ADDRESS_SIZE == `DFFRAM_ADDRESS_SIZE) begin

			// Based on sky130 sram verilog model
			// Primary RW port
			wire primarySelect_reg;
			wire primaryWriteEnable_reg;
			wire[BYTE_COUNT-1:0] primaryWriteMask_reg;
			wire[ADDRESS_SIZE-1:0] primaryAddress_reg;
			wire[WORD_SIZE-1:0] primaryDataWrite_reg;

			always @(posedge clk0) begin
				// Primary RW port
				primarySelect_reg <= primarySelect;
				primaryWriteEnable_reg <= primaryWriteEnable;
				primaryWriteMask_reg <= primaryWriteMask;
				primaryAddress_reg <= primaryAddress;
				primaryDataWrite_reg <= primaryDataWrite;
			end

			// Read from memory
			wire[WORD_SIZE-1:0] primaryDataReadOut;
			always @ (negedge clk) begin
				if (primarySelect_reg && !primaryWriteEnable_reg) primaryDataRead <= primaryDataReadOut;
			end

			// Only one SRAM is needed for this configuration
			RAM32 sram(
				.CLK(clk),
				.EN0(primarySelect_reg),
				.A0(primaryAddress_reg),
				.Di0(primaryDataWrite_reg),
				.Do0(primaryDataReadOut),
				.WE0(primaryWriteEnable & primaryWriteMask_reg));

		end else if (ADDRESS_SIZE > 9) begin

			// Recursively instantiate SRAMWrappers to create a memory with the desired address size
			wire[(2*WORD_SIZE)-1:0] primaryDataReadFull;

			SRAM_Wrapper_DFF_RW #(
				.BYTE_COUNT(BYTE_COUNT),
				.ADDRESS_SIZE(ADDRESS_SIZE-1)
			) sramWrapperHigh (
`ifdef USE_POWER_PINS
				.VPWR(VPWR),
				.VGND(VGND),
`endif
				.clk(clk),
				.rst(rst),
				.primarySelect(primarySelect && primaryAddress[ADDRESS_SIZE-1]), // MSB of primary address
				.primaryWriteEnable(primaryWriteEnable),
				.primaryWriteMask(primaryWriteMask),
				.primaryAddress(primaryAddress[ADDRESS_SIZE-2:0]),
				.primaryDataWrite(primaryDataWrite),
				.primaryDataRead(primaryDataReadFull[(2*WORD_SIZE)-1:WORD_SIZE]));

			SRAM_Wrapper_DFF_RW #(
				.BYTE_COUNT(BYTE_COUNT),
				.ADDRESS_SIZE(ADDRESS_SIZE-1)
			) sramWrapperLow (
`ifdef USE_POWER_PINS
				.VPWR(VPWR),
				.VGND(VGND),
`endif
				.clk(clk),
				.rst(rst),
				.primarySelect(primarySelect && !primaryAddress[ADDRESS_SIZE-1]), // MSB of primary address
				.primaryWriteEnable(primaryWriteEnable),
				.primaryWriteMask(primaryWriteMask),
				.primaryAddress(primaryAddress[ADDRESS_SIZE-2:0]),
				.primaryDataWrite(primaryDataWrite),
				.primaryDataRead(primaryDataReadFull[WORD_SIZE-1:0]));

				assign primaryDataRead = primaryAddress[ADDRESS_SIZE-1] ? primaryDataReadFull[(2*WORD_SIZE)-1:WORD_SIZE] : primaryDataReadFull[WORD_SIZE-1:0];

		end else begin
`ifdef SIM
			$display("Unsupported ADDRESS_SIZE", ADDRESS_SIZE);
`endif
		end

	end else begin
`ifdef SIM
		$display("Unsupported BYTE_COUNT", BYTE_COUNT);
`endif
	end

endgenerate

endmodule
