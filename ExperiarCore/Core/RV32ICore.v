`default_nettype none

module RV32ICore(
`ifdef USE_POWER_PINS
	inout vccd1,	// User area 1 1.8V supply
	inout vssd1,	// User area 1 digital ground
`endif

		input wire clk,
		input wire rst,

		// Instruction cache interface
		output wire[31:0] instruction_memoryAddress,
		output wire instruction_memoryEnable,
		input wire[31:0] instruction_memoryDataRead,
		input wire instruction_memoryBusy,
		input wire instruction_memoryAccessFault,
		input wire instruction_memoryAddressBreakpoint,

		// Data cache interface
		output wire[31:0] data_memoryAddress,
		output wire[3:0] data_memoryByteSelect,
		output wire data_memoryEnable,
		output wire data_memoryWriteEnable,
		output wire[31:0] data_memoryDataWrite,
		input wire[31:0] data_memoryDataRead,
		input wire data_memoryBusy,
		input wire data_memoryAccessFault,
		input wire data_memoryAddressBreakpoint,

		// Management interface
		input wire management_run,
		input wire management_interruptEnable,
		input wire management_writeEnable,
		input wire[3:0] management_byteSelect,
		input wire[15:0] management_address,
		input wire[31:0] management_writeData,
		output wire[31:0] management_readData,

		// System info
		input wire[7:0] coreIndex,
		input wire[10:0] manufacturerID,
		input wire[15:0] partID,
		input wire[3:0] versionID,
		input wire[25:0] extensions,

		// Traps
		input wire[15:0] userInterrupts,

		// Logic probes
		output wire probe_state,
		output wire[1:0] probe_env,
		output wire[31:0] probe_programCounter
    );

	localparam STATE_HALT 	 	= 1'b0;
	localparam STATE_EXECUTE 	= 1'b1;

	//localparam STATE_HALT 	 	= 2'b00;
	//localparam STATE_FETCH   	= 2'b10;
	//localparam STATE_EXECUTE 	= 2'b11;

	// System state
	reg state;
	wire stateExecute = state == STATE_EXECUTE;
	wire[31:0] fetchProgramCounter;
	wire[31:0] nextFetchProgramCounter;
	wire[31:0] executeProgramCounter;

	// Pipe control
	wire progressPipe;
	wire pipeActive;
	wire stepPipe;
	wire stallPipe;
	wire stepProgramCounter;

	// System registers
	reg[31:0] registers [0:31];

	// State control
	always @(posedge clk) begin
		if (rst) begin
			state <= STATE_HALT;
		end else begin
			case (state)
				STATE_HALT: begin
					if (progressPipe) begin
						state <= STATE_EXECUTE;
					end
				end

				STATE_EXECUTE: begin
					if (stepPipe) begin
						if (!progressPipe) state <= STATE_HALT;
					end
				end

				default: state <= STATE_HALT;
			endcase
		end
	end

	// Management control
	localparam MANAGMENT_ADDRESS_SYSTEM	   = 2'b00;
	localparam MANAGMENT_ADDRESS_REGISTERS = 2'b01;
	localparam MANAGMENT_ADDRESS_CSR 	   = 2'b10;

	wire management_selectProgramCounter      = (management_address[15:14] == MANAGMENT_ADDRESS_SYSTEM) && (management_address[13:4] == 10'h000);
	wire management_selectInstructionRegister = (management_address[15:14] == MANAGMENT_ADDRESS_SYSTEM) && (management_address[13:4] == 10'h001);
	wire management_selectClearError		  = (management_address[15:14] == MANAGMENT_ADDRESS_SYSTEM) && (management_address[13:4] == 10'h002);
	wire management_selectRegister            = (management_address[15:14] == MANAGMENT_ADDRESS_REGISTERS) && (management_address[13:7] == 7'h00);
	wire management_selectCSR 				  = management_address[15:14] == MANAGMENT_ADDRESS_CSR;

	wire management_writeValid = !management_run && management_writeEnable;
	wire management_writeProgramCounter = management_writeValid && management_selectProgramCounter;
	wire management_writeProgramCounter_set = management_writeProgramCounter && (management_address[3:0] == 4'h0);
	wire management_writeProgramCounter_jump = management_writeProgramCounter && (management_address[3:0] == 4'h4);
	wire management_writeProgramCounter_step = management_writeProgramCounter && (management_address[3:0] == 4'h8);
	wire management_writeClearError = management_writeValid && management_selectClearError;
	wire management_writeRegister = management_writeValid && management_selectRegister;
	wire management_writeCSR = management_writeValid && management_selectCSR;

	wire management_readValid = !management_run && !management_writeEnable;
	wire management_readProgramCounter = management_readValid && management_selectProgramCounter;
	wire management_readInstructionRegister = management_readValid && management_selectInstructionRegister;
	wire management_readRegister = management_readValid && management_selectRegister;
	wire management_readCSR = management_readValid && management_selectCSR;

	
	reg management_previousRun;
	wire management_restart = (management_run && !management_previousRun) || management_writeProgramCounter_step;

	// Make sure to flush the pipe after a step
	reg management_pipeStartup;
	always @(posedge clk) begin
		if (rst) begin
			management_previousRun <= 1'b0;
			management_pipeStartup <= 1'b0;
		end else begin
			if (management_restart) management_pipeStartup <= 1'b1;
			else if (stepProgramCounter) management_pipeStartup <= 1'b0;

			management_previousRun <= management_run;
		end
	end

	wire management_allowInstruction = (management_run && management_previousRun) || management_writeProgramCounter_step || management_pipeStartup;

	wire[4:0] management_registerIndex = management_address[6:2];
	wire[11:0] management_csrIndex = management_address[13:2];

	reg[31:0] management_dataOut;

	wire[31:0] csrReadData;

	always @(*) begin
		case (1'b1)
			management_readProgramCounter: management_dataOut <= fetchProgramCounter;
			management_readInstructionRegister : management_dataOut <= pipe1_currentInstruction;
			management_readRegister: management_dataOut <= !management_registerIndex ? registers[management_registerIndex] : 32'b0;
			management_readCSR: management_dataOut <= csrReadData;
			default: management_dataOut <= ~32'b0;
		endcase
	end

	assign management_readData = {
		management_byteSelect[3] ? management_dataOut[31:24] : 8'h00,
		management_byteSelect[2] ? management_dataOut[23:16] : 8'h00,
		management_byteSelect[1] ? management_dataOut[15:8]  : 8'h00,
		management_byteSelect[0] ? management_dataOut[7:0]   : 8'h00
	};

	wire[31:0] trapVector;
	wire[31:0] trapReturnVector;
	wire inTrap;

	// ----------State----------
	FlowControl flowControl(
		.clk(clk),
		.rst(rst),
		.management_allowInstruction(management_allowInstruction),
		.stateExecute(state == STATE_EXECUTE),
		.requestingInstruction(instruction_memoryEnable),
		.instructionBusy(instruction_memoryBusy),
		.requestingData(data_memoryEnable),
		.dataBusy(data_memoryBusy),
		.pipe0_active(pipe0_active),
		.pipe1_active(pipe1_active),
		.pipe2_active(pipe2_active),
		.pipe1_shouldStall(pipe1_shouldStall),
		.pipe2_shouldStall(pipe2_shouldStall),
		.stepPipe(stepPipe),
		.stallPipe(stallPipe),
		.progressPipe(progressPipe));

	ProgramCounter programCounter(
		.clk(clk),
		.rst(rst),
		.management_writeProgramCounter_set(management_writeProgramCounter_set),
		.management_writeProgramCounter_jump(management_writeProgramCounter_jump),
		.management_writeData(management_writeData),
		.state(state),
		.progressPipe(progressPipe),
		.stepPipe(stepPipe),
		.stallPipe(stallPipe),
		.inTrap(inTrap),
		.trapVector(trapVector),
		.pipe1_isRET(pipe1_isRET),
		.trapReturnVector(trapReturnVector),
		.pipe1_jumpEnable(pipe1_jumpEnable),
		.pipe1_nextProgramCounter(pipe1_nextProgramCounter),
		.fetchProgramCounter(fetchProgramCounter),
		.nextFetchProgramCounter(nextFetchProgramCounter),
		.executeProgramCounter(executeProgramCounter),
		.stepProgramCounter(stepProgramCounter));

	// ----------Pipe----------
	wire pipe1_shouldStall;
	wire pipe2_shouldStall;
	wire shouldStore;
	wire shouldLoad;

	reg memoryOperationCompleted;
	reg cancelStall;

	// 0: Request instruction
	wire pipe0_stall;
	wire pipe0_active;
	wire[31:0] pipe0_currentInstruction;
	wire[31:0] pipe0_programCounter;
	wire pipe0_addressMisaligned;
	wire[31:0] pipe0_instructionFetchAddress;
	wire pipe0_instructionFetchEnable;
	PipeFetch pipe0_fetch (
		.clk(clk),
		.rst(rst),
		.run(management_allowInstruction),
		.pipeStartup(management_pipeStartup),
		.stepPipe(stepPipe),
		.pipeStall(stallPipe),
		.currentPipeStall(pipe0_stall),
		.active(pipe0_active),
		.currentInstruction(instruction_memoryDataRead),
		.lastInstruction(pipe0_currentInstruction),
		.fetchProgramCounter(nextFetchProgramCounter),
		.addressMisaligned(pipe0_addressMisaligned),
		.fetchAddress(pipe0_instructionFetchAddress),
		.fetchEnable(pipe0_instructionFetchEnable),
		.fetchBusy(instruction_memoryBusy));

	// 1: Request data/Write data/ALU operation
	reg[31:0] pipe1_resultRegister;
	reg[31:0] pipe1_loadResult;
	reg[31:0] pipe1_csrData;

	wire pipe1_stall;
	wire pipe1_active;
	wire pipe1_invalidInstruction;
	wire[31:0] pipe1_currentInstruction;
	wire[11:0] pipe1_csrReadAddress;
	wire pipe1_csrReadEnable;

	wire[4:0] pipe1_rs1Address;
	wire[4:0] pipe1_rs2Address;
	wire[31:0] pipe1_rs1Data;
	wire[31:0] pipe1_rs2Data;
	wire pipe1_operationResultStoreEnable;
	wire[31:0] pipe1_operationResult;
	wire pipe1_isJump;
	wire pipe1_isFence;
	wire pipe1_jumpEnable;
	wire pipe1_failedBranch;
	wire[31:0] pipe1_nextProgramCounter;
	wire pipe1_jumpMissaligned;
	wire pipe1_addressMisaligned_load;
	wire pipe1_addressMisaligned_store;
	wire pipe1_memoryEnable;
	wire pipe1_memoryWriteEnable;
	wire[3:0] pipe1_memoryByteSelect;
	wire[31:0] pipe1_memoryAddress;
	wire[31:0] pipe1_memoryWriteData;
	wire[31:0] pipe1_fullMemoryAddress;
	wire pipe1_isECALL;
	wire pipe1_isEBREAK;
	wire pipe1_isRET;
	PipeOperation pipe1_operation (
		.clk(clk),
		.rst(rst),
		.stepPipe(stepPipe),
		.pipeStall(pipe0_stall && !cancelStall),
		.currentPipeStall(pipe1_stall),
		.active(pipe1_active),
		.currentInstruction(pipe0_currentInstruction),
		.lastInstruction(pipe1_currentInstruction),
		.invalidInstruction(pipe1_invalidInstruction),
		.csrReadAddress(pipe1_csrReadAddress),
		.csrReadData(csrReadData),
		.csrReadEnable(pipe1_csrReadEnable),
		.programCounter(executeProgramCounter),
		.rs1Address(pipe1_rs1Address),
		.rs1Data(pipe1_rs1Data),
		.rs2Address(pipe1_rs2Address),
		.rs2Data(pipe1_rs2Data),
		.operationResultStoreEnable(pipe1_operationResultStoreEnable),
		.operationResult(pipe1_operationResult),
		.isJump(pipe1_isJump),
		.isFence(pipe1_isFence),
		.jumpEnable(pipe1_jumpEnable),
		.failedBranch(pipe1_failedBranch),
		.nextProgramCounter(pipe1_nextProgramCounter),
		.jumpMissaligned(pipe1_jumpMissaligned),
		.addressMisaligned_load(pipe1_addressMisaligned_load),
		.addressMisaligned_store(pipe1_addressMisaligned_store),
		.memoryEnable(pipe1_memoryEnable),
		.memoryWriteEnable(pipe1_memoryWriteEnable),
		.memoryByteSelect(pipe1_memoryByteSelect),
		.memoryAddress(pipe1_memoryAddress),
		.memoryWriteData(pipe1_memoryWriteData),
		.fullMemoryAddress(pipe1_fullMemoryAddress),
		.isECALL(pipe1_isECALL),
		.isEBREAK(pipe1_isEBREAK),
		.isRET(pipe1_isRET));

	assign pipe1_shouldStall = pipe1_isJump || pipe1_isFence || pipe1_isRET; // 
	
	always @(posedge clk) begin
		if (rst) begin
			pipe1_resultRegister <= 32'b0;
			pipe1_csrData <= 32'b0;
			cancelStall <= 1'b0;
		end else begin
			if (stateExecute) begin
				if (stepPipe) begin
					if (pipe1_operationResultStoreEnable) pipe1_resultRegister <= pipe1_operationResult;
					if (pipe1_csrReadEnable) pipe1_csrData <= csrReadData;
				end

				cancelStall <= pipe1_failedBranch;
			end
		end
	end

	reg delayedStepPipe;
	reg storeLoadResult;
	always @(negedge clk) begin
		if (rst) begin
			memoryOperationCompleted <= 1'b0;
			storeLoadResult <= 1'b0;
		end else begin
			if (stateExecute) begin
				if (delayedStepPipe || !pipe1_memoryEnable) begin
					memoryOperationCompleted <= 1'b0;
					storeLoadResult <= 1'b0;
				end else begin
					if (data_memoryBusy) begin
						storeLoadResult <= 1'b0;
					end else begin
						if (shouldLoad) begin
							memoryOperationCompleted <= 1;
							storeLoadResult <= 1'b1;
						end else if (shouldStore) begin
							memoryOperationCompleted <= 1;
							storeLoadResult <= 1'b0;
						end
					end
				end

				delayedStepPipe <= stepPipe;
			end
		end
	end

	always @(posedge clk) begin
		if (rst) begin
			pipe1_loadResult <= ~32'b0;
		end else begin
			if (stateExecute) begin
				if (storeLoadResult) begin
					pipe1_loadResult <= data_memoryDataRead;
				end
			end
		end
	end

	// 3: Store data
	wire pipe2_stall;
	wire pipe2_active;
	wire pipe2_invalidInstruction;
	wire[31:0] pipe2_currentInstruction;
	wire pipe2_expectingLoad;
	wire[4:0] pipe2_rdAddress;
	wire[31:0] pipe2_registerWriteData;
	wire pipe2_registerWriteEnable;
	wire[11:0] pipe2_csrWriteAddress;
	wire[31:0] pipe2_csrWriteData;
	wire pipe2_csrWriteEnable;
	wire pipe2_isFence;
	wire pipe2_isRET;
	PipeStore pipe2_store (
		.clk(clk),
		.rst(rst),
		.stepPipe(stepPipe),
		.pipeStall(pipe1_stall),
		.currentPipeStall(pipe2_stall),
		.active(pipe2_active),
		.currentInstruction(pipe1_currentInstruction),
		.lastInstruction(pipe2_currentInstruction),
		.invalidInstruction(pipe2_invalidInstruction),
		.expectingLoad(pipe2_expectingLoad),
		.memoryDataRead(memoryOperationCompleted ? pipe1_loadResult : data_memoryDataRead),
		.aluResultData(pipe1_resultRegister),
		.csrData(pipe1_csrData),
		.registerWriteAddress(pipe2_rdAddress),
		.registerWriteData(pipe2_registerWriteData),
		.registerWriteEnable(pipe2_registerWriteEnable),
		.csrWriteAddress(pipe2_csrWriteAddress),
		.csrWriteData(pipe2_csrWriteData),
		.csrWriteEnable(pipe2_csrWriteEnable),
		.isFence(pipe2_isFence),
		.isRET(pipe2_isRET));

	assign pipe2_shouldStall = pipe2_isFence || pipe2_isRET;
	assign pipeActive = pipe0_active || pipe1_active || pipe2_active;

	// Integer restister control
	assign pipe1_rs1Data = |pipe1_rs1Address ? registers[pipe1_rs1Address] : 32'b0;
	assign pipe1_rs2Data = |pipe1_rs2Address ? registers[pipe1_rs2Address] : 32'b0;

	always @(negedge clk) begin
		if (rst) begin
		end else begin
			if (stateExecute) begin
				if (delayedStepPipe) begin
					if (pipe2_registerWriteEnable && |pipe2_rdAddress) registers[pipe2_rdAddress] <= pipe2_registerWriteData;
				end
			end
		end
	end

	assign shouldStore = !memoryOperationCompleted && pipe1_memoryEnable && pipe1_memoryWriteEnable;
	assign shouldLoad = !memoryOperationCompleted && (pipe1_memoryEnable && !pipe1_memoryWriteEnable);

	// Memory control
	assign instruction_memoryAddress = pipe0_instructionFetchAddress;
	assign instruction_memoryEnable = pipe0_instructionFetchEnable;

	assign data_memoryAddress = pipe1_memoryAddress;
	assign data_memoryByteSelect = pipe1_memoryByteSelect;
	assign data_memoryEnable = pipe1_memoryEnable && !memoryOperationCompleted;
	assign data_memoryWriteEnable = pipe1_memoryWriteEnable;
	assign data_memoryDataWrite = pipe1_memoryWriteData;

	// System commands 
	wire eCall = pipe1_isECALL && stateExecute;
	wire eBreak = pipe1_isEBREAK && stateExecute;
	wire trapReturn = pipe1_isRET && stateExecute;

	wire isMachineTimerInterrupt = 1'b0;
	wire isMachineExternalInterrupt = 1'b0;
	wire isMachineSoftwareInterrupt = 1'b0;

	// CSRs
	// CSR interface
	wire csrWriteEnable = management_writeCSR || (management_run && pipe2_csrWriteEnable && stateExecute);
	wire csrReadEnable = management_readCSR || (management_run && pipe1_csrReadEnable && stateExecute);
	wire[11:0] csrWriteAddress = !management_run ? management_csrIndex : pipe2_csrWriteAddress;
	wire[11:0] csrReadAddress = !management_run ? management_csrIndex : pipe1_csrReadAddress;
	wire[31:0] csrWriteData = !management_run ? management_writeData : pipe2_csrWriteData;
	
	wire instructionCompleted = !pipe2_stall;
	CSR csr(
		.clk(clk),
		.rst(rst),
		.csrWriteEnable(csrWriteEnable),
		.csrReadEnable(csrReadEnable),
		.csrWriteAddress(csrWriteAddress),
		.csrReadAddress(csrReadAddress),
		.csrWriteData(csrWriteData),
		.csrReadData(csrReadData),
		.coreIndex(coreIndex),
		.manufacturerID(manufacturerID),
		.partID(partID),
		.versionID(versionID),
		.extensions(extensions),
		.instructionCompleted(instructionCompleted),
		.programCounter(executeProgramCounter),
		.currentInstruction(pipe1_currentInstruction),
		.instruction_memoryAddress(instruction_memoryAddress),
		.data_memoryAddress(pipe1_fullMemoryAddress),
		.isMachineTimerInterrupt(isMachineTimerInterrupt),
		.isMachineExternalInterrupt(isMachineExternalInterrupt),
		.isMachineSoftwareInterrupt(isMachineSoftwareInterrupt),
		.isFetchAddressMisaligned(pipe0_addressMisaligned),
		.isDataAddressMisaligned_load(pipe1_addressMisaligned_load),
		.isDataAddressMisaligned_store(pipe1_addressMisaligned_store),
		.isJumpMissaligned(pipe1_jumpMissaligned),
		.isFetchAccessFault(instruction_memoryAccessFault),
		.isDataAccessFault_load(data_memoryAccessFault && data_memoryEnable && !data_memoryWriteEnable),
		.isDataAccessFault_store(data_memoryAccessFault && data_memoryEnable && data_memoryWriteEnable),
		.isInvalidInstruction(pipe1_invalidInstruction),
		.isEBREAK(eBreak),
		.isECALL(eCall),
		.isFetchAddressBreakpoint(instruction_memoryAddressBreakpoint),
		.isDataAddressBreakpoint(data_memoryAddressBreakpoint),
		.userInterrupts(management_interruptEnable ? userInterrupts : 16'b0),
		.trapReturn(trapReturn),
		.inTrap(inTrap),
		.trapVector(trapVector),
		.trapReturnVector(trapReturnVector));

	// Debug
	assign probe_state = state;
	assign probe_env = { eCall, eBreak };
	assign probe_programCounter = executeProgramCounter;

endmodule
