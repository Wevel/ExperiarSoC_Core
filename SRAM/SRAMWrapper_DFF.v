`default_nettype none

`define DFFRAM_ADDRESS_SIZE 6

module SRAMWrapper_DFF #(
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
		output reg[WORD_SIZE-1:0] primaryDataRead,

		// Secondary R port
		input wire secondarySelect,
		input wire[ADDRESS_SIZE-1:0] secondaryAddress,
		output reg[WORD_SIZE-1:0] secondaryDataRead
	);

	localparam WORD_SIZE = 4 * BYTE_COUNT;

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

			// Read from memory
			wire[WORD_SIZE-1:0] primaryDataReadOut;
			wire[WORD_SIZE-1:0] secondaryDataReadOut;
			always @ (negedge clk) begin
				if (primarySelect_reg && !primaryWriteEnable_reg) primaryDataRead <= primaryDataReadOut;
				if (secondarySelect_reg) secondaryDataRead <= secondaryDataReadOut;
			end

			// Only one SRAM is needed for this configuration
			DFFRF_2R1W sram(
`ifdef USE_POWER_PINS
				.VPWR(VPWR),
    			.VGND(VGND),
`endif
				.CLK(clk),
    			.WE(primarySelect_reg && primaryWriteEnable),
    			.DA(primaryDataReadOut),
    			.DB(secondaryDataReadOut),
    			.DW(primaryDataWrite_reg),
    			.RA(primaryAddress_reg),
    			.RB(secondaryAddress_reg),
    			.RW(primaryAddress_reg)
			);

		end else if (ADDRESS_SIZE > 9) begin
			
			// Recursively instantiate SRAMWrappers to create a memory with the desired address size
			wire[(2*WORD_SIZE)-1:0] primaryDataReadFull;
			wire[(2*WORD_SIZE)-1:0] secondaryDataReadFull;

			SRAMWrapper_DFF #(
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
				.primaryDataRead(primaryDataReadFull[(2*WORD_SIZE)-1:WORD_SIZE]),
				.secondarySelect(secondarySelect && secondaryAddress[ADDRESS_SIZE-1]), // MSB of secondary address
				.secondaryAddress(secondaryAddress[ADDRESS_SIZE-2:0]),
				.secondaryDataRead(secondaryDataReadFull[(2*WORD_SIZE)-1:WORD_SIZE]));

			SRAMWrapper_DFF #(
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
				.primaryDataRead(primaryDataReadFull[WORD_SIZE-1:0]),
				.secondarySelect(secondarySelect && !secondaryAddress[ADDRESS_SIZE-1]), // MSB of secondary address
				.secondaryAddress(secondaryAddress[ADDRESS_SIZE-2:0]),
				.secondaryDataRead(secondaryDataReadFull[WORD_SIZE-1:0]));

				assign primaryDataRead = primaryAddress[ADDRESS_SIZE-1] ? primaryDataReadFull[(2*WORD_SIZE)-1:WORD_SIZE] : primaryDataReadFull[WORD_SIZE-1:0];
				assign secondaryDataRead = secondaryAddress[ADDRESS_SIZE-1] ? secondaryDataReadFull[(2*WORD_SIZE)-1:WORD_SIZE] : secondaryDataReadFull[WORD_SIZE-1:0];

		end else begin
			//$display("Unsupported ADDRESS_SIZE", ADDRESS_SIZE);
		end
		
	end else begin
		//$display("Unsupported BYTE_COUNT", BYTE_COUNT);
	end

endgenerate

endmodule
