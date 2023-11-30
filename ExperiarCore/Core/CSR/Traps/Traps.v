`default_nettype none

module Traps (
		input wire clk,
		input wire rst,

		// CSR interface
		input wire csrWriteEnable,
		input wire csrReadEnable,
		input wire[11:0] csrWriteAddress,
		input wire[11:0] csrReadAddress,
		input wire[31:0] csrWriteData,
		output reg[31:0] csrReadData,
		output wire requestOutput,

		// System interface
		input wire[31:0] programCounter,
		input wire[31:0] currentInstruction,
		input wire[31:0] instruction_memoryAddress,
		input wire[31:0] data_memoryAddress,
		input wire isMachineTimerInterrupt,
		input wire isMachineExternalInterrupt,
		input wire isMachineSoftwareInterrupt,
		input wire isFetchAddressMisaligned,
		input wire isDataAddressMisaligned_load,
		input wire isDataAddressMisaligned_store,
		input wire isJumpMissaligned,
		input wire isFetchAccessFault,
		input wire isDataAccessFault_load,
		input wire isDataAccessFault_store,
		input wire isInvalidInstruction,
		input wire isEBREAK,
		input wire isECALL,
		input wire isFetchAddressBreakpoint,
		input wire isDataAddressBreakpoint,
		input wire[15:0] userInterrupts,
		input wire trapReturn,
		output wire inTrap,
		output wire[31:0] trapVector,
		output wire[31:0] trapReturnVector
	);

	reg machineInterruptEnable;
	reg machinePreviousInterruptEnable;
	wire[31:0] mieValue;
	reg[31:0] mtvecValue;
	reg[31:0] mepcValue;
	reg[31:0] mcauseValue;
	reg[31:0] mtvalValue;
	reg[31:0] mipValue;

	wire[11:0] systemInterrupts = { isMachineExternalInterrupt, 1'b0, 1'b0, 1'b0,
									isMachineTimerInterrupt, 1'b0, 1'b0, 1'b0,
									isMachineSoftwareInterrupt, 1'b0, 1'b0, 1'b0 };
	wire[31:0] pendingInterrupts = { userInterrupts, 4'b0000, systemInterrupts } & mieValue;

	wire misalignedInstructionFetch = isFetchAddressMisaligned || isJumpMissaligned;

	reg[30:0] trapCause;
	always @(*) begin
		if (isInterrupt) begin
			case (1'b1)
				isMachineSoftwareInterrupt: trapCause = 30'd3;
				isMachineTimerInterrupt: trapCause = 30'd7;
				|userInterrupts: trapCause = 30'd8;
				isMachineExternalInterrupt: trapCause = 30'd11;
				default: trapCause = 30'b0;
			endcase
		end else begin
			case (1'b1)
				isFetchAddressBreakpoint: trapCause = 30'd3;
				isFetchAccessFault: trapCause = 30'd1;
				isInvalidInstruction: trapCause = 30'd2;
				misalignedInstructionFetch: trapCause = 30'd0;
				isECALL: trapCause = 30'd11;
				isEBREAK: trapCause = 30'd3;
				isDataAddressBreakpoint: trapCause = 30'd3;
				isDataAddressMisaligned_store: trapCause = 30'd6;
				isDataAddressMisaligned_load: trapCause = 30'd4;
				isDataAccessFault_store: trapCause = 30'd7;
				isDataAccessFault_load: trapCause = 30'd5;
				default: trapCause = 30'b0;
			endcase
		end
	end

`ifdef SIM
	always @(posedge clk ) begin
		if (isInterrupt) begin
			case (1'b1)
				isMachineSoftwareInterrupt: $display("%c[1;92mEntered Trap: MachineSoftwareInterrupt%c[0m", 27, 27);
				isMachineTimerInterrupt: $display("%c[1;92mEntered Trap: MachineTimerInterrupt%c[0m", 27, 27);
				|userInterrupts: $display("%c[1;92mEntered Trap: userInterrupts%c[0m", 27, 27);
				isMachineExternalInterrupt: $display("%c[1;92mEntered Trap: MachineExternalInterrupt%c[0m", 27, 27);
			endcase
		end else begin
			case (1'b1)
				isFetchAddressBreakpoint: $display("%c[1;35mEntered Trap: FetchAddressBreakpoint%c[0m", 27, 27);
				isFetchAccessFault: $display("%c[1;31mEntered Trap: FetchAccessFault%c[0m", 27, 27);
				isInvalidInstruction: $display("%c[1;31mEntered Trap: InvalidInstruction%c[0m", 27, 27);
				misalignedInstructionFetch: $display("%c[1;31mEntered Trap: misalignedInstructionFetch%c[0m", 27, 27);
				isECALL: $display("%c[1;92mEntered Trap: ECALL%c[0m", 27, 27);
				isEBREAK: $display("%c[1;92mEntered Trap: EBREAK%c[0m", 27, 27);
				isDataAddressBreakpoint: $display("%c[1;35mEntered Trap: DataAddressBreakpoint%c[0m", 27, 27);
				isDataAddressMisaligned_store: $display("%c[1;31mEntered Trap: DataAddressMisaligned_store%c[0m", 27, 27);
				isDataAddressMisaligned_load: $display("%c[1;31mEntered Trap: DataAddressMisaligned_load%c[0m", 27, 27);
				isDataAccessFault_store: $display("%c[1;31mEntered Trap: DataAccessFault_store%c[0m", 27, 27);
				isDataAccessFault_load: $display("%c[1;31mEntered Trap: DataAccessFault_load%c[0m", 27, 27);
			endcase
		end
	end
`endif

	// Misaligned instruction fetch sets trap cause to zero, so needs to be triggered specifically
	wire isException = |trapCause || misalignedInstructionFetch;
	wire isInterrupt = |pendingInterrupts;
	wire isBreakPoint = isEBREAK || isFetchAddressBreakpoint || isDataAddressBreakpoint;
	wire isTrap = isException || isInterrupt;

	assign inTrap = isTrap;

	wire[31:0] mipLoadValue = machineInterruptEnable ? pendingInterrupts : 1'b0;

	reg[31:0] mtvalLoadValue;
	always @(*) begin
		 if (isTrap) begin
			 case (1'b1)
				 isBreakPoint: mtvalLoadValue = programCounter;
				 isFetchAddressMisaligned: mtvalLoadValue = instruction_memoryAddress;
				 isDataAddressMisaligned_store || isDataAddressMisaligned_load: mtvalLoadValue =  data_memoryAddress;
				 isInvalidInstruction: mtvalLoadValue = currentInstruction;
				 default: mtvalLoadValue = 32'b0;
			 endcase
		 end else begin
			 mtvalLoadValue = 32'b0;
		 end
	end

	// mstatus
	wire[31:0] mstatusReadData;
	wire mstatusRequestOutput;
	wire _unused_mstatusReadDataEnable;
	wire[31:0] mstatusWriteData;
	wire mstatusWriteDataEnable;
	CSR_DataRegister #(.ADDRESS(12'h300)) mstatus(
		.clk(clk),
		.rst(rst),
		.csrWriteEnable(csrWriteEnable),
		.csrReadEnable(csrReadEnable),
		.csrWriteAddress(csrWriteAddress),
		.csrReadAddress(csrReadAddress),
		.csrWriteData(csrWriteData),
		.csrReadData(mstatusReadData),
		.csrRequestOutput(mstatusRequestOutput),
		.readData( { 25'b0, machinePreviousInterruptEnable, 3'b0, machineInterruptEnable, 2'b0 } ),
		.readDataEnable(_unused_mstatusReadDataEnable),
		.writeData(mstatusWriteData),
		.writeDataEnable(mstatusWriteDataEnable));

	always @(posedge clk) begin
		if (rst) begin
			machineInterruptEnable <= 1'b0;
			machinePreviousInterruptEnable <= 1'b0;
		end
		else begin
			if (trapReturn) begin
				machineInterruptEnable <= machinePreviousInterruptEnable;
				machinePreviousInterruptEnable <= 1'b0;
			end else if (isTrap) begin
				machineInterruptEnable <= 1'b0;
				machinePreviousInterruptEnable <= machineInterruptEnable;
			end else if (mstatusWriteDataEnable) begin
				machineInterruptEnable <=  mstatusWriteData[3];
				machinePreviousInterruptEnable <=  mstatusWriteData[7];
			end
		end
	end

	// mie
	wire[31:0] mieReadData;
	wire mieRequestOutput;
	CSR_ConfigurationRegister #(.ADDRESS(12'h304), .DEFAULT(32'b0)) mie(
		.clk(clk),
		.rst(rst),
		.csrWriteEnable(csrWriteEnable),
		.csrReadEnable(csrReadEnable),
		.csrWriteAddress(csrWriteAddress),
		.csrReadAddress(csrReadAddress),
		.csrWriteData(csrWriteData),
		.csrReadData(mieReadData),
		.csrRequestOutput(mieRequestOutput),
		.value(mieValue));

	// mtvec
	// In theory this is a WARL register, so only legal values can be read,
	// This means that some bits should always be zero, but
	wire[31:0] mtvecValueValid = mtvecValue;//{ mtvecValue[31:4] , 2'b00, 1'b0, mtvecValue[0] };
	wire mtvecRequestOutput;
	wire[31:0] mtvecReadData;
	wire _unused_mtvecReadDataEnable;
	wire[31:0] mtvecWriteData;
	wire mtvecWriteDataEnable;
	CSR_DataRegister #(.ADDRESS(12'h305)) mtvec(
		.clk(clk),
		.rst(rst),
		.csrWriteEnable(csrWriteEnable),
		.csrReadEnable(csrReadEnable),
		.csrWriteAddress(csrWriteAddress),
		.csrReadAddress(csrReadAddress),
		.csrWriteData(csrWriteData),
		.csrReadData(mtvecReadData),
		.csrRequestOutput(mtvecRequestOutput),
		.readData(mtvecValueValid),
		.readDataEnable(_unused_mtvecReadDataEnable),
		.writeData(mtvecWriteData),
		.writeDataEnable(mtvecWriteDataEnable));

	always @(posedge clk) begin
		if (rst) mtvecValue <= 32'b0;
		else begin
			if (mtvecWriteDataEnable) mtvecValue <= mtvecWriteData;
		end
	end

	wire[31:0] trapVectorBase = { mtvecValueValid[31:2], 2'b00 };
	wire[1:0] trapVectorMode = mtvecValueValid[1:0];

	assign trapVector = (trapVectorMode == 2'b01) && isInterrupt ? trapVectorBase + {mcauseValue[29:0], 2'b00} : trapVectorBase;

	// mscratch
	wire[31:0] mscratchReadData;
	wire mscratchRequestOutput;
	wire[31:0] _unused_mscratchValue;
	CSR_ConfigurationRegister #(.ADDRESS(12'h340), .DEFAULT(32'b0)) mscratch (
		.clk(clk),
		.rst(rst),
		.csrWriteEnable(csrWriteEnable),
		.csrReadEnable(csrReadEnable),
		.csrWriteAddress(csrWriteAddress),
		.csrReadAddress(csrReadAddress),
		.csrWriteData(csrWriteData),
		.csrReadData(mscratchReadData),
		.csrRequestOutput(mscratchRequestOutput),
		.value(_unused_mscratchValue));

	// mepc
	wire[31:0] mepcReadData;
	wire mepcRequestOutput;
	wire _unused_mepcReadDataEnable;
	wire[31:0] mepcWriteData;
	wire mepcWriteDataEnable;
	CSR_DataRegister #(.ADDRESS(12'h341)) mepc(
		.clk(clk),
		.rst(rst),
		.csrWriteEnable(csrWriteEnable),
		.csrReadEnable(csrReadEnable),
		.csrWriteAddress(csrWriteAddress),
		.csrReadAddress(csrReadAddress),
		.csrWriteData(csrWriteData),
		.csrReadData(mepcReadData),
		.csrRequestOutput(mepcRequestOutput),
		.readData({ mepcValue[31:1], 1'b0 }),
		.readDataEnable(_unused_mepcReadDataEnable),
		.writeData(mepcWriteData),
		.writeDataEnable(mepcWriteDataEnable));

	always @(posedge clk) begin
		if (rst) mepcValue <= 32'b0;
		else begin
			if (isTrap) mepcValue <= programCounter;
			else if (mepcWriteDataEnable) mepcValue <= mepcWriteData;
		end
	end

	assign trapReturnVector = mepcValue;

	// mcause
	wire[31:0] mcauseReadData;
	wire mcauseRequestOutput;
	wire _unused_mcauseReadDataEnable;
	wire[31:0] mcauseWriteData;
	wire mcauseWriteDataEnable;
	CSR_DataRegister #(.ADDRESS(12'h342)) mcause(
		.clk(clk),
		.rst(rst),
		.csrWriteEnable(csrWriteEnable),
		.csrReadEnable(csrReadEnable),
		.csrWriteAddress(csrWriteAddress),
		.csrReadAddress(csrReadAddress),
		.csrWriteData(csrWriteData),
		.csrReadData(mcauseReadData),
		.csrRequestOutput(mcauseRequestOutput),
		.readData(mcauseValue),
		.readDataEnable(_unused_mcauseReadDataEnable),
		.writeData(mcauseWriteData),
		.writeDataEnable(mcauseWriteDataEnable));

	always @(posedge clk) begin
		if (rst) mcauseValue <= 32'b0;
		else begin
			if (isTrap) mcauseValue <= { isInterrupt, trapCause };
			else if (mcauseWriteDataEnable) mcauseValue <= mcauseWriteData;
		end
	end

	// mtval
	wire[31:0] mtvalReadData;
	wire mtvalRequestOutput;
	wire _unused_mtvalReadDataEnable;
	wire[31:0] mtvalWriteData;
	wire mtvalWriteDataEnable;
	CSR_DataRegister #(.ADDRESS(12'h343)) mtval(
		.clk(clk),
		.rst(rst),
		.csrWriteEnable(csrWriteEnable),
		.csrReadEnable(csrReadEnable),
		.csrWriteAddress(csrWriteAddress),
		.csrReadAddress(csrReadAddress),
		.csrWriteData(csrWriteData),
		.csrReadData(mtvalReadData),
		.csrRequestOutput(mtvalRequestOutput),
		.readData(mtvalValue),
		.readDataEnable(_unused_mtvalReadDataEnable),
		.writeData(mtvalWriteData),
		.writeDataEnable(mtvalWriteDataEnable));

	always @(posedge clk) begin
		if (rst) mtvalValue <= 32'b0;
		else begin
			if (isTrap) mtvalValue <= mtvalLoadValue;
			else if (mtvalWriteDataEnable) mtvalValue <= mtvalWriteData;
		end
	end

	// mip
	wire[31:0] mipReadData;
	wire mipRequestOutput;
	wire _unused_mipReadDataEnable;
	wire[31:0] mipWriteData;
	wire mipWriteDataEnable;
	CSR_DataRegister #(.ADDRESS(12'h344)) mip(
		.clk(clk),
		.rst(rst),
		.csrWriteEnable(csrWriteEnable),
		.csrReadEnable(csrReadEnable),
		.csrWriteAddress(csrWriteAddress),
		.csrReadAddress(csrReadAddress),
		.csrWriteData(csrWriteData),
		.csrReadData(mipReadData),
		.csrRequestOutput(mipRequestOutput),
		.readData(mipValue),
		.readDataEnable(_unused_mipReadDataEnable),
		.writeData(mipWriteData),
		.writeDataEnable(mipWriteDataEnable));

	always @(posedge clk) begin
		if (rst) mipValue <= 32'b0;
		else begin
			if (isTrap && isInterrupt) mipValue <= mipLoadValue;
			else if (mipWriteDataEnable) mipValue <= mipWriteData;
		end
	end

	assign requestOutput = mstatusRequestOutput
						|| mieRequestOutput
						|| mtvecRequestOutput
						|| mscratchRequestOutput
						|| mepcRequestOutput
						|| mcauseRequestOutput
						|| mtvalRequestOutput
						|| mipRequestOutput;

	always @(*) begin
		case (1'b1)
			mstatusRequestOutput: csrReadData = mstatusReadData;
			mieRequestOutput: csrReadData = mieReadData;
			mtvecRequestOutput: csrReadData = mtvecReadData;
			mscratchRequestOutput: csrReadData = mscratchReadData;
			mepcRequestOutput: csrReadData = mepcReadData;
			mcauseRequestOutput: csrReadData = mcauseReadData;
			mtvalRequestOutput: csrReadData = mtvalReadData;
			mipRequestOutput: csrReadData = mipReadData;
			default: csrReadData = 32'b0;
		endcase
	end

endmodule
