`default_nettype none

module LocalMemoryInterface_RW #(
		parameter ADDRESS_SIZE = 24,
		parameter SRAM_ADDRESS_SIZE = 9
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

		// SRAM primary RW port
		output wire sram_primarySelect,
		output wire sram_primaryWriteEnable,
		output wire[SRAM_ADDRESS_SIZE-1:0] sram_primaryAddress,
		output reg[3:0] sram_primaryWriteMask,
		output reg[31:0] sram_primaryDataWrite,
		input wire[31:0] sram_primaryDataRead
	);

	localparam PRIMARY = 1'b0;
	localparam SECONDARY = 1'b1;

	// Primary enable pins
	wire primarySRAMEnable;
	wire primarySRAMWriteEnable = primarySRAMEnable && primaryWriteEnable && ~|primaryAddress[1:0];
	// wire primarySRAMReadEnable = primarySRAMEnable && !primaryWriteEnable && ~|primaryAddress[1:0];

	// Secondary enable pins
	wire secondarySRAMEnable;
	wire secondarySRAMWriteEnable = secondarySRAMEnable && secondaryWriteEnable && ~|secondaryAddress[1:0];
	// wire secondarySRAMReadEnable = secondarySRAMEnable && !secondaryWriteEnable && ~|secondaryAddress[1:0];

	generate
		if (ADDRESS_SIZE <= SRAM_ADDRESS_SIZE+2) begin
			assign primarySRAMEnable = primaryEnable;
			assign secondarySRAMEnable = secondaryEnable;
		end else begin
			assign primarySRAMEnable = primaryAddress[ADDRESS_SIZE-1:SRAM_ADDRESS_SIZE+2] == 'b0 && primaryEnable;
			assign secondarySRAMEnable = secondaryAddress[ADDRESS_SIZE-1:SRAM_ADDRESS_SIZE+2] == 'b0 && secondaryEnable;
		end
	endgenerate

	// Generate SRAM control signals
	wire[31:0] rwPortReadData;

	// Action complete control
	wire rwActionDone;
	reg primaryActionDone = 1'b0;
	reg[3:0] lastPrimaryByteSelect = 4'b0;
	always @(posedge clk) begin
		if (rst) begin
			primaryActionDone <= 1'b0;
			lastPrimaryByteSelect <= 4'b0;
		end	else if (rwActionDone && (wrController == PRIMARY)) begin
			primaryActionDone <= 1'b1;
			lastPrimaryByteSelect <= primaryByteSelect;
		end else begin
			primaryActionDone <= 1'b0;
		end
	end

	reg secondaryActionDone = 1'b0;
	reg[3:0] lastSecondaryByteSelect = 4'b0;
	always @(posedge clk) begin
		if (rst) begin
			secondaryActionDone <= 1'b0;
			lastSecondaryByteSelect <= 4'b0;
		end else if (rwActionDone && (wrController == SECONDARY)) begin
			secondaryActionDone <= 1'b1;
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
				if (primarySRAMEnable) begin
					wrController <= PRIMARY;
				end else if (secondarySRAMEnable) begin
					wrController <= SECONDARY;
				end
			end
		end
	end

	// Busy signals
	assign primaryBusy = primarySRAMEnable && (wrController != PRIMARY || !primaryActionDone);
	assign secondaryBusy = secondarySRAMEnable && (wrController != SECONDARY || !secondaryActionDone);

	// Read/Write port
	wire rwPortEnable = wrController ? secondarySRAMEnable : primarySRAMEnable;
	reg rwWriteEnable;
	reg[SRAM_ADDRESS_SIZE-1:0] rwAddress;
	always @(*) begin
		if (rst) begin
			rwWriteEnable = 1'b0;
			rwAddress = 'b0;
		end else begin
			case (wrController)
			PRIMARY: begin
				rwWriteEnable = primarySRAMWriteEnable;
				rwAddress = primaryAddress[SRAM_ADDRESS_SIZE+1:2];
			end

			SECONDARY: begin
				rwWriteEnable = secondarySRAMWriteEnable;
				rwAddress = secondaryAddress[SRAM_ADDRESS_SIZE+1:2];
			end
			endcase
		end
	end

	assign primaryDataRead = {
		lastPrimaryByteSelect[3] && primaryActionDone ? rwPortReadData[31:24] : ~8'h00,
		lastPrimaryByteSelect[2] && primaryActionDone ? rwPortReadData[23:16] : ~8'h00,
		lastPrimaryByteSelect[1] && primaryActionDone ? rwPortReadData[15:8]  : ~8'h00,
		lastPrimaryByteSelect[0] && primaryActionDone ? rwPortReadData[7:0]   : ~8'h00
	};

	assign secondaryDataRead = {
		lastSecondaryByteSelect[3] && secondaryActionDone ? rwPortReadData[31:24] : ~8'h00,
		lastSecondaryByteSelect[2] && secondaryActionDone ? rwPortReadData[23:16] : ~8'h00,
		lastSecondaryByteSelect[1] && secondaryActionDone ? rwPortReadData[15:8]  : ~8'h00,
		lastSecondaryByteSelect[0] && secondaryActionDone ? rwPortReadData[7:0]   : ~8'h00
	};

	// Shared write signals
	always @(*) begin
		if (rst) begin
			sram_primaryWriteMask = 4'b0;
			sram_primaryDataWrite = 32'b0;
		end else begin
			if (wrController == PRIMARY) begin
				sram_primaryWriteMask = primaryByteSelect;
				sram_primaryDataWrite = primaryDataWrite;
			end else if (wrController == SECONDARY) begin
				sram_primaryWriteMask = secondaryByteSelect;
				sram_primaryDataWrite = secondaryDataWrite;
			end else begin
				sram_primaryWriteMask = 4'b0;
				sram_primaryDataWrite = 32'b0;
			end
		end
	end

	// SRAM primary control signals
	assign sram_primarySelect = rwPortEnable;
	assign sram_primaryWriteEnable = rwWriteEnable;
	assign sram_primaryAddress = rwAddress;

	// SRAM primary read data
	assign rwActionDone = rwPortEnable;
	assign rwPortReadData = sram_primaryDataRead;

endmodule
