`default_nettype none

module BinaryTreePLRUCache #(
		parameter SIZE = 3
	)(
		input wire clk,
		input wire rst,

		input wire enable,
		input wire[SIZE-1:0] address,
		output wire [SIZE-1:0] lruAddress
	);

	localparam PARENT_SIZE = (SIZE - 1);
	localparam STATE_SIZE = (1 << PARENT_SIZE);

	reg[STATE_SIZE-1:0] state;

generate
	if (SIZE > 1) begin

		always @(posedge clk) begin
			if (rst) begin
				state <= {STATE_SIZE{1'b0}};
			end else if (enable) begin
				state[address[SIZE-1:1]] <= !address[0];
			end
		end

		wire[PARENT_SIZE-1:0] lruAddressParent;
		BinaryTreePLRUCache #(.SIZE(PARENT_SIZE)) parentLayer (
			.clk(clk),
			.rst(rst),
			.enable(enable),
			.address(address[SIZE-1:1]),
			.lruAddress(lruAddressParent));

		assign lruAddress = { lruAddressParent, state[lruAddressParent] };

	end else begin
		always @(posedge clk) begin
			if (rst) begin
				state <= 1'b0;
			end else if (enable) begin
				state <= !address;
			end
		end

		assign lruAddress = state;
	end
endgenerate

endmodule
