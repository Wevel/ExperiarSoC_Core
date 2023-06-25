`default_nettype none

module MemoryController (
		input wire clk,
		input wire rst,

		// Instruction cache interface
		input wire[31:0] coreInstructionAddress,
		input wire coreInstructionEnable,
		output reg[31:0] coreInstructionDataRead,
		output reg coreInstructionBusy,

		// Data cache interface
		input wire[31:0] coreDataAddress,
		input wire[3:0] coreDataByteSelect,
		input wire coreDataEnable,
		input wire coreDataWriteEnable,
		input wire[31:0] coreDataDataWrite,
		output reg[31:0] coreDataDataRead,
		output reg coreDataBusy,

		// Local memory interface
		output reg[23:0] localMemoryAddress,
		output reg[3:0] localMemoryByteSelect,
		output reg localMemoryEnable,
		output reg localMemoryWriteEnable,
		output reg[31:0] localMemoryDataWrite,
		input wire[31:0] localMemoryDataRead,
		input wire localMemoryBusy,

		// WB interface
		output reg[27:0] wbAddress,
		output reg[3:0] wbByteSelect,
		output reg wbEnable,
		output reg wbWriteEnable,
		output reg[31:0] wbDataWrite,
		input wire[31:0] wbDataRead,
		input wire wbBusy
	);
	
	localparam LOCAL_MEMORY_ADDRESS = 4'b0000;
	localparam WB_ADDRESS 		    = 4'b0001;

	localparam SOURCE_NONE 		  = 2'h0;
	localparam SOURCE_INSTRUCTION = 2'h1;
	localparam SOURCE_DATA 		  = 2'h2;

	wire instruction_enableLocalMemoryRequest	= coreInstructionEnable && (coreInstructionAddress[31:24] == { LOCAL_MEMORY_ADDRESS, 4'b0000 });
	wire data_enableLocalMemoryRequest			= coreDataEnable 		&& (	   coreDataAddress[31:24] == { LOCAL_MEMORY_ADDRESS, 4'b0000 });
	wire instruction_enableWBRequest 			= coreInstructionEnable && (coreInstructionAddress[31:28] == WB_ADDRESS);
	wire data_enableWBRequest 					= coreDataEnable 		&& (	   coreDataAddress[31:28] == WB_ADDRESS);

	reg[1:0] localMemory_source = SOURCE_NONE;
	always @(posedge clk) begin
		if (rst) begin
			localMemory_source <= SOURCE_NONE;
		end else begin
			case (localMemory_source)
				SOURCE_NONE: begin
					if (instruction_enableLocalMemoryRequest) localMemory_source <= SOURCE_INSTRUCTION;
					else if (data_enableLocalMemoryRequest) localMemory_source <= SOURCE_DATA;
				end

				SOURCE_INSTRUCTION: begin
					if (!instruction_enableLocalMemoryRequest) begin
						if (data_enableLocalMemoryRequest) localMemory_source <= SOURCE_DATA;
						else localMemory_source <= SOURCE_NONE;
					end
				end

				SOURCE_DATA: begin
					if (!data_enableLocalMemoryRequest) begin
						if (instruction_enableLocalMemoryRequest) localMemory_source <= SOURCE_INSTRUCTION;
						else localMemory_source <= SOURCE_NONE;
					end
				end

				default: begin
					localMemory_source <= SOURCE_NONE;
				end
			endcase
		end		
	end

	reg[1:0] wb_source = SOURCE_NONE;
	always @(posedge clk) begin
		if (rst) begin
			wb_source <= SOURCE_NONE;
		end else begin
			case (wb_source)
				SOURCE_NONE: begin
					if (instruction_enableWBRequest) wb_source <= SOURCE_INSTRUCTION;
					else if (data_enableWBRequest) wb_source <= SOURCE_DATA;
				end

				SOURCE_INSTRUCTION: begin
					if (!instruction_enableWBRequest) begin
						if (data_enableWBRequest) wb_source <= SOURCE_DATA;
						else wb_source <= SOURCE_NONE;
					end
				end

				SOURCE_DATA: begin
					if (!data_enableWBRequest) begin
						if (instruction_enableWBRequest) wb_source <= SOURCE_INSTRUCTION;
						else wb_source <= SOURCE_NONE;
					end
				end

				default: begin
					wb_source <= SOURCE_NONE;
				end
			endcase
		end		
	end

	always @(*) begin
		case (localMemory_source)
			SOURCE_INSTRUCTION: begin
				localMemoryAddress <= coreInstructionAddress[23:0];
				localMemoryByteSelect <= 4'b1111;
				localMemoryEnable <= coreInstructionEnable;
				localMemoryWriteEnable <= 1'b0;
				localMemoryDataWrite <= 32'b0;
			end

			SOURCE_DATA: begin
				localMemoryAddress 	   <= coreDataAddress[23:0];
				localMemoryByteSelect  <= coreDataByteSelect;
				localMemoryEnable  	   <= coreDataEnable;
				localMemoryWriteEnable <= coreDataWriteEnable;
				localMemoryDataWrite   <= coreDataDataWrite;
			end

			default: begin
				if (instruction_enableLocalMemoryRequest) begin
					localMemoryAddress <= coreInstructionAddress[23:0];
					localMemoryByteSelect <= 4'b1111;
					localMemoryEnable <= coreInstructionEnable;
					localMemoryWriteEnable <= 1'b0;
					localMemoryDataWrite <= 32'b0;
				end else if (data_enableLocalMemoryRequest) begin
					localMemoryAddress 	   <= coreDataAddress[23:0];
					localMemoryByteSelect  <= coreDataByteSelect;
					localMemoryEnable  	   <= coreDataEnable;
					localMemoryWriteEnable <= coreDataWriteEnable;
					localMemoryDataWrite   <= coreDataDataWrite;
				end else begin
					localMemoryAddress 	   <= 24'b0;
					localMemoryByteSelect  <=  4'b0;
					localMemoryEnable  	   <=  1'b0;
					localMemoryWriteEnable <=  1'b0;
					localMemoryDataWrite   <= 32'b0;
				end
			end
		endcase
	end

	always @(*) begin
		case (wb_source)
			SOURCE_INSTRUCTION: begin
				wbAddress 	  <= coreInstructionAddress[27:0];
				wbByteSelect  <= 4'b1111;
				wbEnable  	  <= coreInstructionEnable;
				wbWriteEnable <= 1'b0;
				wbDataWrite   <= 32'b0;
			end

			SOURCE_DATA: begin
				wbAddress 	  <= coreDataAddress[27:0];
				wbByteSelect  <= coreDataByteSelect;
				wbEnable  	  <= coreDataEnable;
				wbWriteEnable <= coreDataWriteEnable;
				wbDataWrite   <= coreDataDataWrite;
			end

			default: begin
				if (instruction_enableWBRequest) begin
					wbAddress 	  <= coreInstructionAddress[27:0];
					wbByteSelect  <= 4'b1111;
					wbEnable  	  <= coreInstructionEnable;
					wbWriteEnable <= 1'b0;
					wbDataWrite   <= 32'b0;
				end else if (data_enableWBRequest) begin
					wbAddress 	  <= coreDataAddress[27:0];
					wbByteSelect  <= coreDataByteSelect;
					wbEnable  	  <= coreDataEnable;
					wbWriteEnable <= coreDataWriteEnable;
					wbDataWrite   <= coreDataDataWrite;
				end else begin
					wbAddress 	  <= 28'b0;
					wbByteSelect  <=  4'b0;
					wbEnable  	  <=  1'b0;
					wbWriteEnable <=  1'b0;
					wbDataWrite   <= 32'b0;
				end
			end
		endcase
	end

	always @(*) begin
		if (rst) begin
			coreInstructionDataRead <= ~32'b0;
			coreInstructionBusy 	<= 1'b1;
		end else begin
			if (localMemory_source == SOURCE_INSTRUCTION) begin
				coreInstructionDataRead <= localMemoryDataRead;
				coreInstructionBusy 	<= localMemoryBusy;
			end else if (wb_source == SOURCE_INSTRUCTION) begin
				coreInstructionDataRead <= wbDataRead;
				coreInstructionBusy 	<= wbBusy;
			end else begin
				coreInstructionDataRead <= ~32'b0;
				coreInstructionBusy 	<= 1'b1;
			end
		end
	end

	always @(*) begin
		if (rst) begin
			coreDataDataRead <= ~32'b0;
			coreDataBusy 	 <= 1'b1;
		end else begin
			if (localMemory_source == SOURCE_DATA) begin
				coreDataDataRead <= localMemoryDataRead;
				coreDataBusy 	 <= localMemoryBusy;
			end else if (wb_source == SOURCE_DATA) begin
				coreDataDataRead <= wbDataRead;
				coreDataBusy 	 <= wbBusy;
			end
			 else begin
				coreDataDataRead <= ~32'b0;
				coreDataBusy 	 <= 1'b1;
			end
		end
	end

endmodule