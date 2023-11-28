`default_nettype none

`ifndef PERIPHERAL_SELECT_V
`define PERIPHERAL_SELECT_V

module PeripheralSelect #(
		parameter ID = 8'h00
	)(
		input wire[23:0] peripheralBus_address,
		output wire[15:0] localAddress,
		output wire peripheralEnable
	);

	assign peripheralEnable = peripheralBus_address[23:16] == ID;
	assign localAddress = peripheralBus_address[15:0];

endmodule

`endif
