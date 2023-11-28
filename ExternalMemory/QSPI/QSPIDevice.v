`default_nettype none

`ifndef QSPIDevice_V
`define QSPIDevice_V

`include "../../Utility/ShiftRegister.v"

module QSPIDevice (
		input wire clk,
		input wire rst,

		// Configuration
		input wire[3:0] clockScale,

		// Cache interface
		input wire qspi_enable,
		input wire qspi_interruptOperation,
		input wire[23:0] qspi_address,
		input wire qspi_changeAddress,
		input wire qspi_requestData,
		input wire qspi_storeData,
		input wire[31:0] qspi_writeData,
		output reg[31:0] qspi_readData,
		output reg qspi_wordComplete,
		output reg qspi_initialised,
		output reg qspi_busy,

		// QSPI interface
		output wire device_csb,
		output reg device_sck,
		output wire device_io0_we,
		output wire device_io0_write,
		input wire device_io0_read, 	// Unused
		output wire device_io1_we,
		output wire device_io1_write,  // Unused (constant 1'b0)
		input wire device_io1_read
	);

	localparam STATE_IDLE = 2'h0;
	localparam STATE_SETUP = 2'h1;
	localparam STATE_SHIFT = 2'h2;
	localparam STATE_END = 2'h3;

	localparam RESET_NONE = 2'h0;
	localparam RESET_START = 2'h1;
	localparam RESET_WAKE = 2'h2;

	// Assign these as constants to be in a default spi mode
	assign device_io0_we = 1'b1;
	assign device_io1_we = 1'b0;
	assign device_io1_write = 1'b0;
	wire _unused_device_io0_read = device_io0_read;

	// State control
	reg[1:0] state = STATE_IDLE;
	wire deviceBusy = state != STATE_IDLE;
	reg[1:0] resetState = RESET_NONE;
	wire resetDevice = resetState != RESET_NONE;
	reg settingAddress = 1'b0;
	reg[3:0] clockCounter;

	reg outputClock = 1'b0;
	reg[4:0] bitCounter = 5'b0;
	wire[4:0] nextBitCounter = bitCounter + 1;

	wire shiftInEnable  = outputClock && deviceBusy && clockCounter == clockScale;
	wire shiftOutEnable = !outputClock && deviceBusy && clockCounter == clockScale;

	reg[31:0] registerLoadData;
	wire serialOut;
	wire[31:0] readData;
	ShiftRegister #(.WIDTH(32)) register (
		.clk(clk),
		.rst(rst),
		.loadEnable((!deviceBusy && qspi_changeAddress) || ((state == STATE_SETUP) && resetDevice)),
		.shiftInEnable(shiftInEnable),
		.shiftOutEnable(shiftOutEnable),
		.msbFirst(1'b1),
		.parallelIn(registerLoadData),
		.parallelOut(readData),
		.serialIn(device_io1_read),
		.serialOut(serialOut));

	always @(*) begin
		case (1'b1)
			resetState == RESET_START: registerLoadData = { 8'hFF, 8'h00, 8'h00, 8'h00 };
			resetState == RESET_WAKE: registerLoadData = { 8'hAB, 8'h00, 8'h00, 8'h00 };
			qspi_changeAddress: registerLoadData = { qspi_storeData ? 8'h02 : 8'h03, qspi_address };
			qspi_storeData && !qspi_changeAddress && !settingAddress: registerLoadData = qspi_writeData;
			default: registerLoadData = 32'b0;
		endcase
	end

	always @(posedge clk) begin
		if (rst) begin
			clockCounter <= 4'b0;
		end else begin
			if (qspi_enable) begin
				if (clockCounter == 4'h0 || qspi_interruptOperation) begin
					clockCounter <= clockScale;
				end else begin
					clockCounter <= clockCounter - 1;
				end
			end else begin
				clockCounter <= clockScale;
			end
		end
	end

	always @(posedge clk) begin
		if (rst) begin
			state <= STATE_IDLE;
			outputClock <= 1'b0;
			bitCounter <= 5'b0;
			resetState <= RESET_START;
			settingAddress <= 1'b0;
			qspi_wordComplete <= 1'b0;
			qspi_initialised <= 1'b0;
			qspi_busy <= 1'b0;
		end else begin
			if (qspi_interruptOperation) begin
				state <= STATE_IDLE;
				bitCounter <= 5'b0;
				outputClock <= 1'b0;
				qspi_wordComplete <= 1'b0;
				qspi_busy <= 1'b0;
			end else begin
				case (state)
					STATE_IDLE: begin
						outputClock <= 1'b0;
						bitCounter <= 5'b0;

						if (qspi_enable) begin
							if (resetDevice || qspi_changeAddress) begin
								state <= STATE_SETUP;
								settingAddress <= qspi_changeAddress;
								qspi_busy <= 1'b1;
							end
						end
					end

					STATE_SETUP: begin
						if (clockCounter == 4'h0) state <= STATE_SHIFT;
						bitCounter <= 5'b0;
						outputClock <= 1'b1;
						qspi_wordComplete <= 1'b0;
						qspi_busy <= 1'b1;
					end

					STATE_SHIFT: begin
						if (clockCounter == 4'h0) begin
							if (!outputClock) begin
								if ((resetDevice && bitCounter == 5'h07) || (bitCounter == 5'h1F)) begin
									state <= STATE_END;
									qspi_wordComplete <= !settingAddress;
									qspi_readData <= { readData[7:0], readData[15:8], readData[23:16], readData[31:24] };
								end	else begin
									bitCounter <= nextBitCounter;
									outputClock <= 1'b1;
								end
							end else begin
								outputClock <= 1'b0;
							end
						end

						if (qspi_changeAddress) begin
							state <= STATE_IDLE;
							qspi_busy <= 1'b0;
						end
					end

					STATE_END: begin
						if (qspi_requestData || qspi_storeData) begin
							state <= STATE_SETUP;
							qspi_busy <= 1'b1;
						end else begin
							state <= STATE_IDLE;
							qspi_busy <= 1'b0;
						end

						outputClock <= 1'b0;
						settingAddress <= 1'b0;
						qspi_wordComplete <= 1'b0;

						if (resetState == RESET_START) begin
							resetState <= RESET_WAKE;
						end else begin
							resetState <= RESET_NONE;
							qspi_initialised <= 1'b1;
						end
					end

					default: begin
						state <= STATE_IDLE;
						outputClock <= 1'b0;
						bitCounter <= 5'b0;
						resetState <= RESET_START;
						settingAddress <= 1'b0;
						qspi_wordComplete <= 1'b0;
						qspi_initialised <= 1'b0;
						qspi_busy <= 1'b0;
					end
				endcase
			end
		end
	end

	// Buffer the spi clock by one cycle so that it lines up with when data is sampled
	always @(posedge clk) begin
		if (rst) device_sck <= 1'b0;
		else if (clockCounter == 4'b0) device_sck <= outputClock;
	end

	assign device_io0_write = serialOut & deviceBusy;
	assign device_csb = !deviceBusy;

endmodule

`endif
