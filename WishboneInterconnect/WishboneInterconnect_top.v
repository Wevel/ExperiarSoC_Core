`default_nettype none

module WishboneInterconnect (
`ifdef USE_POWER_PINS
		inout VPWR,
		inout VGND,
`endif
		input wire wb_clk_i,
		input wire wb_rst_i,

		// Controller 0
		input wire controller0_wb_cyc_o,
		input wire controller0_wb_stb_o,
		input wire controller0_wb_we_o,
		input wire[3:0] controller0_wb_sel_o,
		input wire[31:0] controller0_wb_data_o,
		input wire[27:0] controller0_wb_adr_o,
		output reg controller0_wb_ack_i,
		output reg controller0_wb_stall_i,
		output reg controller0_wb_error_i,
		output reg[31:0] controller0_wb_data_i,

		// Controller 1
		input wire controller1_wb_cyc_o,
		input wire controller1_wb_stb_o,
		input wire controller1_wb_we_o,
		input wire[3:0] controller1_wb_sel_o,
		input wire[31:0] controller1_wb_data_o,
		input wire[27:0] controller1_wb_adr_o,
		output reg controller1_wb_ack_i,
		output reg controller1_wb_stall_i,
		output reg controller1_wb_error_i,
		output reg[31:0] controller1_wb_data_i,

		// Controller 2
		input wire controller2_wb_cyc_o,
		input wire controller2_wb_stb_o,
		input wire controller2_wb_we_o,
		input wire[3:0] controller2_wb_sel_o,
		input wire[31:0] controller2_wb_data_o,
		input wire[27:0] controller2_wb_adr_o,
		output reg controller2_wb_ack_i,
		output reg controller2_wb_stall_i,
		output reg controller2_wb_error_i,
		output reg[31:0] controller2_wb_data_i,

		// Controller 3
		// input wire controller3_wb_cyc_o,
		// input wire controller3_wb_stb_o,
		// input wire controller3_wb_we_o,
		// input wire[3:0] controller3_wb_sel_o,
		// input wire[31:0] controller3_wb_data_o,
		// input wire[27:0] controller3_wb_adr_o,
		// output reg controller3_wb_ack_i,
		// output reg controller3_wb_stall_i,
		// output reg controller3_wb_error_i,
		// output reg[31:0] controller3_wb_data_i,

		// Device 0
		output wire device0_wb_cyc_i,
		output wire device0_wb_stb_i,
		output wire device0_wb_we_i,
		output wire[3:0] device0_wb_sel_i,
		output wire[31:0] device0_wb_data_i,
		output wire[23:0] device0_wb_adr_i,
		input wire device0_wb_ack_o,
		input wire device0_wb_stall_o,
		input wire device0_wb_error_o,
		input wire[31:0] device0_wb_data_o,

		// Device 1
		output wire device1_wb_cyc_i,
		output wire device1_wb_stb_i,
		output wire device1_wb_we_i,
		output wire[3:0] device1_wb_sel_i,
		output wire[31:0] device1_wb_data_i,
		output wire[23:0] device1_wb_adr_i,
		input wire device1_wb_ack_o,
		input wire device1_wb_stall_o,
		input wire device1_wb_error_o,
		input wire[31:0] device1_wb_data_o,

		// Device 2
		output wire device2_wb_cyc_i,
		output wire device2_wb_stb_i,
		output wire device2_wb_we_i,
		output wire[3:0] device2_wb_sel_i,
		output wire[31:0] device2_wb_data_i,
		output wire[23:0] device2_wb_adr_i,
		input wire device2_wb_ack_o,
		input wire device2_wb_stall_o,
		input wire device2_wb_error_o,
		input wire[31:0] device2_wb_data_o,

		// Device 3
		output wire device3_wb_cyc_i,
		output wire device3_wb_stb_i,
		output wire device3_wb_we_i,
		output wire[3:0] device3_wb_sel_i,
		output wire[31:0] device3_wb_data_i,
		output wire[23:0] device3_wb_adr_i,
		input wire device3_wb_ack_o,
		input wire device3_wb_stall_o,
		input wire device3_wb_error_o,
		input wire[31:0] device3_wb_data_o,

		// Device 4
		output wire device4_wb_cyc_i,
		output wire device4_wb_stb_i,
		output wire device4_wb_we_i,
		output wire[3:0] device4_wb_sel_i,
		output wire[31:0] device4_wb_data_i,
		output wire[23:0] device4_wb_adr_i,
		input wire device4_wb_ack_o,
		input wire device4_wb_stall_o,
		input wire device4_wb_error_o,
		input wire[31:0] device4_wb_data_o,

		// Device 5
		output wire device5_wb_cyc_i,
		output wire device5_wb_stb_i,
		output wire device5_wb_we_i,
		output wire[3:0] device5_wb_sel_i,
		output wire[31:0] device5_wb_data_i,
		output wire[23:0] device5_wb_adr_i,
		input wire device5_wb_ack_o,
		input wire device5_wb_stall_o,
		input wire device5_wb_error_o,
		input wire[31:0] device5_wb_data_o,

		output wire[3:0] probe_controller0_currentDevice,
		output wire[3:0] probe_controller1_currentDevice,
		output wire[3:0] probe_controller2_currentDevice,
		output wire[3:0] probe_controller3_currentDevice,
		output wire[1:0] probe_device0_currentController,
		output wire[1:0] probe_device1_currentController,
		output wire[1:0] probe_device2_currentController,
		output wire[1:0] probe_device3_currentController,
		output wire[1:0] probe_device4_currentController,
		output wire[1:0] probe_device5_currentController
	);

	// Disble controller3
	wire controller3_wb_cyc_o = 1'b0;
	wire controller3_wb_stb_o = 1'b0;
	wire controller3_wb_we_o = 1'b0;
	wire[3:0] controller3_wb_sel_o = 4'b0;
	wire[31:0] controller3_wb_data_o = ~32'b0;
	wire[27:0] controller3_wb_adr_o = 28'b0;
	reg controller3_wb_ack_i;
	reg controller3_wb_stall_i;
	reg controller3_wb_error_i;
	reg[31:0] controller3_wb_data_i;

	// Controller select signals
	wire[5:0] controller0_device_select;
	wire[5:0] controller1_device_select;
	wire[5:0] controller2_device_select;
	wire[5:0] controller3_device_select;

	genvar deviceIndex;
	generate
		for (deviceIndex = 0; deviceIndex < 6; deviceIndex = deviceIndex + 1) begin
			assign controller0_device_select[deviceIndex] = controller0_wb_adr_o[27:24] == deviceIndex;
			assign controller1_device_select[deviceIndex] = controller1_wb_adr_o[27:24] == deviceIndex;
			assign controller2_device_select[deviceIndex] = controller2_wb_adr_o[27:24] == deviceIndex;
			assign controller3_device_select[deviceIndex] = controller3_wb_adr_o[27:24] == deviceIndex;
		end
	endgenerate

	// Device return signals
	// Controller 0
	wire controller0_device0_wb_ack_i;
	wire controller0_device0_wb_stall_i;
	wire controller0_device0_wb_error_i;
	wire[31:0] controller0_device0_wb_data_i;
	wire controller0_device1_wb_ack_i;
	wire controller0_device1_wb_stall_i;
	wire controller0_device1_wb_error_i;
	wire[31:0] controller0_device1_wb_data_i;
	wire controller0_device2_wb_ack_i;
	wire controller0_device2_wb_stall_i;
	wire controller0_device2_wb_error_i;
	wire[31:0] controller0_device2_wb_data_i;
	wire controller0_device3_wb_ack_i;
	wire controller0_device3_wb_stall_i;
	wire controller0_device3_wb_error_i;
	wire[31:0] controller0_device3_wb_data_i;
	wire controller0_device4_wb_ack_i;
	wire controller0_device4_wb_stall_i;
	wire controller0_device4_wb_error_i;
	wire[31:0] controller0_device4_wb_data_i;
	wire controller0_device5_wb_ack_i;
	wire controller0_device5_wb_stall_i;
	wire controller0_device5_wb_error_i;
	wire[31:0] controller0_device5_wb_data_i;

	// Controller 1
	wire controller1_device0_wb_ack_i;
	wire controller1_device0_wb_stall_i;
	wire controller1_device0_wb_error_i;
	wire[31:0] controller1_device0_wb_data_i;
	wire controller1_device1_wb_ack_i;
	wire controller1_device1_wb_stall_i;
	wire controller1_device1_wb_error_i;
	wire[31:0] controller1_device1_wb_data_i;
	wire controller1_device2_wb_ack_i;
	wire controller1_device2_wb_stall_i;
	wire controller1_device2_wb_error_i;
	wire[31:0] controller1_device2_wb_data_i;
	wire controller1_device3_wb_ack_i;
	wire controller1_device3_wb_stall_i;
	wire controller1_device3_wb_error_i;
	wire[31:0] controller1_device3_wb_data_i;
	wire controller1_device4_wb_ack_i;
	wire controller1_device4_wb_stall_i;
	wire controller1_device4_wb_error_i;
	wire[31:0] controller1_device4_wb_data_i;
	wire controller1_device5_wb_ack_i;
	wire controller1_device5_wb_stall_i;
	wire controller1_device5_wb_error_i;
	wire[31:0] controller1_device5_wb_data_i;

	// Controller 2
	wire controller2_device0_wb_ack_i;
	wire controller2_device0_wb_stall_i;
	wire controller2_device0_wb_error_i;
	wire[31:0] controller2_device0_wb_data_i;
	wire controller2_device1_wb_ack_i;
	wire controller2_device1_wb_stall_i;
	wire controller2_device1_wb_error_i;
	wire[31:0] controller2_device1_wb_data_i;
	wire controller2_device2_wb_ack_i;
	wire controller2_device2_wb_stall_i;
	wire controller2_device2_wb_error_i;
	wire[31:0] controller2_device2_wb_data_i;
	wire controller2_device3_wb_ack_i;
	wire controller2_device3_wb_stall_i;
	wire controller2_device3_wb_error_i;
	wire[31:0] controller2_device3_wb_data_i;
	wire controller2_device4_wb_ack_i;
	wire controller2_device4_wb_stall_i;
	wire controller2_device4_wb_error_i;
	wire[31:0] controller2_device4_wb_data_i;
	wire controller2_device5_wb_ack_i;
	wire controller2_device5_wb_stall_i;
	wire controller2_device5_wb_error_i;
	wire[31:0] controller2_device5_wb_data_i;

	// Controller 3
	wire controller3_device0_wb_ack_i;
	wire controller3_device0_wb_stall_i;
	wire controller3_device0_wb_error_i;
	wire[31:0] controller3_device0_wb_data_i;
	wire controller3_device1_wb_ack_i;
	wire controller3_device1_wb_stall_i;
	wire controller3_device1_wb_error_i;
	wire[31:0] controller3_device1_wb_data_i;
	wire controller3_device2_wb_ack_i;
	wire controller3_device2_wb_stall_i;
	wire controller3_device2_wb_error_i;
	wire[31:0] controller3_device2_wb_data_i;
	wire controller3_device3_wb_ack_i;
	wire controller3_device3_wb_stall_i;
	wire controller3_device3_wb_error_i;
	wire[31:0] controller3_device3_wb_data_i;
	wire controller3_device4_wb_ack_i;
	wire controller3_device4_wb_stall_i;
	wire controller3_device4_wb_error_i;
	wire[31:0] controller3_device4_wb_data_i;
	wire controller3_device5_wb_ack_i;
	wire controller3_device5_wb_stall_i;
	wire controller3_device5_wb_error_i;
	wire[31:0] controller3_device5_wb_data_i;

	// Device 0
	WishboneMultiControllerDevice device0MultiController(
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.controller0_wb_cyc_o(controller0_wb_cyc_o && controller0_device_select[0]),
		.controller0_wb_stb_o(controller0_wb_stb_o),
		.controller0_wb_we_o(controller0_wb_we_o),
		.controller0_wb_sel_o(controller0_wb_sel_o),
		.controller0_wb_data_o(controller0_wb_data_o),
		.controller0_wb_adr_o(controller0_wb_adr_o[23:0]),
		.controller0_wb_ack_i(controller0_device0_wb_ack_i),
		.controller0_wb_stall_i(controller0_device0_wb_stall_i),
		.controller0_wb_error_i(controller0_device0_wb_error_i),
		.controller0_wb_data_i(controller0_device0_wb_data_i),
		.controller1_wb_cyc_o(controller1_wb_cyc_o && controller1_device_select[0]),
		.controller1_wb_stb_o(controller1_wb_stb_o),
		.controller1_wb_we_o(controller1_wb_we_o),
		.controller1_wb_sel_o(controller1_wb_sel_o),
		.controller1_wb_data_o(controller1_wb_data_o),
		.controller1_wb_adr_o(controller1_wb_adr_o[23:0]),
		.controller1_wb_ack_i(controller1_device0_wb_ack_i),
		.controller1_wb_stall_i(controller1_device0_wb_stall_i),
		.controller1_wb_error_i(controller1_device0_wb_error_i),
		.controller1_wb_data_i(controller1_device0_wb_data_i),
		.controller2_wb_cyc_o(controller2_wb_cyc_o && controller2_device_select[0]),
		.controller2_wb_stb_o(controller2_wb_stb_o),
		.controller2_wb_we_o(controller2_wb_we_o),
		.controller2_wb_sel_o(controller2_wb_sel_o),
		.controller2_wb_data_o(controller2_wb_data_o),
		.controller2_wb_adr_o(controller2_wb_adr_o[23:0]),
		.controller2_wb_ack_i(controller2_device0_wb_ack_i),
		.controller2_wb_stall_i(controller2_device0_wb_stall_i),
		.controller2_wb_error_i(controller2_device0_wb_error_i),
		.controller2_wb_data_i(controller2_device0_wb_data_i),
		.controller3_wb_cyc_o(controller3_wb_cyc_o && controller3_device_select[0]),
		.controller3_wb_stb_o(controller3_wb_stb_o),
		.controller3_wb_we_o(controller3_wb_we_o),
		.controller3_wb_sel_o(controller3_wb_sel_o),
		.controller3_wb_data_o(controller3_wb_data_o),
		.controller3_wb_adr_o(controller3_wb_adr_o[23:0]),
		.controller3_wb_ack_i(controller3_device0_wb_ack_i),
		.controller3_wb_stall_i(controller3_device0_wb_stall_i),
		.controller3_wb_error_i(controller3_device0_wb_error_i),
		.controller3_wb_data_i(controller3_device0_wb_data_i),
		.device_cyc_i(device0_wb_cyc_i),
		.device_stb_i(device0_wb_stb_i),
		.device_we_i(device0_wb_we_i),
		.device_sel_i(device0_wb_sel_i),
		.device_data_i(device0_wb_data_i),
		.device_adr_i(device0_wb_adr_i),
		.device_ack_o(device0_wb_ack_o),
		.device_stall_o(device0_wb_stall_o),
		.device_error_o(device0_wb_error_o),
		.device_data_o(device0_wb_data_o),
		.probe_currentController(probe_device0_currentController));

	// Device 1
	WishboneMultiControllerDevice device1MultiController(
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.controller0_wb_cyc_o(controller0_wb_cyc_o && controller0_device_select[1]),
		.controller0_wb_stb_o(controller0_wb_stb_o),
		.controller0_wb_we_o(controller0_wb_we_o),
		.controller0_wb_sel_o(controller0_wb_sel_o),
		.controller0_wb_data_o(controller0_wb_data_o),
		.controller0_wb_adr_o(controller0_wb_adr_o[23:0]),
		.controller0_wb_ack_i(controller0_device1_wb_ack_i),
		.controller0_wb_stall_i(controller0_device1_wb_stall_i),
		.controller0_wb_error_i(controller0_device1_wb_error_i),
		.controller0_wb_data_i(controller0_device1_wb_data_i),
		.controller1_wb_cyc_o(controller1_wb_cyc_o && controller1_device_select[1]),
		.controller1_wb_stb_o(controller1_wb_stb_o),
		.controller1_wb_we_o(controller1_wb_we_o),
		.controller1_wb_sel_o(controller1_wb_sel_o),
		.controller1_wb_data_o(controller1_wb_data_o),
		.controller1_wb_adr_o(controller1_wb_adr_o[23:0]),
		.controller1_wb_ack_i(controller1_device1_wb_ack_i),
		.controller1_wb_stall_i(controller1_device1_wb_stall_i),
		.controller1_wb_error_i(controller1_device1_wb_error_i),
		.controller1_wb_data_i(controller1_device1_wb_data_i),
		.controller2_wb_cyc_o(controller2_wb_cyc_o && controller2_device_select[1]),
		.controller2_wb_stb_o(controller2_wb_stb_o),
		.controller2_wb_we_o(controller2_wb_we_o),
		.controller2_wb_sel_o(controller2_wb_sel_o),
		.controller2_wb_data_o(controller2_wb_data_o),
		.controller2_wb_adr_o(controller2_wb_adr_o[23:0]),
		.controller2_wb_ack_i(controller2_device1_wb_ack_i),
		.controller2_wb_stall_i(controller2_device1_wb_stall_i),
		.controller2_wb_error_i(controller2_device1_wb_error_i),
		.controller2_wb_data_i(controller2_device1_wb_data_i),
		.controller3_wb_cyc_o(controller3_wb_cyc_o && controller3_device_select[1]),
		.controller3_wb_stb_o(controller3_wb_stb_o),
		.controller3_wb_we_o(controller3_wb_we_o),
		.controller3_wb_sel_o(controller3_wb_sel_o),
		.controller3_wb_data_o(controller3_wb_data_o),
		.controller3_wb_adr_o(controller3_wb_adr_o[23:0]),
		.controller3_wb_ack_i(controller3_device1_wb_ack_i),
		.controller3_wb_stall_i(controller3_device1_wb_stall_i),
		.controller3_wb_error_i(controller3_device1_wb_error_i),
		.controller3_wb_data_i(controller3_device1_wb_data_i),
		.device_cyc_i(device1_wb_cyc_i),
		.device_stb_i(device1_wb_stb_i),
		.device_we_i(device1_wb_we_i),
		.device_sel_i(device1_wb_sel_i),
		.device_data_i(device1_wb_data_i),
		.device_adr_i(device1_wb_adr_i),
		.device_ack_o(device1_wb_ack_o),
		.device_stall_o(device1_wb_stall_o),
		.device_error_o(device1_wb_error_o),
		.device_data_o(device1_wb_data_o),
		.probe_currentController(probe_device1_currentController));

	// Device 2
	WishboneMultiControllerDevice device2MultiController(
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.controller0_wb_cyc_o(controller0_wb_cyc_o && controller0_device_select[2]),
		.controller0_wb_stb_o(controller0_wb_stb_o),
		.controller0_wb_we_o(controller0_wb_we_o),
		.controller0_wb_sel_o(controller0_wb_sel_o),
		.controller0_wb_data_o(controller0_wb_data_o),
		.controller0_wb_adr_o(controller0_wb_adr_o[23:0]),
		.controller0_wb_ack_i(controller0_device2_wb_ack_i),
		.controller0_wb_stall_i(controller0_device2_wb_stall_i),
		.controller0_wb_error_i(controller0_device2_wb_error_i),
		.controller0_wb_data_i(controller0_device2_wb_data_i),
		.controller1_wb_cyc_o(controller1_wb_cyc_o && controller1_device_select[2]),
		.controller1_wb_stb_o(controller1_wb_stb_o),
		.controller1_wb_we_o(controller1_wb_we_o),
		.controller1_wb_sel_o(controller1_wb_sel_o),
		.controller1_wb_data_o(controller1_wb_data_o),
		.controller1_wb_adr_o(controller1_wb_adr_o[23:0]),
		.controller1_wb_ack_i(controller1_device2_wb_ack_i),
		.controller1_wb_stall_i(controller1_device2_wb_stall_i),
		.controller1_wb_error_i(controller1_device2_wb_error_i),
		.controller1_wb_data_i(controller1_device2_wb_data_i),
		.controller2_wb_cyc_o(controller2_wb_cyc_o && controller2_device_select[2]),
		.controller2_wb_stb_o(controller2_wb_stb_o),
		.controller2_wb_we_o(controller2_wb_we_o),
		.controller2_wb_sel_o(controller2_wb_sel_o),
		.controller2_wb_data_o(controller2_wb_data_o),
		.controller2_wb_adr_o(controller2_wb_adr_o[23:0]),
		.controller2_wb_ack_i(controller2_device2_wb_ack_i),
		.controller2_wb_stall_i(controller2_device2_wb_stall_i),
		.controller2_wb_error_i(controller2_device2_wb_error_i),
		.controller2_wb_data_i(controller2_device2_wb_data_i),
		.controller3_wb_cyc_o(controller3_wb_cyc_o && controller3_device_select[2]),
		.controller3_wb_stb_o(controller3_wb_stb_o),
		.controller3_wb_we_o(controller3_wb_we_o),
		.controller3_wb_sel_o(controller3_wb_sel_o),
		.controller3_wb_data_o(controller3_wb_data_o),
		.controller3_wb_adr_o(controller3_wb_adr_o[23:0]),
		.controller3_wb_ack_i(controller3_device2_wb_ack_i),
		.controller3_wb_stall_i(controller3_device2_wb_stall_i),
		.controller3_wb_error_i(controller3_device2_wb_error_i),
		.controller3_wb_data_i(controller3_device2_wb_data_i),
		.device_cyc_i(device2_wb_cyc_i),
		.device_stb_i(device2_wb_stb_i),
		.device_we_i(device2_wb_we_i),
		.device_sel_i(device2_wb_sel_i),
		.device_data_i(device2_wb_data_i),
		.device_adr_i(device2_wb_adr_i),
		.device_ack_o(device2_wb_ack_o),
		.device_stall_o(device2_wb_stall_o),
		.device_error_o(device2_wb_error_o),
		.device_data_o(device2_wb_data_o),
		.probe_currentController(probe_device2_currentController));

	// Device 3
	WishboneMultiControllerDevice device3MultiController(
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.controller0_wb_cyc_o(controller0_wb_cyc_o && controller0_device_select[3]),
		.controller0_wb_stb_o(controller0_wb_stb_o),
		.controller0_wb_we_o(controller0_wb_we_o),
		.controller0_wb_sel_o(controller0_wb_sel_o),
		.controller0_wb_data_o(controller0_wb_data_o),
		.controller0_wb_adr_o(controller0_wb_adr_o[23:0]),
		.controller0_wb_ack_i(controller0_device3_wb_ack_i),
		.controller0_wb_stall_i(controller0_device3_wb_stall_i),
		.controller0_wb_error_i(controller0_device3_wb_error_i),
		.controller0_wb_data_i(controller0_device3_wb_data_i),
		.controller1_wb_cyc_o(controller1_wb_cyc_o && controller1_device_select[3]),
		.controller1_wb_stb_o(controller1_wb_stb_o),
		.controller1_wb_we_o(controller1_wb_we_o),
		.controller1_wb_sel_o(controller1_wb_sel_o),
		.controller1_wb_data_o(controller1_wb_data_o),
		.controller1_wb_adr_o(controller1_wb_adr_o[23:0]),
		.controller1_wb_ack_i(controller1_device3_wb_ack_i),
		.controller1_wb_stall_i(controller1_device3_wb_stall_i),
		.controller1_wb_error_i(controller1_device3_wb_error_i),
		.controller1_wb_data_i(controller1_device3_wb_data_i),
		.controller2_wb_cyc_o(controller2_wb_cyc_o && controller2_device_select[3]),
		.controller2_wb_stb_o(controller2_wb_stb_o),
		.controller2_wb_we_o(controller2_wb_we_o),
		.controller2_wb_sel_o(controller2_wb_sel_o),
		.controller2_wb_data_o(controller2_wb_data_o),
		.controller2_wb_adr_o(controller2_wb_adr_o[23:0]),
		.controller2_wb_ack_i(controller2_device3_wb_ack_i),
		.controller2_wb_stall_i(controller2_device3_wb_stall_i),
		.controller2_wb_error_i(controller2_device3_wb_error_i),
		.controller2_wb_data_i(controller2_device3_wb_data_i),
		.controller3_wb_cyc_o(controller3_wb_cyc_o && controller3_device_select[3]),
		.controller3_wb_stb_o(controller3_wb_stb_o),
		.controller3_wb_we_o(controller3_wb_we_o),
		.controller3_wb_sel_o(controller3_wb_sel_o),
		.controller3_wb_data_o(controller3_wb_data_o),
		.controller3_wb_adr_o(controller3_wb_adr_o[23:0]),
		.controller3_wb_ack_i(controller3_device3_wb_ack_i),
		.controller3_wb_stall_i(controller3_device3_wb_stall_i),
		.controller3_wb_error_i(controller3_device3_wb_error_i),
		.controller3_wb_data_i(controller3_device3_wb_data_i),
		.device_cyc_i(device3_wb_cyc_i),
		.device_stb_i(device3_wb_stb_i),
		.device_we_i(device3_wb_we_i),
		.device_sel_i(device3_wb_sel_i),
		.device_data_i(device3_wb_data_i),
		.device_adr_i(device3_wb_adr_i),
		.device_ack_o(device3_wb_ack_o),
		.device_stall_o(device3_wb_stall_o),
		.device_error_o(device3_wb_error_o),
		.device_data_o(device3_wb_data_o),
		.probe_currentController(probe_device3_currentController));

	// Device 4
	WishboneMultiControllerDevice device4MultiController(
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.controller0_wb_cyc_o(controller0_wb_cyc_o && controller0_device_select[4]),
		.controller0_wb_stb_o(controller0_wb_stb_o),
		.controller0_wb_we_o(controller0_wb_we_o),
		.controller0_wb_sel_o(controller0_wb_sel_o),
		.controller0_wb_data_o(controller0_wb_data_o),
		.controller0_wb_adr_o(controller0_wb_adr_o[23:0]),
		.controller0_wb_ack_i(controller0_device4_wb_ack_i),
		.controller0_wb_stall_i(controller0_device4_wb_stall_i),
		.controller0_wb_error_i(controller0_device4_wb_error_i),
		.controller0_wb_data_i(controller0_device4_wb_data_i),
		.controller1_wb_cyc_o(controller1_wb_cyc_o && controller1_device_select[4]),
		.controller1_wb_stb_o(controller1_wb_stb_o),
		.controller1_wb_we_o(controller1_wb_we_o),
		.controller1_wb_sel_o(controller1_wb_sel_o),
		.controller1_wb_data_o(controller1_wb_data_o),
		.controller1_wb_adr_o(controller1_wb_adr_o[23:0]),
		.controller1_wb_ack_i(controller1_device4_wb_ack_i),
		.controller1_wb_stall_i(controller1_device4_wb_stall_i),
		.controller1_wb_error_i(controller1_device4_wb_error_i),
		.controller1_wb_data_i(controller1_device4_wb_data_i),
		.controller2_wb_cyc_o(controller2_wb_cyc_o && controller2_device_select[4]),
		.controller2_wb_stb_o(controller2_wb_stb_o),
		.controller2_wb_we_o(controller2_wb_we_o),
		.controller2_wb_sel_o(controller2_wb_sel_o),
		.controller2_wb_data_o(controller2_wb_data_o),
		.controller2_wb_adr_o(controller2_wb_adr_o[23:0]),
		.controller2_wb_ack_i(controller2_device4_wb_ack_i),
		.controller2_wb_stall_i(controller2_device4_wb_stall_i),
		.controller2_wb_error_i(controller2_device4_wb_error_i),
		.controller2_wb_data_i(controller2_device4_wb_data_i),
		.controller3_wb_cyc_o(controller3_wb_cyc_o && controller3_device_select[4]),
		.controller3_wb_stb_o(controller3_wb_stb_o),
		.controller3_wb_we_o(controller3_wb_we_o),
		.controller3_wb_sel_o(controller3_wb_sel_o),
		.controller3_wb_data_o(controller3_wb_data_o),
		.controller3_wb_adr_o(controller3_wb_adr_o[23:0]),
		.controller3_wb_ack_i(controller3_device4_wb_ack_i),
		.controller3_wb_stall_i(controller3_device4_wb_stall_i),
		.controller3_wb_error_i(controller3_device4_wb_error_i),
		.controller3_wb_data_i(controller3_device4_wb_data_i),
		.device_cyc_i(device4_wb_cyc_i),
		.device_stb_i(device4_wb_stb_i),
		.device_we_i(device4_wb_we_i),
		.device_sel_i(device4_wb_sel_i),
		.device_data_i(device4_wb_data_i),
		.device_adr_i(device4_wb_adr_i),
		.device_ack_o(device4_wb_ack_o),
		.device_stall_o(device4_wb_stall_o),
		.device_error_o(device4_wb_error_o),
		.device_data_o(device4_wb_data_o),
		.probe_currentController(probe_device4_currentController));

	// Device 5
	WishboneMultiControllerDevice device5MultiController(
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.controller0_wb_cyc_o(controller0_wb_cyc_o && controller0_device_select[5]),
		.controller0_wb_stb_o(controller0_wb_stb_o),
		.controller0_wb_we_o(controller0_wb_we_o),
		.controller0_wb_sel_o(controller0_wb_sel_o),
		.controller0_wb_data_o(controller0_wb_data_o),
		.controller0_wb_adr_o(controller0_wb_adr_o[23:0]),
		.controller0_wb_ack_i(controller0_device5_wb_ack_i),
		.controller0_wb_stall_i(controller0_device5_wb_stall_i),
		.controller0_wb_error_i(controller0_device5_wb_error_i),
		.controller0_wb_data_i(controller0_device5_wb_data_i),
		.controller1_wb_cyc_o(controller1_wb_cyc_o && controller1_device_select[5]),
		.controller1_wb_stb_o(controller1_wb_stb_o),
		.controller1_wb_we_o(controller1_wb_we_o),
		.controller1_wb_sel_o(controller1_wb_sel_o),
		.controller1_wb_data_o(controller1_wb_data_o),
		.controller1_wb_adr_o(controller1_wb_adr_o[23:0]),
		.controller1_wb_ack_i(controller1_device5_wb_ack_i),
		.controller1_wb_stall_i(controller1_device5_wb_stall_i),
		.controller1_wb_error_i(controller1_device5_wb_error_i),
		.controller1_wb_data_i(controller1_device5_wb_data_i),
		.controller2_wb_cyc_o(controller2_wb_cyc_o && controller2_device_select[5]),
		.controller2_wb_stb_o(controller2_wb_stb_o),
		.controller2_wb_we_o(controller2_wb_we_o),
		.controller2_wb_sel_o(controller2_wb_sel_o),
		.controller2_wb_data_o(controller2_wb_data_o),
		.controller2_wb_adr_o(controller2_wb_adr_o[23:0]),
		.controller2_wb_ack_i(controller2_device5_wb_ack_i),
		.controller2_wb_stall_i(controller2_device5_wb_stall_i),
		.controller2_wb_error_i(controller2_device5_wb_error_i),
		.controller2_wb_data_i(controller2_device5_wb_data_i),
		.controller3_wb_cyc_o(controller3_wb_cyc_o && controller3_device_select[5]),
		.controller3_wb_stb_o(controller3_wb_stb_o),
		.controller3_wb_we_o(controller3_wb_we_o),
		.controller3_wb_sel_o(controller3_wb_sel_o),
		.controller3_wb_data_o(controller3_wb_data_o),
		.controller3_wb_adr_o(controller3_wb_adr_o[23:0]),
		.controller3_wb_ack_i(controller3_device5_wb_ack_i),
		.controller3_wb_stall_i(controller3_device5_wb_stall_i),
		.controller3_wb_error_i(controller3_device5_wb_error_i),
		.controller3_wb_data_i(controller3_device5_wb_data_i),
		.device_cyc_i(device5_wb_cyc_i),
		.device_stb_i(device5_wb_stb_i),
		.device_we_i(device5_wb_we_i),
		.device_sel_i(device5_wb_sel_i),
		.device_data_i(device5_wb_data_i),
		.device_adr_i(device5_wb_adr_i),
		.device_ack_o(device5_wb_ack_o),
		.device_stall_o(device5_wb_stall_o),
		.device_error_o(device5_wb_error_o),
		.device_data_o(device5_wb_data_o),
		.probe_currentController(probe_device5_currentController));

	// Multiplex the connections back from the device
	// Controller 0
	always @(*) begin
		case (1'b1)
			controller0_device_select[0]: begin
				controller0_wb_ack_i = controller0_device0_wb_ack_i;
				controller0_wb_stall_i = controller0_device0_wb_stall_i;
				controller0_wb_error_i = controller0_device0_wb_error_i;
				controller0_wb_data_i = controller0_device0_wb_data_i;
			end

			controller0_device_select[1]: begin
				controller0_wb_ack_i = controller0_device1_wb_ack_i;
				controller0_wb_stall_i = controller0_device1_wb_stall_i;
				controller0_wb_error_i = controller0_device1_wb_error_i;
				controller0_wb_data_i = controller0_device1_wb_data_i;
			end

			controller0_device_select[2]: begin
				controller0_wb_ack_i = controller0_device2_wb_ack_i;
				controller0_wb_stall_i = controller0_device2_wb_stall_i;
				controller0_wb_error_i = controller0_device2_wb_error_i;
				controller0_wb_data_i = controller0_device2_wb_data_i;
			end

			controller0_device_select[3]: begin
				controller0_wb_ack_i = controller0_device3_wb_ack_i;
				controller0_wb_stall_i = controller0_device3_wb_stall_i;
				controller0_wb_error_i = controller0_device3_wb_error_i;
				controller0_wb_data_i = controller0_device3_wb_data_i;
			end

			controller0_device_select[4]: begin
				controller0_wb_ack_i = controller0_device4_wb_ack_i;
				controller0_wb_stall_i = controller0_device4_wb_stall_i;
				controller0_wb_error_i = controller0_device4_wb_error_i;
				controller0_wb_data_i = controller0_device4_wb_data_i;
			end

			controller0_device_select[5]: begin
				controller0_wb_ack_i = controller0_device5_wb_ack_i;
				controller0_wb_stall_i = controller0_device5_wb_stall_i;
				controller0_wb_error_i = controller0_device5_wb_error_i;
				controller0_wb_data_i = controller0_device5_wb_data_i;
			end

			default: begin
				controller0_wb_ack_i = controller0_wb_cyc_o;
				controller0_wb_stall_i = 1'b0;
				controller0_wb_error_i = 1'b0;
				controller0_wb_data_i = ~32'b0;
			end

		endcase
	end

	// Controller 1
	always @(*) begin
		case (1'b1)
			controller1_device_select[0]: begin
				controller1_wb_ack_i = controller1_device0_wb_ack_i;
				controller1_wb_stall_i = controller1_device0_wb_stall_i;
				controller1_wb_error_i = controller1_device0_wb_error_i;
				controller1_wb_data_i = controller1_device0_wb_data_i;
			end

			controller1_device_select[1]: begin
				controller1_wb_ack_i = controller1_device1_wb_ack_i;
				controller1_wb_stall_i = controller1_device1_wb_stall_i;
				controller1_wb_error_i = controller1_device1_wb_error_i;
				controller1_wb_data_i = controller1_device1_wb_data_i;
			end

			controller1_device_select[2]: begin
				controller1_wb_ack_i = controller1_device2_wb_ack_i;
				controller1_wb_stall_i = controller1_device2_wb_stall_i;
				controller1_wb_error_i = controller1_device2_wb_error_i;
				controller1_wb_data_i = controller1_device2_wb_data_i;
			end

			controller1_device_select[3]: begin
				controller1_wb_ack_i = controller1_device3_wb_ack_i;
				controller1_wb_stall_i = controller1_device3_wb_stall_i;
				controller1_wb_error_i = controller1_device3_wb_error_i;
				controller1_wb_data_i = controller1_device3_wb_data_i;
			end

			controller1_device_select[4]: begin
				controller1_wb_ack_i = controller1_device4_wb_ack_i;
				controller1_wb_stall_i = controller1_device4_wb_stall_i;
				controller1_wb_error_i = controller1_device4_wb_error_i;
				controller1_wb_data_i = controller1_device4_wb_data_i;
			end

			controller1_device_select[5]: begin
				controller1_wb_ack_i = controller1_device5_wb_ack_i;
				controller1_wb_stall_i = controller1_device5_wb_stall_i;
				controller1_wb_error_i = controller1_device5_wb_error_i;
				controller1_wb_data_i = controller1_device5_wb_data_i;
			end

			default: begin
				controller1_wb_ack_i = controller1_wb_cyc_o;
				controller1_wb_stall_i = 1'b0;
				controller1_wb_error_i = 1'b0;
				controller1_wb_data_i = ~32'b0;
			end

		endcase
	end

	// Controller 2
	always @(*) begin
		case (1'b1)
			controller2_device_select[0]: begin
				controller2_wb_ack_i = controller2_device0_wb_ack_i;
				controller2_wb_stall_i = controller2_device0_wb_stall_i;
				controller2_wb_error_i = controller2_device0_wb_error_i;
				controller2_wb_data_i = controller2_device0_wb_data_i;
			end

			controller2_device_select[1]: begin
				controller2_wb_ack_i = controller2_device1_wb_ack_i;
				controller2_wb_stall_i = controller2_device1_wb_stall_i;
				controller2_wb_error_i = controller2_device1_wb_error_i;
				controller2_wb_data_i = controller2_device1_wb_data_i;
			end

			controller2_device_select[2]: begin
				controller2_wb_ack_i = controller2_device2_wb_ack_i;
				controller2_wb_stall_i = controller2_device2_wb_stall_i;
				controller2_wb_error_i = controller2_device2_wb_error_i;
				controller2_wb_data_i = controller2_device2_wb_data_i;
			end

			controller2_device_select[3]: begin
				controller2_wb_ack_i = controller2_device3_wb_ack_i;
				controller2_wb_stall_i = controller2_device3_wb_stall_i;
				controller2_wb_error_i = controller2_device3_wb_error_i;
				controller2_wb_data_i = controller2_device3_wb_data_i;
			end

			controller2_device_select[4]: begin
				controller2_wb_ack_i = controller2_device4_wb_ack_i;
				controller2_wb_stall_i = controller2_device4_wb_stall_i;
				controller2_wb_error_i = controller2_device4_wb_error_i;
				controller2_wb_data_i = controller2_device4_wb_data_i;
			end

			controller2_device_select[5]: begin
				controller2_wb_ack_i = controller2_device5_wb_ack_i;
				controller2_wb_stall_i = controller2_device5_wb_stall_i;
				controller2_wb_error_i = controller2_device5_wb_error_i;
				controller2_wb_data_i = controller2_device5_wb_data_i;
			end

			default: begin
				controller2_wb_ack_i = controller2_wb_cyc_o;
				controller2_wb_stall_i = 1'b0;
				controller2_wb_error_i = 1'b0;
				controller2_wb_data_i = ~32'b0;
			end

		endcase
	end

	// Controller 3
	always @(*) begin
		case (1'b1)
			controller3_device_select[0]: begin
				controller3_wb_ack_i = controller3_device0_wb_ack_i;
				controller3_wb_stall_i = controller3_device0_wb_stall_i;
				controller3_wb_error_i = controller3_device0_wb_error_i;
				controller3_wb_data_i = controller3_device0_wb_data_i;
			end

			controller3_device_select[1]: begin
				controller3_wb_ack_i = controller3_device1_wb_ack_i;
				controller3_wb_stall_i = controller3_device1_wb_stall_i;
				controller3_wb_error_i = controller3_device1_wb_error_i;
				controller3_wb_data_i = controller3_device1_wb_data_i;
			end

			controller3_device_select[2]: begin
				controller3_wb_ack_i = controller3_device2_wb_ack_i;
				controller3_wb_stall_i = controller3_device2_wb_stall_i;
				controller3_wb_error_i = controller3_device2_wb_error_i;
				controller3_wb_data_i = controller3_device2_wb_data_i;
			end

			controller3_device_select[3]: begin
				controller3_wb_ack_i = controller3_device3_wb_ack_i;
				controller3_wb_stall_i = controller3_device3_wb_stall_i;
				controller3_wb_error_i = controller3_device3_wb_error_i;
				controller3_wb_data_i = controller3_device3_wb_data_i;
			end

			controller3_device_select[4]: begin
				controller3_wb_ack_i = controller3_device4_wb_ack_i;
				controller3_wb_stall_i = controller3_device4_wb_stall_i;
				controller3_wb_error_i = controller3_device4_wb_error_i;
				controller3_wb_data_i = controller3_device4_wb_data_i;
			end

			controller3_device_select[5]: begin
				controller3_wb_ack_i = controller3_device5_wb_ack_i;
				controller3_wb_stall_i = controller3_device5_wb_stall_i;
				controller3_wb_error_i = controller3_device5_wb_error_i;
				controller3_wb_data_i = controller3_device5_wb_data_i;
			end

			default: begin
				controller3_wb_ack_i = controller3_wb_cyc_o;
				controller3_wb_stall_i = 1'b0;
				controller3_wb_error_i = 1'b0;
				controller3_wb_data_i = ~32'b0;
			end

		endcase
	end

	assign probe_controller0_currentDevice = controller0_wb_adr_o[27:24];
	assign probe_controller1_currentDevice = controller1_wb_adr_o[27:24];
	assign probe_controller2_currentDevice = controller2_wb_adr_o[27:24];
	assign probe_controller3_currentDevice = controller3_wb_adr_o[27:24];

endmodule
