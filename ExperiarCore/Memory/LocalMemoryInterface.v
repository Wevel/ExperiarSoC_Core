`default_nettype none

module LocalMemoryInterface #(
		parameter ADDRESS_SIZE = 24,
		parameter SRAM_ADDRESS_SIZE = 9,
		parameter BLOCK_ADDRESS_SIZE = 1
	)(
		input wire clk,
		input wire rst,

		// Primary interface
		input wire[ADDRESS_SIZE-1:0] primaryAddress,
		input wire[3:0] primaryByteSelect,
		input wire primaryEnable,
		input wire primaryWriteEnable,
		input wire[31:0] primaryDataWrite,
		output wire[31:0] primaryDataRead,
		output wire primaryBusy,

		// Secondary interface
		input wire[ADDRESS_SIZE-1:0] secondaryAddress,
		input wire[3:0] secondaryByteSelect,
		input wire secondaryEnable,
		input wire secondaryWriteEnable,
		input wire[31:0] secondaryDataWrite,
		output wire[31:0] secondaryDataRead,
		output wire secondaryBusy,

		// SRAM rw port
		output wire clk0, // Port clock
		output reg[BLOCK_COUNT-1:0] csb0, // active low chip select
		output reg web0, // active low write control
		output reg[3:0] wmask0, // write mask
		output reg[SRAM_ADDRESS_SIZE-1:0] addr0,
		output reg[31:0] din0,
		input  wire[(32*BLOCK_COUNT)-1:0] dout0,

		// SRAM r port
		output wire clk1,
		output reg[BLOCK_COUNT-1:0] csb1,
		output wire[SRAM_ADDRESS_SIZE-1:0] addr1,
		input  wire[(32*BLOCK_COUNT)-1:0] dout1

		// Primary RW port
		output wire primarySelect,
		output wire primaryWriteEnable,
		output wire[BYTE_COUNT-1:0] primaryWriteMask,
		output wire[ADDRESS_SIZE-1:0] primaryAddress,
		output wire[WORD_SIZE-1:0] primaryDataIn,
		input wire[WORD_SIZE-1:0] primaryDataOut

		// Secondary R port
		output wire secondarySelect,
		output wire[ADDRESS_SIZE-1:0] secondaryAddress,
		input wire[WORD_SIZE-1:0] secondaryDataOut
	);

	localparam BLOCK_COUNT = (1 << BLOCK_ADDRESS_SIZE);
	localparam PRIMARY = 1'b0;
	localparam SECONDARY = 1'b1;

	// Primary enable pins
	wire primarySRAMEnable;
	wire primarySRAMWriteEnable = primarySRAMEnable && primaryWriteEnable;
	wire primarySRAMReadEnable = primarySRAMEnable && !primaryWriteEnable;

	// Secondary enable pins
	wire secondarySRAMEnable;
	wire secondarySRAMWriteEnable = secondarySRAMEnable && secondaryWriteEnable;
	wire secondarySRAMReadEnable = secondarySRAMEnable && !secondaryWriteEnable;

	generate
		if (ADDRESS_SIZE <= SRAM_ADDRESS_SIZE+BLOCK_ADDRESS_SIZE+2) begin
			assign primarySRAMEnable = primaryEnable;
			assign secondarySRAMEnable = secondaryEnable;
		end else begin
			assign primarySRAMEnable = primaryAddress[ADDRESS_SIZE-1:SRAM_ADDRESS_SIZE+BLOCK_ADDRESS_SIZE+2] == 'b0 && primaryEnable;
			assign secondarySRAMEnable = secondaryAddress[ADDRESS_SIZE-1:SRAM_ADDRESS_SIZE+BLOCK_ADDRESS_SIZE+2] == 'b0 && secondaryEnable;
		end 
	endgenerate

	// Generate SRAM control signals
	// Primary can always read from read only port
	// Primary can always write to read/write port
	// Wishbone can read/write to read/write port, but only if primary is not writing to it
	wire[31:0] rwPortReadData;
	wire[31:0] rPortReadData;

	wire[BLOCK_COUNT-1:0] rBankSelect;
	wire[BLOCK_COUNT-1:0] rwBankSelect;

	// Action complete control
	reg rActionDone;
	reg rwActionDone;
	reg primaryActionDone = 1'b0;
	reg[BLOCK_ADDRESS_SIZE-1:0] lastRBankSelectAddress = 'b0;
	reg[3:0] lastPrimaryByteSelect = 4'b0;
	always @(posedge clk) begin
		if (rst) begin
			primaryActionDone <= 1'b0;
			lastRBankSelectAddress = 'b0;
			lastPrimaryByteSelect = 4'b0;
		end	else if (rActionDone) begin
			primaryActionDone <= 1'b1;
			lastRBankSelectAddress <= rAddress[SRAM_ADDRESS_SIZE];
			lastPrimaryByteSelect <= primaryByteSelect;
		end	else if (rwActionDone && (wrController == PRIMARY)) begin
			primaryActionDone <= 1'b1;
			lastRBankSelectAddress <= rAddress[SRAM_ADDRESS_SIZE];
			lastPrimaryByteSelect <= primaryByteSelect;
		end else begin 
			primaryActionDone <= 1'b0;
		end
	end

	reg secondaryActionDone = 1'b0;
	reg[BLOCK_ADDRESS_SIZE-1:0] lastRWBankSelectAddress = 'b0;
	reg[3:0] lastSecondaryByteSelect = 4'b0;
	always @(posedge clk) begin
		if (rst) begin 
			secondaryActionDone <= 1'b0;
			lastRWBankSelectAddress <= 'b0;
			lastSecondaryByteSelect <= 4'b0;
		end else if (rwActionDone && (wrController == SECONDARY)) begin
			secondaryActionDone <= 1'b1;
			lastRWBankSelectAddress <= rwAddress[SRAM_ADDRESS_SIZE];
			lastSecondaryByteSelect <= secondaryByteSelect;	
		end else if (secondaryActionDone) begin
			secondaryActionDone <= 1'b0;
		end
	end

	// WR controller select
	reg wrController = 1'b0;
	always @(negedge clk) begin
		if (rst) begin
			wrController <= 1'b0;
		end else begin
			if (rwActionDone || !rwPortEnable) begin
				if (primarySRAMWriteEnable) begin
					wrController <= PRIMARY;
				end else if (secondarySRAMEnable) begin
					wrController <= SECONDARY;
				end
			end
		end
	end

	// Busy signals
	assign primaryBusy = primarySRAMWriteEnable && (wrController != PRIMARY || !primaryActionDone);
	assign secondaryBusy = secondarySRAMEnable && (wrController != SECONDARY || !secondaryActionDone);

	// Read/Write port
	wire rwPortEnable = wrController ? secondarySRAMEnable : primarySRAMWriteEnable;
	reg rwWriteEnable;
	reg[SRAM_ADDRESS_SIZE:0] rwAddress;	
	always @(*) begin
		if (rst) begin
			rwWriteEnable <= 1'b0;
			rwAddress <= 'b0;
		end else begin
			case (wrController)
			PRIMARY: begin
				rwWriteEnable <= primarySRAMWriteEnable;
				rwAddress <= primaryAddress[SRAM_ADDRESS_SIZE+BLOCK_ADDRESS_SIZE+1:2];
			end

			SECONDARY: begin
				rwWriteEnable <= secondarySRAMWriteEnable;
				rwAddress <= secondaryAddress[SRAM_ADDRESS_SIZE+BLOCK_ADDRESS_SIZE+1:2];
			end
			endcase
		end
	end

	assign secondaryDataRead = {
		lastSecondaryByteSelect[3] && secondaryActionDone ? rwPortReadData[31:24] : ~8'h00,
		lastSecondaryByteSelect[2] && secondaryActionDone ? rwPortReadData[23:16] : ~8'h00,
		lastSecondaryByteSelect[1] && secondaryActionDone ? rwPortReadData[15:8]  : ~8'h00,
		lastSecondaryByteSelect[0] && secondaryActionDone ? rwPortReadData[7:0]   : ~8'h00
	};

	// Read port
	wire rPortEnable = primarySRAMReadEnable && !primaryActionDone;
	wire[SRAM_ADDRESS_SIZE:0] rAddress = primaryAddress[SRAM_ADDRESS_SIZE+BLOCK_ADDRESS_SIZE+1:2];
	
	assign primaryDataRead = {
		lastPrimaryByteSelect[3] && primaryActionDone ? rPortReadData[31:24] : ~8'h00,
		lastPrimaryByteSelect[2] && primaryActionDone ? rPortReadData[23:16] : ~8'h00,
		lastPrimaryByteSelect[1] && primaryActionDone ? rPortReadData[15:8]  : ~8'h00,
		lastPrimaryByteSelect[0] && primaryActionDone ? rPortReadData[7:0]   : ~8'h00
	};

	// SRAM connections
	assign clk0 = clk;

	wire[BLOCK_COUNT-1:0] csb0Value;
	wire[BLOCK_COUNT-1:0] csb1Value;

	generate
		if (BLOCK_COUNT == 1) begin
			assign rBankSelect = 1'b1;
			assign rwBankSelect = 1'b1;
			assign csb0Value = !rwPortEnable;
			assign csb1Value = !rPortEnable;
		end else if (BLOCK_COUNT == 2) begin
			assign rBankSelect = 1 << rAddress[SRAM_ADDRESS_SIZE];
			assign rwBankSelect = 1 << rwAddress[SRAM_ADDRESS_SIZE];
			assign csb0Value = ~(rwPortEnable && rwBankSelect);
			assign csb1Value = ~(rPortEnable && rBankSelect);
		end
	endgenerate

	always @(*) begin
		if (rst) begin
			csb0 <= ~'b0;
			csb1 <= ~'b0;
			web0 <= 1'b1;
			addr0 <= 'b0;
			wmask0 <= 4'b0;
			din0 <= 32'b0;
		end else begin
			csb0 <= csb0Value;
			csb1 <= csb1Value;

			rActionDone <= rPortEnable;
			rwActionDone <= rwPortEnable;

			web0 <= !rwWriteEnable;
			addr0 <= rwAddress[SRAM_ADDRESS_SIZE-1:0];
			
			if (wrController == PRIMARY) begin
				wmask0 <= primaryByteSelect;
				din0 <= primaryDataWrite;
			end else if (wrController == SECONDARY) begin
				wmask0 <= secondaryByteSelect;
				din0 <= secondaryDataWrite;
			end else begin
				wmask0 <= 4'b0;
				din0 <= 32'b0;
			end
		end
	end
	

	assign clk1 = clk;
	assign addr1 = rAddress[SRAM_ADDRESS_SIZE-1:0];

	generate
		if (BLOCK_COUNT == 1) begin
			assign rwPortReadData = dout0;
			assign rPortReadData = dout1;
		end else if (BLOCK_COUNT == 2) begin
			assign rwPortReadData = lastRWBankSelectAddress ? dout0[63:32] : dout0[31:0];
			assign rPortReadData = lastRBankSelectAddress ? dout1[63:32] : dout1[31:0];
		end
	endgenerate

endmodule