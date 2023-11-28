`default_nettype none

module Core_WBInterface #(
		parameter ADDRESS_WIDTH = 28
	)(
		// Wishbone master interface
		input wire wb_clk_i,
		input wire wb_rst_i,
		output wire wb_cyc_o,
		output wire wb_stb_o,
		output wire wb_we_o,
		output reg[3:0] wb_sel_o,
		output reg[31:0] wb_data_o,
		output reg[ADDRESS_WIDTH-1:0] wb_adr_o,
		input wire wb_ack_i,
		input wire wb_stall_i,
		input wire wb_error_i,
		input wire[31:0] wb_data_i,

		// Memory interface from core
		input wire[ADDRESS_WIDTH-1:0] wbAddress,
		input wire[3:0] wbByteSelect,
		input wire wbEnable,
		input wire wbWriteEnable,
		input wire[31:0] wbDataWrite,
		output wire[31:0] wbDataRead,
		output reg wbBusy
	);

	localparam STATE_IDLE  		  = 2'h0;
	localparam STATE_WRITE_SINGLE = 2'h1;
	localparam STATE_READ_SINGLE  = 2'h2;
	
	reg[1:0] state = STATE_IDLE;
	reg[31:0] readDataBuffered;

	reg stb = 1'b0;

	always @(posedge wb_clk_i) begin
		if (wb_rst_i || (wb_error_i && state != STATE_IDLE)) begin
			state = STATE_IDLE;
			stb = 1'b0;
			readDataBuffered = ~32'b0;
			wb_sel_o = 4'b0;
			wb_adr_o = 0;
			wb_data_o = ~32'b0;
			wbBusy = 1'b0;
		end else begin
			case (state)
				STATE_IDLE: begin
					readDataBuffered = ~32'b0;
					wbBusy = 1'b1;

					if (wbEnable) begin
						if (wbWriteEnable) begin
							state = STATE_WRITE_SINGLE;
							stb = 1'b1;
							wb_data_o = wbDataWrite;
						end else begin
							state = STATE_READ_SINGLE;
							stb = 1'b1;
							wb_data_o = ~32'b0;
						end

						wb_sel_o = wbByteSelect;
						wb_adr_o = wbAddress;
					end
				end

				STATE_WRITE_SINGLE: begin
					stb = 1'b0;
					if (wbEnable) begin
						if (wb_ack_i) begin
							state = STATE_IDLE;
							wbBusy = 1'b0;
						end
					end else begin
						state = STATE_IDLE;
					end
				end

				STATE_READ_SINGLE: begin
					stb = 1'b0;
					if (wbEnable) begin
						if (wb_ack_i) begin
							state = STATE_IDLE;
							readDataBuffered = wb_data_i;
							wbBusy = 1'b0;
						end
					end else begin
						state = STATE_IDLE;
					end
				end

				default: begin
					state = STATE_IDLE;
					stb = 1'b0;
					wbBusy = 1'b1;
				end
			endcase
		end
	end

	assign wb_cyc_o = state != STATE_IDLE && wbEnable;
	assign wb_stb_o = wb_cyc_o;

	assign wb_we_o = state == STATE_WRITE_SINGLE;
		
	assign wbDataRead = readDataBuffered;
	//assign wbBusy = wb_cyc_o;

endmodule
