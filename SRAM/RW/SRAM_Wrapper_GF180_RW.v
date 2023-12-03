`default_nettype none

module SRAM_Wrapper_GF180_RW #(
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
		output wire[WORD_SIZE-1:0] primaryDataRead
	);

	localparam WORD_SIZE = 8 * BYTE_COUNT;

genvar index;
generate

	if (BYTE_COUNT == 1) begin
		if (ADDRESS_SIZE == 9) begin

			// input           CLK;
			// input           CEN;    //Chip Enable
			// input           GWEN;   //Global Write Enable
			// input   [7:0]  	WEN;    //Write Enable
			// input   [8:0]   A;
			// input   [7:0]  	D;
			// output	[7:0]	Q;
			// inout		VDD;
			// inout		VSS;

			// Only one SRAM is needed for this configuration
			gf180mcu_fd_ip_sram__sram512x8m8wm1 sram (
				.CLK(clk),
				.CEN(primarySelect),
				.GWEN(primaryWriteEnable && primaryWriteMask),
				.WEN(~8'b0),
				.A(primaryAddress),
				.D(primaryDataWrite),
				.Q(primaryDataRead),
`ifdef USE_POWER_PINS
				.VDD(VPWR),
				.VSS(VGND)
`endif
			);

		end if (ADDRESS_SIZE == 8) begin

			// Only one SRAM is needed for this configuration
			gf180mcu_fd_ip_sram__sram256x8m8wm1 sram (
				.CLK(clk),
				.CEN(primarySelect),
				.GWEN(primaryWriteEnable && primaryWriteMask),
				.WEN(~8'b0),
				.A(primaryAddress),
				.D(primaryDataWrite),
				.Q(primaryDataRead),
`ifdef USE_POWER_PINS
				.VDD(VPWR),
				.VSS(VGND)
`endif
			);

		end if (ADDRESS_SIZE == 7) begin

			// Only one SRAM is needed for this configuration
			gf180mcu_fd_ip_sram__sram128x8m8wm1 sram (
				.CLK(clk),
				.CEN(primarySelect),
				.GWEN(primaryWriteEnable && primaryWriteMask),
				.WEN(~8'b0),
				.A(primaryAddress),
				.D(primaryDataWrite),
				.Q(primaryDataRead),
`ifdef USE_POWER_PINS
				.VDD(VPWR),
				.VSS(VGND)
`endif
			);

		end if (ADDRESS_SIZE == 6) begin

			// Only one SRAM is needed for this configuration
			gf180mcu_fd_ip_sram__sram64x8m8wm1 sram (
				.CLK(clk),
				.CEN(primarySelect),
				.GWEN(primaryWriteEnable && primaryWriteMask),
				.WEN(~8'b0),
				.A(primaryAddress),
				.D(primaryDataWrite),
				.Q(primaryDataRead),
`ifdef USE_POWER_PINS
				.VDD(VPWR),
				.VSS(VGND)
`endif
			);

		end else if (ADDRESS_SIZE > 9) begin

			// Recursively instantiate SRAMWrappers to create a memory with the desired address size
			wire[(2*WORD_SIZE)-1:0] primaryDataReadFull;

			SRAMWrapper_GF180 #(
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

			SRAMWrapper_GF180 #(
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

	end if (BYTE_COUNT == 4) begin

		// Break into single byte SRAMs
		for (index = 0; index < BYTE_COUNT; index = index + 1) begin
			SRAMWrapper_GF180 #(
				.BYTE_COUNT(1),
				.ADDRESS_SIZE(ADDRESS_SIZE)
			) sramWrapper (
`ifdef USE_POWER_PINS
				.VPWR(VPWR),
				.VGND(VGND),
`endif
				.clk(clk),
				.rst(rst),
				.primarySelect(primarySelect),
				.primaryWriteEnable(primaryWriteEnable),
				.primaryWriteMask(primaryWriteMask[index]),
				.primaryAddress(primaryAddress),
				.primaryDataWrite(primaryDataWrite[(index*8)+7:(index*8)]),
				.primaryDataRead(primaryDataRead[(index*8)+7:(index*8)]));
		end

	end else begin
`ifdef SIM
		$display("Unsupported BYTE_COUNT", BYTE_COUNT);
`endif
	end

endgenerate

endmodule
