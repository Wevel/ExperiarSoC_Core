`default_nettype none

`ifndef MPRJ_IO_PADS
	`define MPRJ_IO_PADS (19 + 19)
`endif

module IOMultiplexer #(
		parameter UART_COUNT = 4,
		parameter PWM_COUNT = 4,
		parameter PWM_OUTPUTS_PER_DEVICE = 2,
		parameter SPI_COUNT = 1
	) (
`ifdef USE_POWER_PINS
		inout VPWR,
		inout VGND,
`endif

		input wire clk,
		input wire rst,

		// IO Modules
		// UART
		input wire[UART_COUNT-1:1] uart_en,
		output wire[UART_COUNT-1:1] uart_rx,
		input  wire[UART_COUNT-1:1] uart_tx,

		// SPI
		input wire[SPI_COUNT-1:0] spi_en,
		input wire[SPI_COUNT-1:0] spi_clk,
		input wire[SPI_COUNT-1:0] spi_mosi,
		output wire[SPI_COUNT-1:0] spi_miso,
		input  wire[SPI_COUNT-1:0] spi_cs,

		// PWM
		input wire[(PWM_COUNT*PWM_OUTPUTS_PER_DEVICE)-1:0] pwm_en,
		input wire[(PWM_COUNT*PWM_OUTPUTS_PER_DEVICE)-1:0] pwm_out,

		// GPIO
		output wire[`MPRJ_IO_PADS-1:0] gpio_input,
		input  wire[`MPRJ_IO_PADS-1:0] gpio_output,
		input  wire[`MPRJ_IO_PADS-1:0] gpio_oe,

		// IO Pads
    	input  wire[`MPRJ_IO_PADS-1:0] io_in,
    	output wire[`MPRJ_IO_PADS-1:0] io_out,
    	output wire[`MPRJ_IO_PADS-1:0] io_oeb,

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
		input wire irq_en,
		output wire irq_in,

		// VGA
		input wire[1:0] vga_r,
		input wire[1:0] vga_g,
		input wire[1:0] vga_b,
		input wire vga_vsync,
		input wire vga_hsync,

		output wire[1:0] probe_blink
	);

	// Test blink
	localparam BLINK_CLOCK_DIV = 26;
	reg blinkEnabled = 1'b1;
	wire[1:0] blink;
	Counter #(.WIDTH(2), .DIV(BLINK_CLOCK_DIV), .TOP(0)) ctr(.clk(clk), .rst(rst), .halt(1'b0), .value(blink));

	always @(posedge clk) begin
		if (rst) blinkEnabled <= 1'b1;
		else if (gpio_oe[PIN_BLINK0]) blinkEnabled <= 1'b0;
	end

	assign probe_blink = blink;

	wire jtag;
	wire _unused_jtag = jtag;
	wire sdo;
	wire sdi;
	wire csb;
	wire sck;

	assign jtag_tck = sck;
	assign jtag_tms = csb;
	assign jtag_tdi = sdi;
	assign sdo = jtag_tdo;

	//-------------------------------------------------//
	//----------------Pin Mapping Start----------------//
	//-------------Start of Generated Code-------------//

	// Interface IO mapping
	// GPIO0 (user1 side)
	// IO00: JTAG
	// IO01: SDO
	// IO02: SDI
	// IO03: CSB
	// IO04: SCK
	// IO05: GPIO05 or UART1_RX
	// IO06: GPIO06 or UART1_TX
	// IO07: GPIO07 or IRQ
	// IO08: GPIO08 or CachedMemory0_CSB
	// IO09: GPIO09 or CachedMemory0_SCK
	// IO10: GPIO10 or CachedMemory0_IO0
	// IO11: GPIO11 or CachedMemory0_IO1
	// IO12: GPIO12 or CachedMemory1_CSB
	// IO13: GPIO13 or CachedMemory1_SCK
	// IO14: GPIO14 or CachedMemory1_IO0
	// IO15: GPIO15 or CachedMemory1_IO1
	// IO16: GPIO16 or PWM0
	// IO17: GPIO17 or PWM1
	// IO18: GPIO18 or PWM2

	// GPIO1 (user2 side)
	// IO19: GPIO19 or PWM3
	// IO20: GPIO20 or PWM4
	// IO21: GPIO21 or PWM5
	// IO22: GPIO22 or SPI0_CLK
	// IO23: GPIO23 or SPI0_MOSI
	// IO24: GPIO24 or SPI0_MISO
	// IO25: GPIO25 or SPI0_CS
	// IO26: GPIO26 or PWM6
	// IO27: GPIO27 or PWM7
	// IO28: GPIO28 or BLINK0
	// IO29: GPIO29 or BLINK1
	// IO30: VGA_R0
	// IO31: VGA_R1
	// IO32: VGA_G0
	// IO33: VGA_G1
	// IO34: VGA_B0
	// IO35: VGA_B1
	// IO36: VGA_VSYNC
	// IO37: VGA_HSYNC

	// IO00-PIN_JTAG: Input
	localparam PIN_JTAG = 0;
	assign gpio_input[PIN_JTAG] = 1'b0;
	assign io_out[PIN_JTAG] = 1'b0;
	assign io_oeb[PIN_JTAG] = 1'b1;
	assign jtag = io_in[PIN_JTAG];

	// IO01-PIN_SDO: Output
	localparam PIN_SDO = 1;
	assign gpio_input[PIN_SDO] = 1'b0;
	assign io_out[PIN_SDO] = sdo;
	assign io_oeb[PIN_SDO] = 1'b0;

	// IO02-PIN_SDI: Input
	localparam PIN_SDI = 2;
	assign gpio_input[PIN_SDI] = 1'b0;
	assign io_out[PIN_SDI] = 1'b0;
	assign io_oeb[PIN_SDI] = 1'b1;
	assign sdi = io_in[PIN_SDI];

	// IO03-PIN_CSB: Input
	localparam PIN_CSB = 3;
	assign gpio_input[PIN_CSB] = 1'b0;
	assign io_out[PIN_CSB] = 1'b0;
	assign io_oeb[PIN_CSB] = 1'b1;
	assign csb = io_in[PIN_CSB];

	// IO04-PIN_SCK: Input
	localparam PIN_SCK = 4;
	assign gpio_input[PIN_SCK] = 1'b0;
	assign io_out[PIN_SCK] = 1'b0;
	assign io_oeb[PIN_SCK] = 1'b1;
	assign sck = io_in[PIN_SCK];

	// IO05-PIN_UART1_RX: Input
	localparam PIN_UART1_RX = 5;
	assign gpio_input[PIN_UART1_RX] = uart_en[1] ? 1'b0 : (gpio_oe[PIN_UART1_RX] ? io_in[PIN_UART1_RX] : 1'b0);
	assign io_out[PIN_UART1_RX] = uart_en[1] ? 1'b0 : gpio_output[PIN_UART1_RX];
	assign io_oeb[PIN_UART1_RX] = uart_en[1] ? 1'b1 : gpio_oe[PIN_UART1_RX];
	assign uart_rx[1] = uart_en[1] ? io_in[PIN_UART1_RX] : 1'b1;

	// IO06-PIN_UART1_TX: Output
	localparam PIN_UART1_TX = 6;
	assign gpio_input[PIN_UART1_TX] = uart_en[1] ? 1'b0 : (gpio_oe[PIN_UART1_TX] ? io_in[PIN_UART1_TX] : 1'b0);
	assign io_out[PIN_UART1_TX] = uart_en[1] ? uart_tx[1] : gpio_output[PIN_UART1_TX];
	assign io_oeb[PIN_UART1_TX] = uart_en[1] ? 1'b0 : gpio_oe[PIN_UART1_TX];

	// IO07-PIN_IRQ: Input
	localparam PIN_IRQ = 7;
	assign gpio_input[PIN_IRQ] = irq_en ? 1'b0 : (gpio_oe[PIN_IRQ] ? io_in[PIN_IRQ] : 1'b0);
	assign io_out[PIN_IRQ] = irq_en ? 1'b0 : gpio_output[PIN_IRQ];
	assign io_oeb[PIN_IRQ] = irq_en ? 1'b1 : gpio_oe[PIN_IRQ];
	assign irq_in = irq_en ? io_in[PIN_IRQ] : 1'b0;

	// IO08-PIN_CACHEDMEMORY0_CSB: Output
	localparam PIN_CACHEDMEMORY0_CSB = 8;
	assign gpio_input[PIN_CACHEDMEMORY0_CSB] = cachedMemory_en[0] ? 1'b0 : (gpio_oe[PIN_CACHEDMEMORY0_CSB] ? io_in[PIN_CACHEDMEMORY0_CSB] : 1'b0);
	assign io_out[PIN_CACHEDMEMORY0_CSB] = cachedMemory_en[0] ? cachedMemory_csb[0] : gpio_output[PIN_CACHEDMEMORY0_CSB];
	assign io_oeb[PIN_CACHEDMEMORY0_CSB] = cachedMemory_en[0] ? 1'b0 : gpio_oe[PIN_CACHEDMEMORY0_CSB];

	// IO09-PIN_CACHEDMEMORY0_SCK: Output
	localparam PIN_CACHEDMEMORY0_SCK = 9;
	assign gpio_input[PIN_CACHEDMEMORY0_SCK] = cachedMemory_en[0] ? 1'b0 : (gpio_oe[PIN_CACHEDMEMORY0_SCK] ? io_in[PIN_CACHEDMEMORY0_SCK] : 1'b0);
	assign io_out[PIN_CACHEDMEMORY0_SCK] = cachedMemory_en[0] ? cachedMemory_sck[0] : gpio_output[PIN_CACHEDMEMORY0_SCK];
	assign io_oeb[PIN_CACHEDMEMORY0_SCK] = cachedMemory_en[0] ? 1'b0 : gpio_oe[PIN_CACHEDMEMORY0_SCK];

	// IO10-PIN_CACHEDMEMORY0_IO0: InOut
	localparam PIN_CACHEDMEMORY0_IO0 = 10;
	assign gpio_input[PIN_CACHEDMEMORY0_IO0] = cachedMemory_en[0] ? 1'b0 : (gpio_oe[PIN_CACHEDMEMORY0_IO0] ? io_in[PIN_CACHEDMEMORY0_IO0] : 1'b0);
	assign io_out[PIN_CACHEDMEMORY0_IO0] = cachedMemory_en[0] ? cachedMemory_io0_write[0] : gpio_output[PIN_CACHEDMEMORY0_IO0];
	assign io_oeb[PIN_CACHEDMEMORY0_IO0] = cachedMemory_en[0] ? !cachedMemory_io0_we[0] : gpio_oe[PIN_CACHEDMEMORY0_IO0];
	assign cachedMemory_io0_read[0] = cachedMemory_en[0] && !cachedMemory_io0_we[0] ? io_in[PIN_CACHEDMEMORY0_IO0] : 1'b0;

	// IO11-PIN_CACHEDMEMORY0_IO1: InOut
	localparam PIN_CACHEDMEMORY0_IO1 = 11;
	assign gpio_input[PIN_CACHEDMEMORY0_IO1] = cachedMemory_en[0] ? 1'b0 : (gpio_oe[PIN_CACHEDMEMORY0_IO1] ? io_in[PIN_CACHEDMEMORY0_IO1] : 1'b0);
	assign io_out[PIN_CACHEDMEMORY0_IO1] = cachedMemory_en[0] ? cachedMemory_io1_write[0] : gpio_output[PIN_CACHEDMEMORY0_IO1];
	assign io_oeb[PIN_CACHEDMEMORY0_IO1] = cachedMemory_en[0] ? !cachedMemory_io1_we[0] : gpio_oe[PIN_CACHEDMEMORY0_IO1];
	assign cachedMemory_io1_read[0] = cachedMemory_en[0] && !cachedMemory_io1_we[0] ? io_in[PIN_CACHEDMEMORY0_IO1] : 1'b0;

	// IO12-PIN_CACHEDMEMORY1_CSB: Output
	localparam PIN_CACHEDMEMORY1_CSB = 12;
	assign gpio_input[PIN_CACHEDMEMORY1_CSB] = cachedMemory_en[1] ? 1'b0 : (gpio_oe[PIN_CACHEDMEMORY1_CSB] ? io_in[PIN_CACHEDMEMORY1_CSB] : 1'b0);
	assign io_out[PIN_CACHEDMEMORY1_CSB] = cachedMemory_en[1] ? cachedMemory_csb[1] : gpio_output[PIN_CACHEDMEMORY1_CSB];
	assign io_oeb[PIN_CACHEDMEMORY1_CSB] = cachedMemory_en[1] ? 1'b0 : gpio_oe[PIN_CACHEDMEMORY1_CSB];

	// IO13-PIN_CACHEDMEMORY1_SCK: Output
	localparam PIN_CACHEDMEMORY1_SCK = 13;
	assign gpio_input[PIN_CACHEDMEMORY1_SCK] = cachedMemory_en[1] ? 1'b0 : (gpio_oe[PIN_CACHEDMEMORY1_SCK] ? io_in[PIN_CACHEDMEMORY1_SCK] : 1'b0);
	assign io_out[PIN_CACHEDMEMORY1_SCK] = cachedMemory_en[1] ? cachedMemory_sck[1] : gpio_output[PIN_CACHEDMEMORY1_SCK];
	assign io_oeb[PIN_CACHEDMEMORY1_SCK] = cachedMemory_en[1] ? 1'b0 : gpio_oe[PIN_CACHEDMEMORY1_SCK];

	// IO14-PIN_CACHEDMEMORY1_IO0: InOut
	localparam PIN_CACHEDMEMORY1_IO0 = 14;
	assign gpio_input[PIN_CACHEDMEMORY1_IO0] = cachedMemory_en[1] ? 1'b0 : (gpio_oe[PIN_CACHEDMEMORY1_IO0] ? io_in[PIN_CACHEDMEMORY1_IO0] : 1'b0);
	assign io_out[PIN_CACHEDMEMORY1_IO0] = cachedMemory_en[1] ? cachedMemory_io0_write[1] : gpio_output[PIN_CACHEDMEMORY1_IO0];
	assign io_oeb[PIN_CACHEDMEMORY1_IO0] = cachedMemory_en[1] ? !cachedMemory_io0_we[1] : gpio_oe[PIN_CACHEDMEMORY1_IO0];
	assign cachedMemory_io0_read[1] = cachedMemory_en[1] && !cachedMemory_io0_we[1] ? io_in[PIN_CACHEDMEMORY1_IO0] : 1'b0;

	// IO15-PIN_CACHEDMEMORY1_IO1: InOut
	localparam PIN_CACHEDMEMORY1_IO1 = 15;
	assign gpio_input[PIN_CACHEDMEMORY1_IO1] = cachedMemory_en[1] ? 1'b0 : (gpio_oe[PIN_CACHEDMEMORY1_IO1] ? io_in[PIN_CACHEDMEMORY1_IO1] : 1'b0);
	assign io_out[PIN_CACHEDMEMORY1_IO1] = cachedMemory_en[1] ? cachedMemory_io1_write[1] : gpio_output[PIN_CACHEDMEMORY1_IO1];
	assign io_oeb[PIN_CACHEDMEMORY1_IO1] = cachedMemory_en[1] ? !cachedMemory_io1_we[1] : gpio_oe[PIN_CACHEDMEMORY1_IO1];
	assign cachedMemory_io1_read[1] = cachedMemory_en[1] && !cachedMemory_io1_we[1] ? io_in[PIN_CACHEDMEMORY1_IO1] : 1'b0;

	// IO16-PIN_PWM0: Output
	localparam PIN_PWM0 = 16;
	assign gpio_input[PIN_PWM0] = pwm_en[0] ? 1'b0 : (gpio_oe[PIN_PWM0] ? io_in[PIN_PWM0] : 1'b0);
	assign io_out[PIN_PWM0] = pwm_en[0] ? pwm_out[0] : gpio_output[PIN_PWM0];
	assign io_oeb[PIN_PWM0] = pwm_en[0] ? 1'b0 : gpio_oe[PIN_PWM0];

	// IO17-PIN_PWM1: Output
	localparam PIN_PWM1 = 17;
	assign gpio_input[PIN_PWM1] = pwm_en[1] ? 1'b0 : (gpio_oe[PIN_PWM1] ? io_in[PIN_PWM1] : 1'b0);
	assign io_out[PIN_PWM1] = pwm_en[1] ? pwm_out[1] : gpio_output[PIN_PWM1];
	assign io_oeb[PIN_PWM1] = pwm_en[1] ? 1'b0 : gpio_oe[PIN_PWM1];

	// IO18-PIN_PWM2: Output
	localparam PIN_PWM2 = 18;
	assign gpio_input[PIN_PWM2] = pwm_en[2] ? 1'b0 : (gpio_oe[PIN_PWM2] ? io_in[PIN_PWM2] : 1'b0);
	assign io_out[PIN_PWM2] = pwm_en[2] ? pwm_out[2] : gpio_output[PIN_PWM2];
	assign io_oeb[PIN_PWM2] = pwm_en[2] ? 1'b0 : gpio_oe[PIN_PWM2];

	// IO19-PIN_PWM3: Output
	localparam PIN_PWM3 = 19;
	assign gpio_input[PIN_PWM3] = pwm_en[3] ? 1'b0 : (gpio_oe[PIN_PWM3] ? io_in[PIN_PWM3] : 1'b0);
	assign io_out[PIN_PWM3] = pwm_en[3] ? pwm_out[3] : gpio_output[PIN_PWM3];
	assign io_oeb[PIN_PWM3] = pwm_en[3] ? 1'b0 : gpio_oe[PIN_PWM3];

	// IO20-PIN_PWM4: Output
	localparam PIN_PWM4 = 20;
	assign gpio_input[PIN_PWM4] = pwm_en[4] ? 1'b0 : (gpio_oe[PIN_PWM4] ? io_in[PIN_PWM4] : 1'b0);
	assign io_out[PIN_PWM4] = pwm_en[4] ? pwm_out[4] : gpio_output[PIN_PWM4];
	assign io_oeb[PIN_PWM4] = pwm_en[4] ? 1'b0 : gpio_oe[PIN_PWM4];

	// IO21-PIN_PWM5: Output
	localparam PIN_PWM5 = 21;
	assign gpio_input[PIN_PWM5] = pwm_en[5] ? 1'b0 : (gpio_oe[PIN_PWM5] ? io_in[PIN_PWM5] : 1'b0);
	assign io_out[PIN_PWM5] = pwm_en[5] ? pwm_out[5] : gpio_output[PIN_PWM5];
	assign io_oeb[PIN_PWM5] = pwm_en[5] ? 1'b0 : gpio_oe[PIN_PWM5];

	// IO22-PIN_SPI0_CLK: Output
	localparam PIN_SPI0_CLK = 22;
	assign gpio_input[PIN_SPI0_CLK] = spi_en[0] ? 1'b0 : (gpio_oe[PIN_SPI0_CLK] ? io_in[PIN_SPI0_CLK] : 1'b0);
	assign io_out[PIN_SPI0_CLK] = spi_en[0] ? spi_clk[0] : gpio_output[PIN_SPI0_CLK];
	assign io_oeb[PIN_SPI0_CLK] = spi_en[0] ? 1'b0 : gpio_oe[PIN_SPI0_CLK];

	// IO23-PIN_SPI0_MOSI: Output
	localparam PIN_SPI0_MOSI = 23;
	assign gpio_input[PIN_SPI0_MOSI] = spi_en[0] ? 1'b0 : (gpio_oe[PIN_SPI0_MOSI] ? io_in[PIN_SPI0_MOSI] : 1'b0);
	assign io_out[PIN_SPI0_MOSI] = spi_en[0] ? spi_mosi[0] : gpio_output[PIN_SPI0_MOSI];
	assign io_oeb[PIN_SPI0_MOSI] = spi_en[0] ? 1'b0 : gpio_oe[PIN_SPI0_MOSI];

	// IO24-PIN_SPI0_MISO: Input
	localparam PIN_SPI0_MISO = 24;
	assign gpio_input[PIN_SPI0_MISO] = spi_en[0] ? 1'b0 : (gpio_oe[PIN_SPI0_MISO] ? io_in[PIN_SPI0_MISO] : 1'b0);
	assign io_out[PIN_SPI0_MISO] = spi_en[0] ? 1'b0 : gpio_output[PIN_SPI0_MISO];
	assign io_oeb[PIN_SPI0_MISO] = spi_en[0] ? 1'b1 : gpio_oe[PIN_SPI0_MISO];
	assign spi_miso[0] = spi_en[0] ? io_in[PIN_SPI0_MISO] : 1'b0;

	// IO25-PIN_SPI0_CS: Output
	localparam PIN_SPI0_CS = 25;
	assign gpio_input[PIN_SPI0_CS] = spi_en[0] ? 1'b0 : (gpio_oe[PIN_SPI0_CS] ? io_in[PIN_SPI0_CS] : 1'b0);
	assign io_out[PIN_SPI0_CS] = spi_en[0] ? spi_cs[0] : gpio_output[PIN_SPI0_CS];
	assign io_oeb[PIN_SPI0_CS] = spi_en[0] ? 1'b0 : gpio_oe[PIN_SPI0_CS];

	// IO26-PIN_PWM6: Output
	localparam PIN_PWM6 = 26;
	assign gpio_input[PIN_PWM6] = pwm_en[6] ? 1'b0 : (gpio_oe[PIN_PWM6] ? io_in[PIN_PWM6] : 1'b0);
	assign io_out[PIN_PWM6] = pwm_en[6] ? pwm_out[6] : gpio_output[PIN_PWM6];
	assign io_oeb[PIN_PWM6] = pwm_en[6] ? 1'b0 : gpio_oe[PIN_PWM6];

	// IO27-PIN_PWM7: Output
	localparam PIN_PWM7 = 27;
	assign gpio_input[PIN_PWM7] = pwm_en[7] ? 1'b0 : (gpio_oe[PIN_PWM7] ? io_in[PIN_PWM7] : 1'b0);
	assign io_out[PIN_PWM7] = pwm_en[7] ? pwm_out[7] : gpio_output[PIN_PWM7];
	assign io_oeb[PIN_PWM7] = pwm_en[7] ? 1'b0 : gpio_oe[PIN_PWM7];

	// IO28-PIN_BLINK0: Output
	localparam PIN_BLINK0 = 28;
	assign gpio_input[PIN_BLINK0] = blinkEnabled ? 1'b0 : (gpio_oe[PIN_BLINK0] ? io_in[PIN_BLINK0] : 1'b0);
	assign io_out[PIN_BLINK0] = blinkEnabled ? blink[0] : gpio_output[PIN_BLINK0];
	assign io_oeb[PIN_BLINK0] = blinkEnabled ? 1'b0 : gpio_oe[PIN_BLINK0];

	// IO29-PIN_BLINK1: Output
	localparam PIN_BLINK1 = 29;
	assign gpio_input[PIN_BLINK1] = blinkEnabled ? 1'b0 : (gpio_oe[PIN_BLINK1] ? io_in[PIN_BLINK1] : 1'b0);
	assign io_out[PIN_BLINK1] = blinkEnabled ? blink[1] : gpio_output[PIN_BLINK1];
	assign io_oeb[PIN_BLINK1] = blinkEnabled ? 1'b0 : gpio_oe[PIN_BLINK1];

	// IO30-PIN_VGA_R0: Output
	localparam PIN_VGA_R0 = 30;
	assign gpio_input[PIN_VGA_R0] = 1'b0;
	assign io_out[PIN_VGA_R0] = vga_r[0];
	assign io_oeb[PIN_VGA_R0] = 1'b0;

	// IO31-PIN_VGA_R1: Output
	localparam PIN_VGA_R1 = 31;
	assign gpio_input[PIN_VGA_R1] = 1'b0;
	assign io_out[PIN_VGA_R1] = vga_r[1];
	assign io_oeb[PIN_VGA_R1] = 1'b0;

	// IO32-PIN_VGA_G0: Output
	localparam PIN_VGA_G0 = 32;
	assign gpio_input[PIN_VGA_G0] = 1'b0;
	assign io_out[PIN_VGA_G0] = vga_g[0];
	assign io_oeb[PIN_VGA_G0] = 1'b0;

	// IO33-PIN_VGA_G1: Output
	localparam PIN_VGA_G1 = 33;
	assign gpio_input[PIN_VGA_G1] = 1'b0;
	assign io_out[PIN_VGA_G1] = vga_g[1];
	assign io_oeb[PIN_VGA_G1] = 1'b0;

	// IO34-PIN_VGA_B0: Output
	localparam PIN_VGA_B0 = 34;
	assign gpio_input[PIN_VGA_B0] = 1'b0;
	assign io_out[PIN_VGA_B0] = vga_b[0];
	assign io_oeb[PIN_VGA_B0] = 1'b0;

	// IO35-PIN_VGA_B1: Output
	localparam PIN_VGA_B1 = 35;
	assign gpio_input[PIN_VGA_B1] = 1'b0;
	assign io_out[PIN_VGA_B1] = vga_b[1];
	assign io_oeb[PIN_VGA_B1] = 1'b0;

	// IO36-PIN_VGA_VSYNC: Output
	localparam PIN_VGA_VSYNC = 36;
	assign gpio_input[PIN_VGA_VSYNC] = 1'b0;
	assign io_out[PIN_VGA_VSYNC] = vga_vsync;
	assign io_oeb[PIN_VGA_VSYNC] = 1'b0;

	// IO37-PIN_VGA_HSYNC: Output
	localparam PIN_VGA_HSYNC = 37;
	assign gpio_input[PIN_VGA_HSYNC] = 1'b0;
	assign io_out[PIN_VGA_HSYNC] = vga_hsync;
	assign io_oeb[PIN_VGA_HSYNC] = 1'b0;

	//--------------End of Generated Code--------------//
	//-----------------Pin Mapping End-----------------//
	//-------------------------------------------------//

endmodule
