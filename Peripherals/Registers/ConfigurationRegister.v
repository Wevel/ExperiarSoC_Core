`default_nettype none

`ifndef CONFIGURATION_REGISTER_V
`define CONFIGURATION_REGISTER_V

module ConfigurationRegister #(
		parameter WIDTH = 32,
		parameter ADDRESS = 12'b0,
		parameter DEFAULT = 32'b0
	)(
		input wire clk,
		input wire rst,

		// Peripheral Bus
		input wire enable,
		input wire peripheralBus_we,
		input wire peripheralBus_oe,
		input wire[11:0] peripheralBus_address,
		input wire[3:0] peripheralBus_byteSelect,
		output wire[31:0] peripheralBus_dataRead,
		input wire[31:0] peripheralBus_dataWrite,
		output wire requestOutput,

		output wire[WIDTH-1:0] currentValue
	);

	wire[31:0] dataMask = {
		peripheralBus_byteSelect[3] ? 8'hFF : 8'h00,
		peripheralBus_byteSelect[2] ? 8'hFF : 8'h00,
		peripheralBus_byteSelect[1] ? 8'hFF : 8'h00,
		peripheralBus_byteSelect[0] ? 8'hFF : 8'h00
	};

	reg[WIDTH-1:0] registerValue;
	wire[WIDTH-1:0] maskedWriteData = (peripheralBus_dataWrite[WIDTH-1:0] & dataMask[WIDTH-1:0]) | (registerValue & ~dataMask[WIDTH-1:0]);

	generate
		if (WIDTH < 32) wire[32-WIDTH-1:0] _unused_zeroPadding = peripheralBus_dataWrite[31:WIDTH];
	endgenerate

	wire registerSelect = enable && (peripheralBus_address == ADDRESS[11:0]);
	wire we = registerSelect && peripheralBus_we && !peripheralBus_oe;
	wire oe = registerSelect && peripheralBus_oe && !peripheralBus_we;

	always @(posedge clk) begin
		if (rst) begin
			registerValue <= DEFAULT;
		end else begin
			if (we) registerValue <= maskedWriteData;
		end
	end

	wire[31:0] baseReadData;
	generate
		if (WIDTH == 32) begin
			assign baseReadData = registerValue;
		end else begin
			wire[32-WIDTH-1:0] zeroPadding = 'b0;
			assign baseReadData = { zeroPadding, registerValue };
		end
	endgenerate

	assign peripheralBus_dataRead = oe ? baseReadData & dataMask : 32'b0;
	assign requestOutput = oe;
	assign currentValue = registerValue;

endmodule

`endif
