`default_nettype none

module PipeFetch #(
	 	parameter PROGRAM_COUNTER_RESET = 32'b0
	)(
		input wire clk,
		input wire rst,

		// Pipe control
		input wire run,
		input wire pipeStartup,
		input wire stepPipe,
		input wire pipeStall,
		output reg currentPipeStall,
		output wire active,
		input wire[31:0] currentInstruction,
		output reg[31:0] lastInstruction,

		// Control
		input wire[31:0] fetchProgramCounter,
		output wire addressMisaligned,

		// Memory access
		output wire[31:0] fetchAddress,
		output wire fetchEnable,
		input wire fetchBusy
	);

	reg[31:0] cachedInstruction;
	reg instructionCached;
	reg useCachedInstruction;

	// Pipe control
	always @(posedge clk) begin
		if (rst) begin
			currentPipeStall <= 1'b1;
			lastInstruction <= ~32'b0;
			cachedInstruction <= 32'b0;
			useCachedInstruction <= 1'b0;
		end else begin
			if (stepPipe) begin
				currentPipeStall <= pipeStall;
				if (!pipeStall) lastInstruction <= useCachedInstruction ? cachedInstruction : currentInstruction;
				else lastInstruction <= ~32'b0;

				useCachedInstruction <= 1'b0;
			end else begin
				useCachedInstruction <= instructionCached;

				if (instructionCached && !useCachedInstruction) cachedInstruction <= currentInstruction;
			end
		end
	end

	// Fetch control
	reg delayedStepPipe;
	always @(negedge clk) begin
		if (rst) begin
			instructionCached <= 1'b0;			
		end else begin
			if (stepPipe) begin
				instructionCached <= 1'b0;
			end else begin
				if (!fetchBusy && fetchEnable) begin
					instructionCached <= 1'b1;
				end
			end
			
			delayedStepPipe <= stepPipe;
		end
	end

	assign active = !pipeStall;

	assign addressMisaligned = |fetchProgramCounter[1:0];
	assign fetchAddress = fetchProgramCounter;
	assign fetchEnable = run && (pipeStartup || !useCachedInstruction);

endmodule
