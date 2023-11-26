`default_nettype none

module MemoryCache #(
		parameter ADDRESS_SIZE = 24,
		parameter SRAM_ADDRESS_SIZE = 9,
		parameter PAGE_INDEX_ADDRESS_SIZE = 3
	)(
		input wire clk,
		input wire rst,

		// Config
		input wire writeEnable,
		input wire automaticPaging,
		input wire manualPageAddressSet,
		input wire[PAGE_ADDRESS_SIZE-1:0] manualPageAddress,

		// Bus access
		input wire busEnable,
		input wire busWriteEnable,
		input wire[ADDRESS_SIZE-1:0] busVirtualAddress,
		output wire[SRAM_ADDRESS_SIZE+1:0] busPhysicalAddress,
		output reg busBusy,

		// Cache control SRAM access
		output wire cacheSRAMEnable,
		output wire cacheSRAMWriteEnable,
		output wire[SRAM_ADDRESS_SIZE+1:0] cacheSRAMAddress,
		input wire cacheSRAMBusy,

		// Page filling control
		input wire qspi_enable,
		output wire qspi_interruptOperation,
		output wire[23:0] qspi_address,
		output wire qspi_changeAddress,
		output wire qspi_requestData,
		output wire qspi_storeData,
		input wire qspi_wordComplete,
		input wire qspi_initialised,
		input wire qspi_busy,

		// Status
		output wire[PAGE_COUNT-1:0] pageAddressSet,
		output wire[PAGE_COUNT-1:0] pageRequestLoad,
		output wire[PAGE_COUNT-1:0] pageRequestFlush
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
	wire pageAccess = (pageHit && !busBusy) || (pageMiss && qspi_changeAddress);
	
	reg[PAGE_INDEX_ADDRESS_SIZE-1:0] activePageIndex;
	reg activePage;

	reg[PAGE_INDEX_ADDRESS_SIZE-1:0] requestPageIndex;
	reg flushRequested;
	reg loadRequested;

	wire[PAGE_INDEX_ADDRESS_SIZE-1:0] evictionPageIndex;
	
	reg[PAGE_INDEX_ADDRESS_SIZE-1:0] selectedPageIndex;
	reg pageSelected;
	wire switchPageSelected;

	reg[PAGE_INDEX_ADDRESS_SIZE-1:0] pageMoveIndex;
	reg pageFlushing;
	reg pageLoading;
	wire pageMoving = pageFlushing || pageLoading;
	wire switchPageMove;

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
	wire[PAGE_COUNT-1:0] page_qspi_storeData;
	wire[SRAM_ADDRESS_SIZE+1:0] page_busPhysicalAddress[PAGE_COUNT-1:0];
	wire[SRAM_ADDRESS_SIZE+1:0] page_cacheSRAMAddress[PAGE_COUNT-1:0];

	wire busEnableValid = busEnable && !(busWriteEnable && !writeEnable);

	genvar generatePageIndex;
	generate
		for (generatePageIndex = 0; generatePageIndex < PAGE_COUNT; generatePageIndex = generatePageIndex + 1) begin
			MemoryPage #(
				.ADDRESS_SIZE(ADDRESS_SIZE),
				.SRAM_ADDRESS_SIZE(SRAM_ADDRESS_SIZE),
				.PAGE_INDEX_ADDRESS_SIZE(PAGE_INDEX_ADDRESS_SIZE),
				.INDEX(generatePageIndex)
			) memoryPage (
				.clk(clk),
				.rst(rst),
				.automaticPaging(automaticPaging),
				.automaticPagingChanged(automaticPagingChanged),
				.manualPageAddressSet(manualPageAddressSet),
				.manualPageAddress(manualPageAddress),
				.pageSelected(pageSelected && !switchPageSelected && (selectedPageIndex == generatePageIndex)),
				.pageLoading(pageLoading && !switchPageMove && (pageMoveIndex == generatePageIndex)),
				.pageFlushing(pageFlushing && !switchPageMove && (pageMoveIndex == generatePageIndex)),
				.busEnable(busEnableValid),
				.busWriteEnable(busWriteEnable),
				.busVirtualAddress(busVirtualAddress),
				.busPhysicalAddress(page_busPhysicalAddress[generatePageIndex]),
				.cacheSRAMAddress(page_cacheSRAMAddress[generatePageIndex]),
				.cacheSRAMBusy(cacheSRAMBusy),
				.pageValid(pageValid[generatePageIndex]),
				.wordReady(wordReady[generatePageIndex]),
				.qspi_enable(qspi_enable),
				.writeEnable(writeEnable),
				.qspi_address(page_qspi_address[generatePageIndex]),
				.qspi_changeAddress(page_qspi_changeAddress[generatePageIndex]),
				.qspi_requestData(page_qspi_requestData[generatePageIndex]),
				.qspi_storeData(page_qspi_storeData[generatePageIndex]),
				.qspi_wordComplete(qspi_wordComplete),
				.qspi_initialised(qspi_initialised),
				.qspi_busy(qspi_busy),
				.pageAddressSet(pageAddressSet[generatePageIndex]));
		end
	endgenerate

	assign pageRequestLoad = page_qspi_requestData;
	assign pageRequestFlush = page_qspi_storeData;

	wire anyPageValid = |pageValid;
	assign pageHit = busEnableValid && anyPageValid;
	assign pageMiss = busEnableValid && !anyPageValid;

	integer generatePageValidIndex;
	always @(*) begin
		activePageIndex = {PAGE_INDEX_ADDRESS_SIZE{1'b0}};
		activePage = 1'b0;

		requestPageIndex = {PAGE_INDEX_ADDRESS_SIZE{1'b0}};
		loadRequested = 1'b0;
		flushRequested = 1'b0;

		if (busEnable) begin
			activePageIndex = evictionPageIndex;
			activePage = 1'b1;
		end

		for (generatePageValidIndex = PAGE_COUNT - 1; generatePageValidIndex >= 0; generatePageValidIndex = generatePageValidIndex - 1) begin
			if (pageValid[generatePageValidIndex]) begin
				activePageIndex = generatePageValidIndex;
				activePage = 1'b1;
			end

			if (pageRequestFlush[generatePageValidIndex] && writeEnable) begin
				requestPageIndex = generatePageValidIndex;
				loadRequested = 1'b0;
				flushRequested = 1'b1;
			end else if (pageRequestLoad[generatePageValidIndex]) begin
				requestPageIndex = generatePageValidIndex;
				loadRequested = 1'b1;
				flushRequested <= 1'b0;
			end

			
		end
	
		if (pageSelected && pageRequestFlush[selectedPageIndex] && writeEnable) begin
			requestPageIndex = selectedPageIndex;
			loadRequested = 1'b0;
			flushRequested <= 1'b1;
		end else if (pageSelected && pageRequestLoad[selectedPageIndex]) begin
			requestPageIndex = selectedPageIndex;
			loadRequested = 1'b1;
			flushRequested <= 1'b0;
		end
	end

	// Remember that the read data is only valid on the next clock cycle
	always @(posedge clk) begin
		if (rst) busBusy <= 1'b1;
		else if (busEnableValid && wordReady[selectedPageIndex]) busBusy <= 1'b0;
		else busBusy <= 1'b1;
	end

	assign switchPageSelected = (busEnableValid && activePage && (activePageIndex != selectedPageIndex)) || manualPageAddressSet || automaticPagingChanged;

	always @(posedge clk) begin
		if (rst) begin
			pageSelected <= 1'b0;
			selectedPageIndex <= {PAGE_INDEX_ADDRESS_SIZE{1'b0}};
		end else begin
			if (pageSelected) begin
				if (switchPageSelected) pageSelected <= 1'b0;
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

	assign switchPageMove = (pageLoading && !pageRequestLoad[pageMoveIndex]) || (pageFlushing && !pageRequestFlush[pageMoveIndex]) || manualPageAddressSet || automaticPagingChanged;

	always @(posedge clk) begin
		if (rst) begin
			pageFlushing <= 1'b0;
			pageLoading <= 1'b0;
			pageMoveIndex <= {PAGE_INDEX_ADDRESS_SIZE{1'b0}};
		end else begin
			if (pageMoving) begin
				if (switchPageMove) pageLoading <= 1'b0;
			end else begin
				if (flushRequested && writeEnable) begin
					pageFlushing <= 1'b1;
					pageLoading <= 1'b0;
				end else if (loadRequested) begin
					pageFlushing <= 1'b0;
					pageLoading <= 1'b1;
					pageMoveIndex <= requestPageIndex;
				end else begin
					pageFlushing <= 1'b0;
					pageLoading <= 1'b0;
				end
			end
		end
	end

	//assign sramReadEnable = busEnableValid && wordReady[selectedPageIndex];
	
	assign cacheSRAMEnable = (qspi_requestData || qspi_storeData) && qspi_wordComplete;
	assign cacheSRAMWriteEnable = (qspi_requestData && !qspi_storeData) && qspi_wordComplete;
	assign busPhysicalAddress = page_busPhysicalAddress[selectedPageIndex];
	assign cacheSRAMAddress = page_cacheSRAMAddress[pageMoveIndex];

	assign qspi_interruptOperation = manualPageAddressSet || automaticPagingChanged || switchPageMove;
	assign qspi_address = page_qspi_address[pageMoveIndex];
	assign qspi_changeAddress = pageMoving && page_qspi_changeAddress[pageMoveIndex];
	assign qspi_requestData = page_qspi_requestData[pageMoveIndex];
	assign qspi_storeData = page_qspi_storeData[pageMoveIndex];
	
endmodule
