`default_nettype none

`ifndef DEVICE_SELECT_V
`define DEVICE_SELECT_V

module DeviceSelect #(
		parameter ID = 4'h0
	)(
		input wire peripheralEnable,
		input wire[15:0] peripheralBus_address,
		output wire[11:0] localAddress,
		output wire deviceEnable
	);

	assign deviceEnable = peripheralEnable && (peripheralBus_address[15:12] == ID[3:0]);
	assign localAddress = peripheralBus_address[11:0];

endmodule

`endif
