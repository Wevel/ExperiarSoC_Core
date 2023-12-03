`default_nettype none

module WishboneMultiControllerDevice (
		input wire wb_clk_i,
		input wire wb_rst_i,

		// Controller 0
		input wire controller0_wb_cyc_o,
		input wire controller0_wb_stb_o,
		input wire controller0_wb_we_o,
		input wire[3:0] controller0_wb_sel_o,
		input wire[31:0] controller0_wb_data_o,
		input wire[23:0] controller0_wb_adr_o,
		output wire controller0_wb_ack_i,
		output wire controller0_wb_stall_i,
		output wire controller0_wb_error_i,
		output wire[31:0] controller0_wb_data_i,

		// Controller 1
		input wire controller1_wb_cyc_o,
		input wire controller1_wb_stb_o,
		input wire controller1_wb_we_o,
		input wire[3:0] controller1_wb_sel_o,
		input wire[31:0] controller1_wb_data_o,
		input wire[23:0] controller1_wb_adr_o,
		output wire controller1_wb_ack_i,
		output wire controller1_wb_stall_i,
		output wire controller1_wb_error_i,
		output wire[31:0] controller1_wb_data_i,

		// Controller 2
		input wire controller2_wb_cyc_o,
		input wire controller2_wb_stb_o,
		input wire controller2_wb_we_o,
		input wire[3:0] controller2_wb_sel_o,
		input wire[31:0] controller2_wb_data_o,
		input wire[23:0] controller2_wb_adr_o,
		output wire controller2_wb_ack_i,
		output wire controller2_wb_stall_i,
		output wire controller2_wb_error_i,
		output wire[31:0] controller2_wb_data_i,

		// Controller 3
		input wire controller3_wb_cyc_o,
		input wire controller3_wb_stb_o,
		input wire controller3_wb_we_o,
		input wire[3:0] controller3_wb_sel_o,
		input wire[31:0] controller3_wb_data_o,
		input wire[23:0] controller3_wb_adr_o,
		output wire controller3_wb_ack_i,
		output wire controller3_wb_stall_i,
		output wire controller3_wb_error_i,
		output wire[31:0] controller3_wb_data_i,

		// Device
		output wire device_cyc_i,
		output wire device_stb_i,
		output wire device_we_i,
		output wire[3:0] device_sel_i,
		output wire[31:0] device_data_i,
		output wire[23:0] device_adr_i,
		input wire device_ack_o,
		input wire device_stall_o,
		input wire device_error_o,
		input wire[31:0] device_data_o,

		output wire[1:0] probe_currentController
	);

	wire[1:0] currentController;
	ControllerArbiter arbiter(
		.clk(wb_clk_i),
		.rst(wb_rst_i),
		.request({ controller3_wb_cyc_o, controller2_wb_cyc_o, controller1_wb_cyc_o, controller0_wb_cyc_o }),
		.controllerSelected(currentController));

	wire controller0Select = currentController == 2'h0;
	wire controller1Select = currentController == 2'h1;
	wire controller2Select = currentController == 2'h2;
	wire controller3Select = currentController == 2'h3;

	assign device_cyc_i =  controller1Select ? controller1_wb_cyc_o :
						  controller2Select ? controller2_wb_cyc_o :
						  controller3Select ? controller3_wb_cyc_o :
							  			  controller0_wb_cyc_o;
	assign device_stb_i =  controller1Select ? controller1_wb_stb_o :
						  controller2Select ? controller2_wb_stb_o :
						  controller3Select ? controller3_wb_stb_o :
							  			  controller0_wb_stb_o;
	assign device_we_i =   controller1Select ? controller1_wb_we_o :
						  controller2Select ? controller2_wb_we_o :
						  controller3Select ? controller3_wb_we_o :
							  			  controller0_wb_we_o;
	assign device_sel_i =  controller1Select ? controller1_wb_sel_o :
						  controller2Select ? controller2_wb_sel_o :
						  controller3Select ? controller3_wb_sel_o :
							  			  controller0_wb_sel_o;
	assign device_data_i = controller1Select ? controller1_wb_data_o :
						  controller2Select ? controller2_wb_data_o :
						  controller3Select ? controller3_wb_data_o :
							  			  controller0_wb_data_o;
	assign device_adr_i =  controller1Select ? controller1_wb_adr_o :
						  controller2Select ? controller2_wb_adr_o :
						  controller3Select ? controller3_wb_adr_o :
							  			  controller0_wb_adr_o;

	// Controller 0
	assign controller0_wb_ack_i   = controller0Select ? device_ack_o : 1'b0;
	assign controller0_wb_stall_i = controller0Select ? device_stall_o : 1'b0;
	assign controller0_wb_error_i = controller0Select ? device_error_o : 1'b0;
	assign controller0_wb_data_i  = device_data_o;

	// Controller 1
	assign controller1_wb_ack_i   = controller1Select ? device_ack_o : 1'b0;
	assign controller1_wb_stall_i = controller1Select ? device_stall_o : 1'b0;
	assign controller1_wb_error_i = controller1Select ? device_error_o : 1'b0;
	assign controller1_wb_data_i  = device_data_o;

	// Controller 2
	assign controller2_wb_ack_i   = controller2Select ? device_ack_o : 1'b0;
	assign controller2_wb_stall_i = controller2Select ? device_stall_o : 1'b0;
	assign controller2_wb_error_i = controller2Select ? device_error_o : 1'b0;
	assign controller2_wb_data_i  = device_data_o;

	// Controller 3
	assign controller3_wb_ack_i   = controller3Select ? device_ack_o : 1'b0;
	assign controller3_wb_stall_i = controller3Select ? device_stall_o : 1'b0;
	assign controller3_wb_error_i = controller3Select ? device_error_o : 1'b0;
	assign controller3_wb_data_i  = device_data_o;

	// Assign logic probes
	assign probe_currentController = currentController;

endmodule
