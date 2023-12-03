`default_nettype none

module ControllerArbiter (
		input wire clk,
		input wire rst,

		input wire[3:0] request,
		output wire[1:0] controllerSelected
	);

	localparam CONTROLLER0 = 2'h0;
	localparam CONTROLLER1 = 2'h1;
	localparam CONTROLLER2 = 2'h2;
	localparam CONTROLLER3 = 2'h3;

	reg[1:0] currentController = CONTROLLER0;
	reg[1:0] nextController;

	always @(*) begin
		nextController = currentController;

		case (currentController)
			CONTROLLER0: begin
				if (!request[0]) begin
					if (request[1]) nextController = CONTROLLER1;
					else if (request[2]) nextController = CONTROLLER2;
					else if (request[3]) nextController = CONTROLLER3;
				end
			end

			CONTROLLER1: begin
				if (!request[1]) begin
					if (request[2]) nextController = CONTROLLER2;
					else if (request[3]) nextController = CONTROLLER3;
					else if (request[0]) nextController = CONTROLLER0;
				end
			end

			CONTROLLER2: begin
				if (!request[2]) begin
					if (request[3]) nextController = CONTROLLER3;
					else if (request[0]) nextController = CONTROLLER0;
					else if (request[1]) nextController = CONTROLLER1;
				end
			end

			CONTROLLER3: begin
				if (!request[3]) begin
					if (request[0]) nextController = CONTROLLER0;
					else if (request[1]) nextController = CONTROLLER1;
					else if (request[2]) nextController = CONTROLLER2;
				end
			end
		endcase
	end

	always @(posedge clk) begin
		if (rst) currentController <= CONTROLLER0;
		else currentController <= nextController;
	end

	assign controllerSelected = nextController;

endmodule
