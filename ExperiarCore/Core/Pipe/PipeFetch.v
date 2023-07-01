`default_nettype none

module PipeFetch #(
	 	parameter PROGRAM_COUNTER_RESET = 32'b0
	)(
		input wire clk,
		input wire rst,

		// Pipe control
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

	// Pipe control
	always @(posedge clk) begin
		if (rst) begin
			currentPipeStall <= 1'b1;
			lastInstruction <= ~32'b0;
		end else begin
			if (stepPipe) begin
				currentPipeStall <= pipeStall;
				if (!pipeStall) lastInstruction <= instructionCached ? cachedInstruction : currentInstruction;
				else lastInstruction <= ~32'b0;
			end
		end
	end

	// Fetch control
	reg delayedStepPipe;
	always @(negedge clk) begin
		if (rst) begin
			instructionCached <= 1'b0;
			cachedInstruction <= 32'b0;
		end else begin
			if (delayedStepPipe) begin
				instructionCached <= 1'b0;
			end else begin
				if (!fetchBusy && fetchEnable) begin
					instructionCached <= 1'b1;
					cachedInstruction <= currentInstruction;
				end
			end
			
			delayedStepPipe <= stepPipe;
		end
	end

	reg cancelFetch = 1'b0;
	always @(negedge clk) begin
		if (rst) cancelFetch <= 1'b0;
		// else if (stepPipe) cancelFetch <= pipeStall;
	end

	assign active = !pipeStall;

	assign addressMisaligned = |fetchProgramCounter[1:0];

	assign fetchAddress = fetchProgramCounter;
	assign fetchEnable = (pipeStartup || !instructionCached) && !cancelFetch;

endmodule