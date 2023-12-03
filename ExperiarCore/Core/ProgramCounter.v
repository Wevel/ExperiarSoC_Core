`default_nettype none

module ProgramCounter(
		input wire clk,
		input wire rst,

		input wire[31:0] resetProgramCounterAddress,

		// Management interface
		input wire management_writeProgramCounter_set,
		input wire management_writeProgramCounter_jump,
		input wire[31:0] management_writeData,

		// Pipe control
		input wire state,
		input wire progressPipe,
		input wire stepPipe,
		input wire stallPipe,

		// Program counter jump
		input wire inTrap,
		input wire[31:0] trapVector,
		input wire pipe1_isRET,
		input wire[31:0] trapReturnVector,
		input wire pipe1_jumpEnable,
		input wire[31:0] pipe1_nextProgramCounter,

		// System state
		output reg[31:0] fetchProgramCounter,
		output reg[31:0] nextFetchProgramCounter,
		output reg[31:0] executeProgramCounter,

		// Pipe state
		output reg stepProgramCounter
	);

	localparam STATE_HALT 	 	= 1'b0;
	localparam STATE_EXECUTE 	= 1'b1;

	// Update the next program counter half a clock cycle before the program counter is updated
	// This makes sure the address is updated prior to the instruction being fetched
	always @(*) begin
		if (rst) begin
			nextFetchProgramCounter = resetProgramCounterAddress;
			stepProgramCounter = 1'b0;
		end else begin
			nextFetchProgramCounter = fetchProgramCounter;
			stepProgramCounter = 1'b0;

			case (state)
				STATE_HALT: begin

				end

				STATE_EXECUTE: begin
					if (inTrap) begin
						nextFetchProgramCounter = trapVector;
						stepProgramCounter = 1'b1;
					end	else if (pipe1_isRET) begin
						nextFetchProgramCounter = trapReturnVector;
						stepProgramCounter = 1'b1;
					end else if (pipe1_jumpEnable) begin
						nextFetchProgramCounter = pipe1_nextProgramCounter;
						stepProgramCounter = 1'b1;
					end else if (!stallPipe) begin
						nextFetchProgramCounter = fetchProgramCounter + 4;
						stepProgramCounter = 1'b1;
					end
				end
			endcase
		end
	end

	// Update program counter value
	always @(posedge clk) begin
		if (rst) begin
			fetchProgramCounter <= 32'b0;
			executeProgramCounter <= 32'b0;
		end else begin
			case (state)
				STATE_HALT: begin
					if (!progressPipe) begin
						if (management_writeProgramCounter_set) fetchProgramCounter <= management_writeData;
						else if (management_writeProgramCounter_jump) fetchProgramCounter <= executeProgramCounter + management_writeData;
					end
				end

				STATE_EXECUTE: begin
					if (stepPipe) begin
						if (stepProgramCounter) fetchProgramCounter <= nextFetchProgramCounter;
						if (!stallPipe) executeProgramCounter <= fetchProgramCounter;
					end
				end
			endcase
		end
	end
endmodule
