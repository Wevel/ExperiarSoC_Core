`default_nettype none

module FlashPage #(
		parameter ADDRESS_SIZE = 24,
		parameter SRAM_ADDRESS_SIZE = 9,
		parameter PAGE_INDEX_ADDRESS_SIZE = 3,
		parameter INDEX = 0
	)(
		input wire clk,
		input wire rst,

		// Control
		input wire automaticPaging,
		input wire automaticPagingChanged,
		input wire manualPageAddressSet,
		input wire[PAGE_ADDRESS_SIZE-1:0] manualPageAddress,
		input wire pageSelected,
		input wire pageLoading,

		// Access address decoding
		input wire readEnable,
		input wire[ADDRESS_SIZE-1:0] readAddress,
		output reg pageValid,
		output wire wordReady,

		output wire[SRAM_ADDRESS_SIZE-1:0] sramReadAddress,
		output wire[SRAM_ADDRESS_SIZE-1:0] sramWriteAddress,

		// Page filling control
		input wire qspi_enable,
		output wire[ADDRESS_SIZE-1:0] qspi_address,
		output wire qspi_changeAddress,
		output reg qspi_requestData,
		input wire qspi_readDataValid,
		input wire qspi_initialised,
		input wire qspi_busy,

		// Status
		output reg pageAddressSet,
		output wire requestLoad
	);

	localparam PAGE_ADDRESS_SIZE = (ADDRESS_SIZE - SRAM_ADDRESS_SIZE - 2);
	localparam PAGE_DATA_ADDRESS_SIZE = (SRAM_ADDRESS_SIZE - PAGE_INDEX_ADDRESS_SIZE);
	localparam PAGE_DATA_COUNT = (1 << PAGE_DATA_ADDRESS_SIZE);

	reg pendingAddressChange;

	wire[PAGE_INDEX_ADDRESS_SIZE-1:0] pageIndex = INDEX;

	reg[ADDRESS_SIZE-1:0] loadAddress;
	reg[ADDRESS_SIZE-PAGE_DATA_ADDRESS_SIZE-2-1:0] currentPageAddress;

	reg[SRAM_ADDRESS_SIZE:0] cachedCount;
	wire[SRAM_ADDRESS_SIZE:0] nextCachedCount = cachedCount + 1;
	wire[SRAM_ADDRESS_SIZE:0] cachedCountFinal = 1 << PAGE_DATA_ADDRESS_SIZE;

	wire[ADDRESS_SIZE-PAGE_DATA_ADDRESS_SIZE-2-1:0] targetPageAddress = readAddress[ADDRESS_SIZE-1:PAGE_DATA_ADDRESS_SIZE+2];
	wire[PAGE_DATA_ADDRESS_SIZE-1:0] targetSubPageAddress = readAddress[PAGE_DATA_ADDRESS_SIZE+1:2];

	always @(*) begin
		if (automaticPaging) pageValid <= pageAddressSet && (targetPageAddress == currentPageAddress);
		else pageValid <= pageAddressSet && (targetPageAddress[PAGE_INDEX_ADDRESS_SIZE-1:0] == currentPageAddress[PAGE_INDEX_ADDRESS_SIZE-1:0]);
	end

	wire invalidPage = readEnable && automaticPaging && !pageValid;

	assign wordReady = qspi_enable && qspi_initialised && pageValid && pageSelected && (targetSubPageAddress < cachedCount) && !invalidPage && !pendingAddressChange;

	reg[ADDRESS_SIZE-1:0] currentPageAddressLoadAddress;
	reg requireAddressChange;
	always @(*) begin
		currentPageAddressLoadAddress = {ADDRESS_SIZE{1'b0}};
		requireAddressChange = 1'b0;

		if (automaticPaging) begin
			if (readEnable && invalidPage && pageSelected) begin
				currentPageAddressLoadAddress = targetPageAddress;
				requireAddressChange = 1'b1;
			end
		end else begin
			if (manualPageAddressSet) begin
				currentPageAddressLoadAddress = { manualPageAddress, pageIndex};
				requireAddressChange = 1'b1;
			end
		end
	end

	assign qspi_address = { currentPageAddress[ADDRESS_SIZE-PAGE_DATA_ADDRESS_SIZE-2-1:0], {PAGE_DATA_ADDRESS_SIZE{1'b0}}, 2'b00 };
	assign qspi_changeAddress = pendingAddressChange && pageLoading && !qspi_busy;

	always @(posedge clk) begin
		if (rst) begin
			currentPageAddress <= {ADDRESS_SIZE{1'b0}};
			pageAddressSet <= 1'b0;
			pendingAddressChange <= 1'b0;
		end else if (qspi_changeAddress) begin
			pendingAddressChange <= 1'b0;
		end else if (requireAddressChange) begin
			currentPageAddress <= currentPageAddressLoadAddress;
			pageAddressSet <= 1'b1;
			pendingAddressChange <= 1'b1;
		end else if (pendingAddressChange && automaticPagingChanged) begin
			pageAddressSet <= 1'b0;
			pendingAddressChange <= 1'b0;
		end
	end

	// QSPI interface
	always @(posedge clk) begin
		if (rst) begin
			loadAddress <= 32'b0;
			cachedCount <= {SRAM_ADDRESS_SIZE{1'b0}};
			qspi_requestData <= 1'b0;
		end	else if (qspi_changeAddress) begin
			$display("Changing base address of flash page 0x%h to 0x%h", pageIndex, qspi_address);
			loadAddress <= qspi_address;
			cachedCount <= {SRAM_ADDRESS_SIZE{1'b0}};
			qspi_requestData <= 1'b1;
		end else if (qspi_requestData && qspi_readDataValid && pageLoading) begin
			loadAddress <= loadAddress + 4;
			cachedCount <= nextCachedCount;
			qspi_requestData <= (nextCachedCount != cachedCountFinal) && pageAddressSet && !pendingAddressChange;
		end
	end

	assign sramReadAddress = { pageIndex, readAddress[PAGE_DATA_ADDRESS_SIZE+1:2] };
	assign sramWriteAddress = { pageIndex, loadAddress[PAGE_DATA_ADDRESS_SIZE+1:2] };

	assign requestLoad = qspi_requestData || pendingAddressChange;

endmodule
