`default_nettype none

module FlashCache #(
		parameter ADDRESS_SIZE = 24,
		parameter SRAM_ADDRESS_SIZE = 9,
		parameter PAGE_INDEX_ADDRESS_SIZE = 3
	)(
		input wire clk,
		input wire rst,

		// Config
		input wire automaticPaging,
		input wire manualPageAddressSet,
		input wire[PAGE_ADDRESS_SIZE-1:0] manualPageAddress,

		// Access address decoding
		input wire readEnable,
		input wire[ADDRESS_SIZE-1:0] readAddress,
		output reg readReady,

		// SRAM access
		output wire sramReadEnable,
		output wire sramWriteEnable,
		output wire[SRAM_ADDRESS_SIZE-1:0] sramReadAddress,
		output wire[SRAM_ADDRESS_SIZE-1:0] sramWriteAddress,

		// Page filling control
		input wire qspi_enable,
		output wire[23:0] qspi_address,
		output wire qspi_changeAddress,
		output wire qspi_requestData,
		input wire qspi_readDataValid,
		input wire qspi_initialised,
		input wire qspi_busy,

		// Status
		output wire[PAGE_COUNT-1:0] pageAddressSet,
		output wire[PAGE_COUNT-1:0] pageRequestLoad
	);

	localparam PAGE_ADDRESS_SIZE = (ADDRESS_SIZE - SRAM_ADDRESS_SIZE - 2);
	localparam PAGE_DATA_ADDRESS_SIZE = (SRAM_ADDRESS_SIZE - PAGE_INDEX_ADDRESS_SIZE);
	localparam PAGE_DATA_COUNT = (1 << PAGE_DATA_ADDRESS_SIZE);
	localparam PAGE_COUNT = (1 << PAGE_INDEX_ADDRESS_SIZE);

	reg lastAutomaticPaging;
	always @(posedge clk) begin
		if (rst) lastAutomaticPaging <= 1'b0;
		else lastAutomaticPaging <= automaticPaging;
	end

	wire automaticPagingChanged = automaticPaging != lastAutomaticPaging;

	wire pageHit;
	wire pageMiss;
	wire pageAccess = (pageHit && readReady) || (pageMiss && qspi_changeAddress);
	
	reg[PAGE_INDEX_ADDRESS_SIZE-1:0] activePageIndex;
	reg activePage;

	reg[PAGE_INDEX_ADDRESS_SIZE-1:0] requestLoadingPageIndex;
	reg loadRequested;

	wire[PAGE_INDEX_ADDRESS_SIZE-1:0] evictionPageIndex;
	
	reg[PAGE_INDEX_ADDRESS_SIZE-1:0] selectedPageIndex;
	reg pageSelected;

	reg[PAGE_INDEX_ADDRESS_SIZE-1:0] loadingPageIndex;
	reg pageLoading;

	//----------------------------------------------------------------------------------------------------//
	// Page index eviction control
	// This can use different methods to change how page eviction is handled
	// However, the same signals must be used to control the page eviction
	//----------------------------------------------------------------------------------------------------//
	BinaryTreePLRUCache #(.SIZE(PAGE_INDEX_ADDRESS_SIZE)) binaryTree (
		.clk(clk),
		.rst(rst),
		.enable(pageAccess),
		.address(activePageIndex),
		.lruAddress(evictionPageIndex));
	//----------------------------------------------------------------------------------------------------//		

	wire[PAGE_COUNT-1:0] pageValid;
	wire[PAGE_COUNT-1:0] wordReady;

	wire[23:0] page_qspi_address[PAGE_COUNT-1:0];
	wire[PAGE_COUNT-1:0] page_qspi_changeAddress;
	wire[PAGE_COUNT-1:0] page_qspi_requestData;
	wire[SRAM_ADDRESS_SIZE-1:0] page_sramReadAddress[PAGE_COUNT-1:0];
	wire[SRAM_ADDRESS_SIZE-1:0] page_sramWriteAddress[PAGE_COUNT-1:0];

	genvar generatePageIndex;
	generate
		for (generatePageIndex = 0; generatePageIndex < PAGE_COUNT; generatePageIndex = generatePageIndex + 1) begin
			FlashPage #(
				.ADDRESS_SIZE(ADDRESS_SIZE),
				.SRAM_ADDRESS_SIZE(SRAM_ADDRESS_SIZE),
				.PAGE_INDEX_ADDRESS_SIZE(PAGE_INDEX_ADDRESS_SIZE),
				.INDEX(generatePageIndex)
			) flashPage (
				.clk(clk),
				.rst(rst),
				.automaticPaging(automaticPaging),
				.automaticPagingChanged(automaticPagingChanged),
				.manualPageAddressSet(manualPageAddressSet),
				.manualPageAddress(manualPageAddress),
				.pageSelected(pageSelected && (selectedPageIndex == generatePageIndex)),
				.pageLoading(pageLoading && (loadingPageIndex == generatePageIndex)),
				.readEnable(readEnable),
				.readAddress(readAddress),
				.pageValid(pageValid[generatePageIndex]),
				.wordReady(wordReady[generatePageIndex]),
				.sramReadAddress(page_sramReadAddress[generatePageIndex]),
				.sramWriteAddress(page_sramWriteAddress[generatePageIndex]),
				.qspi_enable(qspi_enable),
				.qspi_address(page_qspi_address[generatePageIndex]),
				.qspi_changeAddress(page_qspi_changeAddress[generatePageIndex]),
				.qspi_requestData(page_qspi_requestData[generatePageIndex]),
				.qspi_readDataValid(qspi_readDataValid),
				.qspi_initialised(qspi_initialised),
				.qspi_busy(qspi_busy),
				.pageAddressSet(pageAddressSet[generatePageIndex]),
				.requestLoad(pageRequestLoad[generatePageIndex]));
		end
	endgenerate

	wire anyPageValid = |pageValid;
	assign pageHit = readEnable && anyPageValid;
	assign pageMiss = readEnable && !anyPageValid;

	integer generatePageValidIndex;
	always @(*) begin
		activePageIndex = {PAGE_INDEX_ADDRESS_SIZE{1'b0}};
		activePage = 1'b0;

		requestLoadingPageIndex = {PAGE_INDEX_ADDRESS_SIZE{1'b0}};
		loadRequested = 1'b0;

		for (generatePageValidIndex = PAGE_COUNT - 1; generatePageValidIndex >= 0; generatePageValidIndex = generatePageValidIndex - 1) begin
			if (pageValid[generatePageValidIndex]) begin
				activePageIndex = generatePageValidIndex;
				activePage = 1'b1;
			end
			
			if (pageRequestLoad[generatePageValidIndex]) begin
				requestLoadingPageIndex = generatePageValidIndex;
				loadRequested = 1'b1;
			end
		end

		if (pageSelected && pageRequestLoad[selectedPageIndex]) begin
			requestLoadingPageIndex = selectedPageIndex;
			loadRequested = 1'b1;
		end
	end

	// Remember that the read data is only valid on the next clock cycle
	always @(posedge clk) begin
		if (rst) readReady <= 1'b0;
		else if (readEnable && wordReady[selectedPageIndex]) readReady <= 1'b1;
		else readReady <= 1'b0;
	end

	always @(posedge clk) begin
		if (rst) begin
			pageSelected <= 1'b0;
			selectedPageIndex <= {PAGE_INDEX_ADDRESS_SIZE{1'b0}};
		end else begin
			if (pageSelected) begin
				if ((readEnable && activePage && (activePageIndex != selectedPageIndex)) || manualPageAddressSet || automaticPagingChanged) pageSelected <= 1'b0;
			end else begin
				if (pageHit && activePage) begin
					pageSelected <= 1'b1;
					selectedPageIndex <= activePageIndex;
				end else if (pageMiss && automaticPaging) begin
					pageSelected <= 1'b1;
					selectedPageIndex <= evictionPageIndex;
				end else begin
					pageSelected <= 1'b0;
				end
			end
		end
	end

	always @(posedge clk) begin
		if (rst) begin
			pageLoading <= 1'b0;
			loadingPageIndex <= {PAGE_INDEX_ADDRESS_SIZE{1'b0}};
		end else begin
			if (pageLoading) begin
				if (!pageRequestLoad[loadingPageIndex] || manualPageAddressSet) pageLoading <= 1'b0;
			end else begin
				if (loadRequested) begin
					pageLoading <= 1'b1;
					loadingPageIndex <= requestLoadingPageIndex;
				end else begin
					pageLoading <= 1'b0;
				end
			end
		end
	end

	assign sramReadEnable = readEnable && wordReady[selectedPageIndex];
	assign sramWriteEnable = qspi_requestData && qspi_readDataValid;
	assign sramReadAddress = page_sramReadAddress[selectedPageIndex];
	assign sramWriteAddress = page_sramWriteAddress[loadingPageIndex];

	assign qspi_address = page_qspi_address[loadingPageIndex];
	assign qspi_changeAddress = page_qspi_changeAddress[loadingPageIndex];
	assign qspi_requestData = page_qspi_requestData[loadingPageIndex];
	
endmodule
