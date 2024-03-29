`default_nettype none

`ifndef MPRJ_IO_PADS
	`define MPRJ_IO_PADS (19 + 19)
`endif


module Peripherals_top #(
		parameter UART_COUNT = 2,
		parameter PWM_COUNT = 4,
		parameter PWM_OUTPUTS_PER_DEVICE = 2,
		parameter SPI_COUNT = 1
	)(
`ifdef USE_POWER_PINS
		inout VPWR,
		inout VGND,
`endif

		// Wishbone device ports
		input wire wb_clk_i,
		input wire wb_rst_i,
		input wire wb_stb_i,
		input wire wb_cyc_i,
		input wire wb_we_i,
		input wire[3:0] wb_sel_i,
		input wire[31:0] wb_data_i,
		input wire[23:0] wb_adr_i,
		output wire wb_ack_o,
		output wire wb_stall_o,
		output wire wb_error_o,
		output wire[31:0] wb_data_o,

		// IOs
		input  wire[`MPRJ_IO_PADS-1:0] io_in,
		output wire[`MPRJ_IO_PADS-1:0] io_out,
		output wire[`MPRJ_IO_PADS-1:0] io_oeb,

		// Caravel UART
		input wire internal_uart_rx,
		output wire internal_uart_tx,

		// JTAG
		output wire jtag_tck,
		output wire jtag_tms,
		output wire jtag_tdi,
		input wire jtag_tdo,

		// Cached Memory
		input wire[1:0] cachedMemory_en,
		input wire[1:0] cachedMemory_csb,
		input wire[1:0] cachedMemory_sck,
		input wire[1:0] cachedMemory_io0_we,
		input wire[1:0] cachedMemory_io0_write,
		output wire[1:0] cachedMemory_io0_read,
		input wire[1:0] cachedMemory_io1_we,
		input wire[1:0] cachedMemory_io1_write,
		output wire[1:0] cachedMemory_io1_read,

		// IRQ
		// input wire irq_en,
		// output wire irq_in,
		output wire[UART_COUNT+PWM_COUNT+2-1:0] peripheral_irq,

		// VGA
		input wire[1:0] vga_r,
		input wire[1:0] vga_g,
		input wire[1:0] vga_b,
		input wire vga_vsync,
		input wire vga_hsync,

		// Logic Analyzer Signals
		output wire[1:0] probe_blink
	);

	wire irq_en = 1'b0;
	wire irq_in;

	wire peripheralBus_we;
	wire peripheralBus_oe;
	wire peripheralBus_busy;
	wire[23:0] peripheralBus_address;
	wire[3:0] peripheralBus_byteSelect;
	reg[31:0] peripheralBus_dataRead;
	wire[31:0] peripheralBus_dataWrite;

	WBPeripheralBusInterface wbPeripheralBusInterface(
`ifdef USE_POWER_PINS
		.VPWR(VPWR),
		.VGND(VGND),
`endif
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.wb_stb_i(wb_stb_i),
		.wb_cyc_i(wb_cyc_i),
		.wb_we_i(wb_we_i),
		.wb_sel_i(wb_sel_i),
		.wb_data_i(wb_data_i),
		.wb_adr_i(wb_adr_i),
		.wb_ack_o(wb_ack_o),
		.wb_stall_o(wb_stall_o),
		.wb_error_o(wb_error_o),
		.wb_data_o(wb_data_o),
		.peripheralBus_we(peripheralBus_we),
		.peripheralBus_oe(peripheralBus_oe),
		.peripheralBus_busy(peripheralBus_busy),
		.peripheralBus_address(peripheralBus_address),
		.peripheralBus_byteSelect(peripheralBus_byteSelect),
		.peripheralBus_dataRead(peripheralBus_dataRead),
		.peripheralBus_dataWrite(peripheralBus_dataWrite));

	wire uart_peripheralBus_busy;
	wire[31:0] uart_peripheralBus_dataRead;
	wire uart_requestOutput;
	wire[UART_COUNT-1:0] uart_en;
	wire[UART_COUNT-1:0] uart_rx;
	wire[UART_COUNT-1:0] uart_tx;
	wire[UART_COUNT-1:0] uart_irq;
	wire _unused_uart_en0 = uart_en[0]; // Internal UART
	UART #(.ID(8'h00), .DEVICE_COUNT(UART_COUNT)) uart(
`ifdef USE_POWER_PINS
		.VPWR(VPWR),
		.VGND(VGND),
`endif
		.clk(wb_clk_i),
		.rst(wb_rst_i),
		.peripheralBus_we(peripheralBus_we),
		.peripheralBus_oe(peripheralBus_oe),
		.peripheralBus_busy(uart_peripheralBus_busy),
		.peripheralBus_address(peripheralBus_address),
		.peripheralBus_byteSelect(peripheralBus_byteSelect),
		.peripheralBus_dataRead(uart_peripheralBus_dataRead),
		.peripheralBus_dataWrite(peripheralBus_dataWrite),
		.requestOutput(uart_requestOutput),
		.uart_en(uart_en),
		.uart_rx(uart_rx),
		.uart_tx(uart_tx),
		.uart_irq(uart_irq));

	assign uart_rx[0] = internal_uart_rx;
	assign internal_uart_tx = uart_tx[0];

	wire spi_peripheralBus_busy;
	wire[31:0] spi_peripheralBus_dataRead;
	wire spi_requestOutput;
	wire[SPI_COUNT-1:0] spi_en;
	wire[SPI_COUNT-1:0] spi_clk;
	wire[SPI_COUNT-1:0] spi_mosi;
	wire[SPI_COUNT-1:0] spi_miso;
	wire[SPI_COUNT-1:0] spi_cs;
	SPI #(.ID(8'h01), .DEVICE_COUNT(SPI_COUNT)) spi(
`ifdef USE_POWER_PINS
		.VPWR(VPWR),
		.VGND(VGND),
`endif
		.clk(wb_clk_i),
		.rst(wb_rst_i),
		.peripheralBus_we(peripheralBus_we),
		.peripheralBus_oe(peripheralBus_oe),
		.peripheralBus_busy(spi_peripheralBus_busy),
		.peripheralBus_address(peripheralBus_address),
		.peripheralBus_byteSelect(peripheralBus_byteSelect),
		.peripheralBus_dataRead(spi_peripheralBus_dataRead),
		.peripheralBus_dataWrite(peripheralBus_dataWrite),
		.requestOutput(spi_requestOutput),
		.spi_en(spi_en),
		.spi_clk(spi_clk),
		.spi_mosi(spi_mosi),
		.spi_miso(spi_miso),
		.spi_cs(spi_cs));

	wire pwm_peripheralBus_busy;
	wire[31:0] pwm_peripheralBus_dataRead;
	wire pwm_requestOutput;
	wire[(PWM_COUNT*PWM_OUTPUTS_PER_DEVICE)-1:0] pwm_en;
	wire[(PWM_COUNT*PWM_OUTPUTS_PER_DEVICE)-1:0] pwm_out;
	wire[PWM_COUNT-1:0] pwm_irq;
	PWM #(.ID(8'h02), .DEVICE_COUNT(PWM_COUNT), .OUTPUTS_PER_DEVICE(PWM_OUTPUTS_PER_DEVICE)) pwm(
`ifdef USE_POWER_PINS
		.VPWR(VPWR),
		.VGND(VGND),
`endif
		.clk(wb_clk_i),
		.rst(wb_rst_i),
		.peripheralBus_we(peripheralBus_we),
		.peripheralBus_oe(peripheralBus_oe),
		.peripheralBus_busy(pwm_peripheralBus_busy),
		.peripheralBus_address(peripheralBus_address),
		.peripheralBus_byteSelect(peripheralBus_byteSelect),
		.peripheralBus_dataRead(pwm_peripheralBus_dataRead),
		.peripheralBus_dataWrite(peripheralBus_dataWrite),
		.requestOutput(pwm_requestOutput),
		.pwm_en(pwm_en),
		.pwm_out(pwm_out),
		.pwm_irq(pwm_irq));

	wire gpio_peripheralBus_busy;
	wire[31:0] gpio_peripheralBus_dataRead;
	wire gpio_requestOutput;
	wire[`MPRJ_IO_PADS-1:0] gpio_input;
	wire[`MPRJ_IO_PADS-1:0] gpio_output;
	wire[`MPRJ_IO_PADS-1:0] gpio_oe;
	wire[1:0] gpio_irq;
	GPIO #(.ID(8'h03)) gpio(
`ifdef USE_POWER_PINS
		.VPWR(VPWR),
		.VGND(VGND),
`endif
		.clk(wb_clk_i),
		.rst(wb_rst_i),
		.peripheralBus_we(peripheralBus_we),
		.peripheralBus_oe(peripheralBus_oe),
		.peripheralBus_busy(gpio_peripheralBus_busy),
		.peripheralBus_address(peripheralBus_address),
		.peripheralBus_byteSelect(peripheralBus_byteSelect),
		.peripheralBus_dataRead(gpio_peripheralBus_dataRead),
		.peripheralBus_dataWrite(peripheralBus_dataWrite),
		.requestOutput(gpio_requestOutput),
		.gpio_input(gpio_input),
		.gpio_output(gpio_output),
		.gpio_oe(gpio_oe),
		.gpio_irq(gpio_irq));

	IOMultiplexer #(
		 .UART_COUNT(UART_COUNT),
		 .PWM_COUNT(PWM_COUNT),
		 .PWM_OUTPUTS_PER_DEVICE(PWM_OUTPUTS_PER_DEVICE),
		 .SPI_COUNT(SPI_COUNT)
	) ioMux(
`ifdef USE_POWER_PINS
		.VPWR(VPWR),
		.VGND(VGND),
`endif
		.clk(wb_clk_i),
		.rst(wb_rst_i),
		.uart_en(uart_en[UART_COUNT-1:1]),
		.uart_rx(uart_rx[UART_COUNT-1:1]),
		.uart_tx(uart_tx[UART_COUNT-1:1]),
		.spi_en(spi_en),
		.spi_clk(spi_clk),
		.spi_mosi(spi_mosi),
		.spi_miso(spi_miso),
		.spi_cs(spi_cs),
		.pwm_en(pwm_en),
		.pwm_out(pwm_out),
		.gpio_input(gpio_input),
		.gpio_output(gpio_output),
		.gpio_oe(gpio_oe),
		.io_in(io_in),
		.io_out(io_out),
		.io_oeb(io_oeb),
		.jtag_tck(jtag_tck),
		.jtag_tms(jtag_tms),
		.jtag_tdi(jtag_tdi),
		.jtag_tdo(jtag_tdo),
		.cachedMemory_en(cachedMemory_en),
		.cachedMemory_csb(cachedMemory_csb),
		.cachedMemory_sck(cachedMemory_sck),
		.cachedMemory_io0_we(cachedMemory_io0_we),
		.cachedMemory_io0_write(cachedMemory_io0_write),
		.cachedMemory_io0_read(cachedMemory_io0_read),
		.cachedMemory_io1_we(cachedMemory_io1_we),
		.cachedMemory_io1_write(cachedMemory_io1_write),
		.cachedMemory_io1_read(cachedMemory_io1_read),
		.irq_en(irq_en),
		.irq_in(irq_in),
		.vga_r(vga_r),
		.vga_g(vga_g),
		.vga_b(vga_b),
		.vga_vsync(vga_vsync),
		.vga_hsync(vga_hsync),
		.probe_blink(probe_blink));

	wire _unused_irq_in = irq_in;

	always @(*) begin
		case (1'b1)
			uart_requestOutput: peripheralBus_dataRead = uart_peripheralBus_dataRead;
			spi_requestOutput:  peripheralBus_dataRead = spi_peripheralBus_dataRead;
			pwm_requestOutput:  peripheralBus_dataRead = pwm_peripheralBus_dataRead;
			gpio_requestOutput: peripheralBus_dataRead = gpio_peripheralBus_dataRead;
			default: 			peripheralBus_dataRead = ~32'b0;
		endcase
	end

	assign peripheralBus_busy = pwm_peripheralBus_busy |
								uart_peripheralBus_busy |
								spi_peripheralBus_busy |
								gpio_peripheralBus_busy;

	assign peripheral_irq = { pwm_irq, uart_irq, gpio_irq };

endmodule
