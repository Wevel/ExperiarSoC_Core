`default_nettype none

module UART #(
		parameter ID = 8'h00,
		parameter DEVICE_COUNT = 4,
		parameter RX_BUFFER_SIZE = 32,
		parameter TX_BUFFER_SIZE = 32
	)(
`ifdef USE_POWER_PINS
		inout VPWR,
		inout VGND,
`endif

		input wire clk,
		input wire rst,

		// Peripheral Bus
		input wire peripheralBus_we,
		input wire peripheralBus_oe,
		output wire peripheralBus_busy,
		input wire[23:0] peripheralBus_address,
		input wire[3:0] peripheralBus_byteSelect,
		output wire[31:0] peripheralBus_dataRead,
		input wire[31:0] peripheralBus_dataWrite,
		output wire requestOutput,

		// UART
		output wire[DEVICE_COUNT-1:0] uart_en,
		input wire[DEVICE_COUNT-1:0] uart_rx,
		output wire[DEVICE_COUNT-1:0] uart_tx,
		output wire[DEVICE_COUNT-1:0] uart_irq
	);

	// Peripheral select
	wire[15:0] localAddress;
	wire peripheralEnable;
	PeripheralSelect #(.ID(ID)) select(
		.peripheralBus_address(peripheralBus_address),
		.localAddress(localAddress),
		.peripheralEnable(peripheralEnable));

	wire[DEVICE_COUNT-1:0] deviceBusy;
	wire[DEVICE_COUNT-1:0] deviceOutputRequest;
	wire[(32 * DEVICE_COUNT) - 1:0] deviceOutputData;
	Mux #(.WIDTH(32), .INPUTS(DEVICE_COUNT), .DEFAULT(~32'b0)) mux(
		.select(deviceOutputRequest),
		.in(deviceOutputData),
		.out(peripheralBus_dataRead),
		.outputEnable(requestOutput));

	genvar i;
	generate
		for (i = 0; i < DEVICE_COUNT; i = i + 1) begin
			UARTDevice #(.ID(i+1), .RX_BUFFER_SIZE(RX_BUFFER_SIZE), .TX_BUFFER_SIZE(TX_BUFFER_SIZE)) device(
				.clk(clk),
				.rst(rst),
				.peripheralEnable(peripheralEnable),
				.peripheralBus_we(peripheralBus_we),
				.peripheralBus_oe(peripheralBus_oe),
				.peripheralBus_busy(deviceBusy[i]),
				.peripheralBus_address(localAddress),
				.peripheralBus_byteSelect(peripheralBus_byteSelect),
				.peripheralBus_dataWrite(peripheralBus_dataWrite),
				.peripheralBus_dataRead(deviceOutputData[(i * 32) + 31:i * 32]),
				.requestOutput(deviceOutputRequest[i]),
				.uart_en(uart_en[i]),
				.uart_rx(uart_rx[i]),
				.uart_tx(uart_tx[i]),
				.uart_irq(uart_irq[i]));
		end
	endgenerate

	assign peripheralBus_busy = |deviceBusy;

endmodule
