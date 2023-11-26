`default_nettype none

`define PDK_FPGA 		0
`define PDK_SKY130 		1
`define PDK_GF180 		2

module SRAMWrapper #(
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
		output wire[WORD_SIZE-1:0] primaryDataRead

		// Secondary R port
		input wire secondarySelect,
		input wire[ADDRESS_SIZE-1:0] secondaryAddress,
		output wire[WORD_SIZE-1:0] secondaryDataRead
	);

	localparam WORD_SIZE = 4 * BYTE_COUNT;

generate

	case (`PDK)
		`PDK_FPGA: begin
			
			SRAMWrapper_FPGA #(
				.BYTE_COUNT(BYTE_COUNT),
				.ADDRESS_SIZE(ADDRESS_SIZE)
			) sramWrapper (
`ifdef USE_POWER_PINS
				.vccd1(vccd1),	// User area 1 1.8V supply
				.vssd1(vssd1),	// User area 1 digital ground
`endif
				.clk(clk),
				.rst(rst),
				.primarySelect(primarySelect),
				.primaryWriteEnable(primaryWriteEnable),
				.primaryWriteMask(primaryWriteMask),
				.primaryAddress(primaryAddress),
				.primaryDataWrite(primaryDataWrite),
				.primaryDataRead(primaryDataRead)
				.secondarySelect(secondarySelect),
				.secondaryAddress(secondaryAddress),
				.secondaryDataRead(secondaryDataRead));

		end

		`PDK_SKY130: begin
					
			SRAMWrapper_SKY130 #(
				.BYTE_COUNT(BYTE_COUNT),
				.ADDRESS_SIZE(ADDRESS_SIZE)
			) sramWrapper (
`ifdef USE_POWER_PINS
				.vccd1(vccd1),	// User area 1 1.8V supply
				.vssd1(vssd1),	// User area 1 digital ground
`endif
				.clk(clk),
				.rst(rst),
				.primarySelect(primarySelect),
				.primaryWriteEnable(primaryWriteEnable),
				.primaryWriteMask(primaryWriteMask),
				.primaryAddress(primaryAddress),
				.primaryDataWrite(primaryDataWrite),
				.primaryDataRead(primaryDataRead)
				.secondarySelect(secondarySelect),
				.secondaryAddress(secondaryAddress),
				.secondaryDataRead(secondaryDataRead));
				
		end

		`PDK_GF180: begin
						
			SRAMWrapper_GF180 #(
				.BYTE_COUNT(BYTE_COUNT),
				.ADDRESS_SIZE(ADDRESS_SIZE)
			) sramWrapper (
`ifdef USE_POWER_PINS
				.vccd1(vccd1),	// User area 1 1.8V supply
				.vssd1(vssd1),	// User area 1 digital ground
`endif
				.clk(clk),
				.rst(rst),
				.primarySelect(primarySelect),
				.primaryWriteEnable(primaryWriteEnable),
				.primaryWriteMask(primaryWriteMask),
				.primaryAddress(primaryAddress),
				.primaryDataWrite(primaryDataWrite),
				.primaryDataRead(primaryDataRead)
				.secondarySelect(secondarySelect),
				.secondaryAddress(secondaryAddress),
				.secondaryDataRead(secondaryDataRead));
				
		end

		`DEFAUL begin
			$display("Unknown PDK", `PDK);
		end
	endcase

endgenerate



endmodule