`default_nettype none

module FlowControl(
		input wire clk,
		input wire rst,

		// Management control
		input wire management_allowInstruction,
		input wire stateExecute,

		// Memory control
		input wire requestingInstruction,
		input wire instructionBusy,
		input wire requestingData,
		input wire dataBusy,

		// Pipe status
		input wire pipe0_active,
		input wire pipe1_active,
		input wire pipe2_active,
		input wire pipe1_shouldStall,
		input wire pipe2_shouldStall,

		// Pipe control output
		output wire stepPipe,
		output wire stallPipe,
		output wire progressPipe
	);

	wire fetchBusy = requestingInstruction && instructionBusy;
	wire loadStoreBusy = requestingData && dataBusy;
	wire stepBlocked = fetchBusy || loadStoreBusy;
	
	wire pipeActive = pipe0_active || pipe1_active || pipe2_active;

	assign stallPipe = !management_allowInstruction || pipe1_shouldStall || pipe2_shouldStall;
	assign stepPipe = stateExecute && !stepBlocked;
	assign progressPipe = pipeActive || management_allowInstruction;
	
endmodule