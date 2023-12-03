`default_nettype none

module PipeStore (
		input wire clk,
		input wire rst,

		// Pipe control
		input wire stepPipe,
		input wire pipeStall,
		output wire currentPipeStall,
		output wire active,
		input wire[31:0] currentInstruction,
		output wire[31:0] lastInstruction,
		output wire invalidInstruction,

		// Memory control
		output wire expectingLoad,

		// Store inputs
		input wire[31:0] memoryDataRead,
		input wire[31:0] aluResultData,
		input wire[31:0] csrData,

		// Register store control
		output wire[4:0] registerWriteAddress,
		output wire[31:0] registerWriteData,
		output wire registerWriteEnable,

		// CSR store control
		output wire[11:0] csrWriteAddress,
		output wire[31:0] csrWriteData,
		output wire csrWriteEnable,

		// Stall control
		output wire isFence,
		output wire isRET
	);

	// Pipe control
	PipeStage pipeStage(
		.clk(clk),
		.rst(rst),
		.stepPipe(stepPipe),
		.pipeStall(pipeStall),
		.currentPipeStall(currentPipeStall),
		.active(active),
		.currentInstruction(currentInstruction),
		.lastInstruction(lastInstruction));

	// Instruction decode
	wire[6:0] _unused_opcode;
	wire[4:0] rdIndex; wire[4:0] _unused_rs1Index; wire[4:0] _unused_rs2Index;
	wire[2:0] funct3; wire[6:0] _unused_funct7;
	wire _unused_isCompressed;
	wire isLUI; wire isAUIPC; wire isJAL; wire isJALR; wire _unused_isBranch; wire isLoad; wire isStore;
	wire _unused_isALUImmBase; wire _unused_isALUImmNormal; wire _unused_isALUImmShift; wire isALUImm; wire isALU;
	wire _unused_isSystem;
	wire isCSR; wire _unused_isCSRIMM; wire isCSRRW; wire _unused_isCSRRS; wire _unused_isCSRRC;
	wire _unused_isECALL; wire _unused_isEBREAK;
	InstructionDecode decode(
		.currentInstruction(currentInstruction),
		.isNOP(pipeStall),
		.opcode(_unused_opcode),
		.rdIndex(rdIndex), .rs1Index(_unused_rs1Index), .rs2Index(_unused_rs2Index),
		.funct3(funct3), .funct7(_unused_funct7),
		.isCompressed(_unused_isCompressed),
		.isLUI(isLUI), .isAUIPC(isAUIPC), .isJAL(isJAL), .isJALR(isJALR), .isBranch(_unused_isBranch), .isLoad(isLoad), .isStore(isStore),
		.isALUImmBase(_unused_isALUImmBase), .isALUImmNormal(_unused_isALUImmNormal), .isALUImmShift(_unused_isALUImmShift), .isALUImm(isALUImm), .isALU(isALU),
		.isFence(isFence), .isSystem(_unused_isSystem),
		.isCSR(isCSR), .isCSRIMM(_unused_isCSRIMM), .isCSRRW(isCSRRW), .isCSRRS(_unused_isCSRRS), .isCSRRC(_unused_isCSRRC),
		.isECALL(_unused_isECALL), .isEBREAK(_unused_isEBREAK), .isRET(isRET),
		.invalidInstruction(invalidInstruction)
	);

	// Memory connections
	wire[1:0] targetMemoryAddressByte = aluResultData[1:0];
	wire loadSigned    = (funct3 == 3'b000) || (funct3 == 3'b001);
	wire loadStoreByte = funct3[1:0] == 2'b00;
	wire loadStoreHalf = funct3[1:0] == 2'b01;
	wire loadStoreWord = funct3 == 3'b010;
	reg[3:0] baseByteMask;
	always @(*) begin
		if (isLoad || isStore) begin
			if (loadStoreWord) baseByteMask = 4'b1111;
			else if (loadStoreHalf) baseByteMask = 4'b0011;
			else if (loadStoreByte) baseByteMask = 4'b0001;
			else baseByteMask = 4'b0000;
		end else begin
			baseByteMask = 4'b0000;
		end
	end

	reg signExtend;
	always @(*) begin
		if (loadSigned) begin
			if (loadStoreByte) begin
				case (targetMemoryAddressByte)
					2'b00: signExtend = memoryDataRead[7];
					2'b01: signExtend = memoryDataRead[15];
					2'b10: signExtend = memoryDataRead[23];
					2'b11: signExtend = memoryDataRead[31];
				endcase
			end else if (loadStoreHalf) begin
				case (targetMemoryAddressByte)
					2'b00: signExtend = memoryDataRead[15];
					2'b01: signExtend = memoryDataRead[23];
					2'b10: signExtend = memoryDataRead[31];
					2'b11: signExtend = 1'b0;
				endcase
			end else begin
				signExtend = 1'b0;
			end
		end else begin
			signExtend = 1'b0;
		end
	end

	wire[7:0] signExtendByte = signExtend ? 8'hFF : 8'h00;

	wire[6:0] loadStoreByteMask = {3'b0, baseByteMask} << targetMemoryAddressByte;
	wire loadStoreByteMaskValid = |(loadStoreByteMask[3:0]);
	wire addressMissaligned = |loadStoreByteMask[6:4];
	wire shouldLoad  = loadStoreByteMaskValid && !addressMissaligned && isLoad;

	reg[31:0] dataIn;
	always @(*) begin
		case (targetMemoryAddressByte)
			2'b00: dataIn = {
					loadStoreByteMask[3] ? memoryDataRead[31:24] : signExtendByte,
					loadStoreByteMask[2] ? memoryDataRead[23:16] : signExtendByte,
					loadStoreByteMask[1] ? memoryDataRead[15:8]  : signExtendByte,
					loadStoreByteMask[0] ? memoryDataRead[7:0]   : 8'h00
				};

			2'b01: dataIn = {
					signExtendByte,
					loadStoreByteMask[3] ? memoryDataRead[31:24] : signExtendByte,
					loadStoreByteMask[2] ? memoryDataRead[23:16] : signExtendByte,
					loadStoreByteMask[1] ? memoryDataRead[15:8]  : 8'h00
				};

			2'b10: dataIn = {
					signExtendByte,
					signExtendByte,
					loadStoreByteMask[3] ? memoryDataRead[31:24] : signExtendByte,
					loadStoreByteMask[2] ? memoryDataRead[23:16] : 8'h00
				};

			2'b11: dataIn = {
					signExtendByte,
					signExtendByte,
					signExtendByte,
					loadStoreByteMask[3] ? memoryDataRead[31:24] : 8'h00
				};
		endcase
	end

	// Register Write
	wire csrWrite = isCSRRW || (isCSR && |rdIndex);
	wire integerRegisterWriteEn = isLUI || isAUIPC || isJAL || isJALR || isALU || isALUImm || isLoad || csrWrite;
	reg[31:0] integerRegisterWriteData;
	always @(*) begin
		case (1'b1)
			isLUI			   : integerRegisterWriteData = aluResultData;
			isAUIPC			   : integerRegisterWriteData = aluResultData;
			isJAL			   : integerRegisterWriteData = aluResultData;
			isJALR	   		   : integerRegisterWriteData = aluResultData;
			shouldLoad  	   : integerRegisterWriteData = dataIn;
			(isALU || isALUImm): integerRegisterWriteData = aluResultData;
			csrWrite   		   : integerRegisterWriteData = csrData;
			default: integerRegisterWriteData = 32'b0;
		endcase
	end

	// Memory control
	assign expectingLoad = shouldLoad;

	// Register write control
	assign registerWriteAddress = rdIndex;
	assign registerWriteData = integerRegisterWriteData;
	assign registerWriteEnable = integerRegisterWriteEn && !pipeStall;

	// CSR write control
	assign csrWriteAddress = currentInstruction[31:20];
	assign csrWriteData = aluResultData;
	assign csrWriteEnable = csrWrite && !pipeStall;

endmodule
