`default_nettype none

module MemoryPage #(
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
		input wire pageFlushing,

		// Bus access
		input wire busEnable,
		input wire busWriteEnable,
		input wire[ADDRESS_SIZE-1:0] busVirtualAddress,
		output wire[SRAM_ADDRESS_SIZE+1:0] busPhysicalAddress,

		// Cache control SRAM access
		output wire[SRAM_ADDRESS_SIZE+1:0] cacheSRAMAddress,

		output reg pageValid,
		output wire wordReady,

		// Page filling/flushing control
		input wire qspi_enable,
		input wire writeEnable,
		output wire[23:0] qspi_address,
		output wire qspi_changeAddress,
		output wire qspi_requestData,
		output wire qspi_storeData,
		input wire qspi_wordComplete,
		input wire qspi_initialised,
		input wire qspi_busy,

		// Status
		output wire pageAddressSet
	);

	localparam PAGE_ADDRESS_SIZE = (ADDRESS_SIZE - SRAM_ADDRESS_SIZE - 2);
	localparam PAGE_DATA_ADDRESS_SIZE = (SRAM_ADDRESS_SIZE - PAGE_INDEX_ADDRESS_SIZE);
	localparam PAGE_DATA_COUNT = (1 << PAGE_DATA_ADDRESS_SIZE);

	localparam STATE_EMPTY = 2'b00;
	localparam STATE_LOADING = 2'b01;
	localparam STATE_LOADED = 2'b10;
	localparam STATE_FLUSHING = 2'b11;

	reg[1:0] state = STATE_EMPTY;
	reg dataDirty;

	reg pendingAddressChange;

	wire[PAGE_INDEX_ADDRESS_SIZE-1:0] pageIndex = INDEX;

	reg[ADDRESS_SIZE-1:0] loadAddress;
	reg[ADDRESS_SIZE-PAGE_DATA_ADDRESS_SIZE-2-1:0] currentPageAddress;
	wire [ADDRESS_SIZE-1:0] nextLoadAddress = loadAddress + 4;

	reg[PAGE_DATA_ADDRESS_SIZE:0] cachedCount;
	wire[PAGE_DATA_ADDRESS_SIZE:0] nextCachedCount = cachedCount + 1;
	wire[PAGE_DATA_ADDRESS_SIZE:0] cachedCountFinal = 1 << PAGE_DATA_ADDRESS_SIZE;

	wire[ADDRESS_SIZE-PAGE_DATA_ADDRESS_SIZE-2-1:0] targetPageAddress = busVirtualAddress[ADDRESS_SIZE-1:PAGE_DATA_ADDRESS_SIZE+2];
	wire[PAGE_DATA_ADDRESS_SIZE-1:0] targetSubPageAddress = busVirtualAddress[PAGE_DATA_ADDRESS_SIZE+1:2];

	always @(*) begin
		if (automaticPaging) pageValid <= pageAddressSet && (targetPageAddress == currentPageAddress);
		else pageValid <= pageAddressSet && (targetPageAddress[PAGE_INDEX_ADDRESS_SIZE-1:0] == currentPageAddress[PAGE_INDEX_ADDRESS_SIZE-1:0]);
	end

	wire invalidPage = busEnable && automaticPaging && !pageValid;

	assign wordReady = qspi_enable && qspi_initialised && pageValid && pageSelected && (targetSubPageAddress < cachedCount) && (state != STATE_FLUSHING) && !invalidPage && !pendingAddressChange;

	reg[ADDRESS_SIZE-1:0] currentPageAddressLoadAddress;
	reg requireAddressChange;
	always @(*) begin
		currentPageAddressLoadAddress = {ADDRESS_SIZE{1'b0}};
		requireAddressChange = 1'b0;

		if (automaticPaging) begin
			if (busEnable && invalidPage && pageSelected) begin
				currentPageAddressLoadAddress = targetPageAddress;
				requireAddressChange = 1'b1;
			end
		end else begin
			if (manualPageAddressSet) begin
				currentPageAddressLoadAddress = { manualPageAddress, pageIndex };
				requireAddressChange = 1'b1;
			end
		end
	end

	assign qspi_address = { currentPageAddress[ADDRESS_SIZE-PAGE_DATA_ADDRESS_SIZE-2-1:0], {PAGE_DATA_ADDRESS_SIZE{1'b0}}, 2'b00 };
	assign qspi_changeAddress = pendingAddressChange && (pageLoading || pageFlushing) && !qspi_busy;

	reg pendingLoad;
	reg[23:0] pendingLoadAddress;

	always @(posedge clk) begin
		if (rst) begin
			state <= STATE_EMPTY;
			dataDirty <= 1'b0;
			loadAddress <= 24'b0;
			cachedCount <= {SRAM_ADDRESS_SIZE{1'b0}};
			pendingLoad <= 1'b0;
			pendingLoadAddress <= 24'b0;
		end else begin
			case(state)
				STATE_EMPTY: begin
					if (requireAddressChange) begin
						`ifdef DEBUG_CACHED_MEMORY
							$display("Changing base address of cached memory page 0x%h to 0x%h", pageIndex, qspi_address);
							$fflush();
						`endif

						state <= STATE_LOADING;
						dataDirty <= 1'b0;
						loadAddress <= qspi_address;
						cachedCount <= {SRAM_ADDRESS_SIZE{1'b0}};
					end
				end

				STATE_LOADING: begin
					if (automaticPagingChanged) begin
						state <= STATE_EMPTY;
					end else if (!pendingAddressChange && qspi_wordComplete && pageLoading) begin
						if (nextCachedCount == cachedCountFinal) begin
							state <= STATE_LOADED;
							cachedCount <= nextCachedCount;
						end else begin
							loadAddress <= nextLoadAddress;
							cachedCount <= nextCachedCount;
						end
					end

					if (busEnable && busWriteEnable) dataDirty <= 1'b1;
				end

				STATE_LOADED: begin
					if (automaticPagingChanged) begin
						if (writeEnable && dataDirty) begin 
							state <= STATE_FLUSHING;
							pendingLoad <= 1'b0;
						end else begin
							state <= STATE_EMPTY;
						end
					end else if (requireAddressChange) begin
						if (writeEnable && dataDirty) begin 
							state <= STATE_FLUSHING;
							pendingLoad <= 1'b1;
							pendingLoadAddress <= qspi_address;
						end	else begin
							`ifdef DEBUG_CACHED_MEMORY
								$display("Changing base address of cached memory page 0x%h to 0x%h", pageIndex, qspi_address);
								$fflush();
							`endif

							state <= STATE_LOADING;
							dataDirty <= 1'b0;
							loadAddress <= qspi_address;
							cachedCount <= {SRAM_ADDRESS_SIZE{1'b0}};
						end
					end else begin
						if (busEnable && busWriteEnable) dataDirty <= 1'b1;
					end
				end

				STATE_FLUSHING: begin
					if (!pendingAddressChange) begin
						if (qspi_wordComplete && pageFlushing) begin
							if (nextCachedCount == cachedCountFinal) begin
								if (pendingLoad) begin
									state <= STATE_LOADING;
									dataDirty <= 1'b0;
									pendingLoad <= 1'b0;
									loadAddress <= pendingLoadAddress;
									cachedCount <= {SRAM_ADDRESS_SIZE{1'b0}};
								end else begin
									state <= STATE_EMPTY;
									cachedCount <= nextCachedCount;
								end
							end else begin
								loadAddress <= nextLoadAddress;
								cachedCount <= nextCachedCount;
							end
						end
					end
				end

				default: state <= STATE_EMPTY;
			endcase
		end
	end

	assign pageAddressSet = state == STATE_LOADING || state == STATE_LOADED;
	assign qspi_storeData = state == STATE_FLUSHING;
	assign qspi_requestData = state == STATE_LOADING;

	always @(posedge clk) begin
		if (rst) begin
			currentPageAddress <= {ADDRESS_SIZE{1'b0}};
			pendingAddressChange <= 1'b0;
		end else if (qspi_changeAddress) begin
			pendingAddressChange <= 1'b0;
		end else if (requireAddressChange) begin
			currentPageAddress <= currentPageAddressLoadAddress;
			pendingAddressChange <= 1'b1;
		end else if (pendingAddressChange && automaticPagingChanged) begin
			pendingAddressChange <= 1'b0;
		end
	end

	assign busPhysicalAddress = { pageIndex, busVirtualAddress[PAGE_DATA_ADDRESS_SIZE+1:2], 2'b00};
	assign cacheSRAMAddress = { pageIndex, loadAddress[PAGE_DATA_ADDRESS_SIZE+1:2], 2'b00 };


endmodule
