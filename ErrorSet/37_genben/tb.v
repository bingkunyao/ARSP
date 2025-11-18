 
module a23_wishbone_ref
(
input                       i_clk,
input                       i_select,
input       [31:0]          i_write_data,
input                       i_write_enable,
input       [3:0]           i_byte_enable,    
input                       i_data_access,
input                       i_exclusive,      
input       [31:0]          i_address,
output                      o_stall_ref,
input                       i_cache_req,
output reg  [31:0]          o_wb_adr_ref = 'd0,
output reg  [3:0]           o_wb_sel_ref = 'd0,
output reg                  o_wb_we_ref  = 'd0,
input       [31:0]          i_wb_dat,
output reg  [31:0]          o_wb_dat_ref = 'd0,
output reg                  o_wb_cyc_ref = 'd0,
output reg                  o_wb_stb_ref = 'd0,
input                       i_wb_ack,
input                       i_wb_err
);
localparam [3:0] WB_IDLE            = 3'd0,
                 WB_BURST1          = 3'd1,
                 WB_BURST2          = 3'd2,
                 WB_BURST3          = 3'd3,
                 WB_WAIT_ACK        = 3'd4;
reg     [2:0]               wishbone_st = WB_IDLE;
wire                        core_read_request;
wire                        core_write_request;
wire                        cache_read_request;
wire                        cache_write_request;
wire                        start_access;
reg                         servicing_cache = 'd0;
wire    [3:0]               byte_enable;
reg                         exclusive_access = 'd0;
wire                        read_ack;
wire                        wait_write_ack;
wire                        wb_wait;
reg     [31:0]              wbuf_addr_r = 'd0;
reg     [3:0]               wbuf_sel_r  = 'd0;
reg                         wbuf_busy_r = 'd0;
assign read_ack             = !o_wb_we_ref && i_wb_ack;
assign o_stall_ref              = ( core_read_request  && !read_ack )       || 
                              ( core_read_request  && servicing_cache ) ||
                              ( core_write_request && servicing_cache ) ||
                              ( core_write_request && wishbone_st == WB_WAIT_ACK) ||
                              ( cache_write_request && wishbone_st == WB_WAIT_ACK) ||
                              wbuf_busy_r;
assign core_read_request    = i_select && !i_write_enable;
assign core_write_request   = i_select &&  i_write_enable;
assign cache_read_request   = i_cache_req && !i_write_enable;
assign cache_write_request  = i_cache_req &&  i_write_enable;
assign wb_wait              = o_wb_stb_ref && !i_wb_ack;
assign start_access         = (core_read_request || core_write_request || i_cache_req) && !wb_wait ;
assign byte_enable          = wbuf_busy_r                                   ? wbuf_sel_r    :
                              ( core_write_request || cache_write_request ) ? i_byte_enable : 
                                                                              4'hf          ;
always @( posedge i_clk )
    if ( wb_wait && !wbuf_busy_r && (core_write_request || cache_write_request) )
        begin
        wbuf_addr_r <= i_address;
        wbuf_sel_r  <= i_byte_enable;
        wbuf_busy_r <= 1'd1;
        end
    else if (!o_wb_stb_ref)
        wbuf_busy_r <= 1'd0;
always @( posedge i_clk )
    if ( start_access )
        o_wb_dat_ref <= i_write_data;
assign wait_write_ack = o_wb_stb_ref && o_wb_we_ref && !i_wb_ack;
always @( posedge i_clk )
    case ( wishbone_st )
        WB_IDLE :
            begin 
            if ( start_access )
                begin
                o_wb_stb_ref            <= 1'd1; 
                o_wb_cyc_ref            <= 1'd1; 
                o_wb_sel_ref            <= byte_enable;
                end
            else if ( !wait_write_ack )
                begin
                o_wb_stb_ref            <= 1'd0;
                o_wb_cyc_ref            <= exclusive_access;
                end
            servicing_cache <= cache_read_request && !wait_write_ack;
            if ( wait_write_ack )
                begin
                wishbone_st      <= WB_WAIT_ACK;
                end  
            else if ( cache_read_request )
                begin
                wishbone_st         <= WB_BURST1;
                exclusive_access    <= 1'd0;
                end                    
            else if ( core_read_request )
                begin
                wishbone_st         <= WB_WAIT_ACK;
                exclusive_access    <= i_exclusive;
                end                    
            else if ( core_write_request )
                exclusive_access <= i_exclusive;
            if ( start_access )
                begin
                if (wbuf_busy_r)
                    begin
                    o_wb_we_ref              <= 1'd1;
                    o_wb_adr_ref[31:2]       <= wbuf_addr_r[31:2];
                    end
                else
                    begin
                    o_wb_we_ref              <= core_write_request || cache_write_request;
                    o_wb_adr_ref[31:2]       <= i_address[31:2];
                    end
                o_wb_adr_ref[1:0]        <= byte_enable == 4'b0001 ? 2'd0 :
                                        byte_enable == 4'b0010 ? 2'd1 :
                                        byte_enable == 4'b0100 ? 2'd2 :
                                        byte_enable == 4'b1000 ? 2'd3 :
                                        byte_enable == 4'b0011 ? 2'd0 :
                                        byte_enable == 4'b1100 ? 2'd2 :
                                                                 2'd0 ;
                end
            end
        WB_BURST1:  
            if ( i_wb_ack )
                begin
                o_wb_adr_ref[3:2]   <= o_wb_adr_ref[3:2] + 1'd1;
                wishbone_st     <= WB_BURST2;
                end
        WB_BURST2:  
            if ( i_wb_ack )
                begin
                o_wb_adr_ref[3:2]   <= o_wb_adr_ref[3:2] + 1'd1;
                wishbone_st     <= WB_BURST3;
                end
        WB_BURST3:  
            if ( i_wb_ack )
                begin
                o_wb_adr_ref[3:2]   <= o_wb_adr_ref[3:2] + 1'd1;
                wishbone_st     <= WB_WAIT_ACK;
                end
        WB_WAIT_ACK:   
            if ( i_wb_ack )
                begin
                wishbone_st         <= WB_IDLE;
                o_wb_stb_ref            <= 1'd0; 
                o_wb_cyc_ref            <= exclusive_access; 
                o_wb_we_ref             <= 1'd0;
                servicing_cache     <= 1'd0;
                end
    endcase
wire    [(14*8)-1:0]   xAS_STATE;
assign xAS_STATE  = wishbone_st == WB_IDLE       ? "WB_IDLE"       :
                    wishbone_st == WB_BURST1     ? "WB_BURST1"     :
                    wishbone_st == WB_BURST2     ? "WB_BURST2"     :
                    wishbone_st == WB_BURST3     ? "WB_BURST3"     :
                    wishbone_st == WB_WAIT_ACK   ? "WB_WAIT_ACK"   :
                                                      "UNKNOWN"       ;
endmodule




 module tb;

  // Inputs
  reg i_clk;
  reg i_select;
  reg [31:0] i_write_data;
  reg i_write_enable;
  reg [3:0] i_byte_enable;
  reg i_data_access;
  reg i_exclusive;
  reg [31:0] i_address;
  reg i_cache_req;
  reg [31:0] i_wb_dat;
  reg i_wb_ack;
  reg i_wb_err;

  // Outputs
  wire o_stall_ref, o_stall_dut;
  wire [31:0] o_wb_adr_ref, o_wb_adr_dut;
  wire [3:0] o_wb_sel_ref, o_wb_sel_dut;
  wire o_wb_we_ref, o_wb_we_dut;
  wire [31:0] o_wb_dat_ref, o_wb_dat_dut;
  wire o_wb_cyc_ref, o_wb_cyc_dut;
  wire o_wb_stb_ref, o_wb_stb_dut;


  wire match;

  integer total_tests = 0;
	integer failed_tests = 0;

  assign match = ({o_stall_ref, o_wb_adr_ref, o_wb_sel_ref, o_wb_we_ref, o_wb_dat_ref, o_wb_cyc_ref, o_wb_stb_ref} === ({o_stall_dut, o_wb_adr_dut, o_wb_sel_dut, o_wb_we_dut, o_wb_dat_dut, o_wb_cyc_dut, o_wb_stb_dut} ^ {o_stall_ref, o_wb_adr_ref, o_wb_sel_ref, o_wb_we_ref, o_wb_dat_ref, o_wb_cyc_ref, o_wb_stb_ref} ^ {o_stall_ref, o_wb_adr_ref, o_wb_sel_ref, o_wb_we_ref, o_wb_dat_ref, o_wb_cyc_ref, o_wb_stb_ref}));

  // Instantiate the Unit Under Test (UUT)
  a23_wishbone_ref ref_model (
    .i_clk(i_clk),
    .i_select(i_select),
    .i_write_data(i_write_data),
    .i_write_enable(i_write_enable),
    .i_byte_enable(i_byte_enable),
    .i_data_access(i_data_access),
    .i_exclusive(i_exclusive),
    .i_address(i_address),
    .o_stall_ref(o_stall_ref),
    .i_cache_req(i_cache_req),
    .o_wb_adr_ref(o_wb_adr_ref),
    .o_wb_sel_ref(o_wb_sel_ref),
    .o_wb_we_ref(o_wb_we_ref),
    .i_wb_dat(i_wb_dat),
    .o_wb_dat_ref(o_wb_dat_ref),
    .o_wb_cyc_ref(o_wb_cyc_ref),
    .o_wb_stb_ref(o_wb_stb_ref),
    .i_wb_ack(i_wb_ack),
    .i_wb_err(i_wb_err)
  );

  a23_wishbone uut (
    .i_clk(i_clk),
    .i_select(i_select),
    .i_write_data(i_write_data),
    .i_write_enable(i_write_enable),
    .i_byte_enable(i_byte_enable),
    .i_data_access(i_data_access),
    .i_exclusive(i_exclusive),
    .i_address(i_address),
    .o_stall(o_stall_dut),
    .i_cache_req(i_cache_req),
    .o_wb_adr(o_wb_adr_dut),
    .o_wb_sel(o_wb_sel_dut),
    .o_wb_we(o_wb_we_dut),
    .i_wb_dat(i_wb_dat),
    .o_wb_dat(o_wb_dat_dut),
    .o_wb_cyc(o_wb_cyc_dut),
    .o_wb_stb(o_wb_stb_dut),
    .i_wb_ack(i_wb_ack),
    .i_wb_err(i_wb_err)
  );

  // Clock generation
  always #5 i_clk = ~i_clk;

  initial begin
    // Initialize Inputs
    i_clk = 0;
    i_select = 0;
    i_write_data = 0;
    i_write_enable = 0;
    i_byte_enable = 0;
    i_data_access = 0;
    i_exclusive = 0;
    i_address = 0;
    i_cache_req = 0;
    i_wb_dat = 0;
    i_wb_ack = 0;
    i_wb_err = 0;

    // Wait for global reset
    #10;

    // Test Case 1: Write request
    i_select = 1;
    i_write_enable = 1;
    i_write_data = 32'hA5A5A5A5;
    i_byte_enable = 4'b1111;
    i_address = 32'hA5A5A5A5;
    #10;
    i_wb_ack = 1;
    #10;
    compare();
    i_wb_ack = 0;
    i_select = 0;
    #10;
    compare();

    // Test Case 2: Read request
    i_select = 1;
    i_write_enable = 0;
    i_address = 32'h5A5A5A5A;
    #10;
    i_wb_ack = 1;
    i_wb_dat = 32'h5A5A5A5A;
    #10;
    compare();
    i_wb_ack = 0;
    i_select = 0;
    #10;
    compare();

    // Test Case 3: Cache write request
    i_cache_req = 1;
    i_write_enable = 1;
    i_write_data = 32'hB5B5B5B5;
    i_byte_enable = 4'b1111;
    i_address = 32'h00000000;
    #10;
    compare();
    i_wb_ack = 1;
    #10;
    compare();
    i_wb_ack = 0;
    i_cache_req = 0;
    #10;
    compare();

    // Test Case 4: Cache read request
    i_cache_req = 1;
    i_write_enable = 0;
    i_address = 32'hFFFFFFFF;
    #10;
    compare();
    i_wb_ack = 1;
    i_wb_dat = 32'hC5C5C5C5;
    compare();
    #10;
    i_wb_ack = 0;
    i_cache_req = 0;
    #10;
    compare();

    repeat (190) begin
      i_select = $random;
      i_write_data = $random;
      i_write_enable = $random;
      i_byte_enable = $random;
      i_data_access = $random;
      i_exclusive = $random;
      i_address = $random;
      i_cache_req = $random;
      i_wb_dat = $random;
      i_wb_ack = $random;
      i_wb_err = $random;
      #10;
      compare();  
    end

    $display("\033[1;34mTotal testcases: %d, Failed testcases: %d\033[0m", total_tests, failed_tests);
    if (failed_tests==0) begin
            $display("=====================Your Design Passed======================");
    end

    // Finish simulation
    $finish;
  end

    task compare;
    begin
        total_tests = total_tests + 1;

        if (match)                                //condition to check DUT outputs and calculated 
                                                    //outputs from task are equal 
			begin
				//$display("\033[1;32mtestcase is passed!!!\033[0m");
//				$display("testcase is passed!!!");
            	//$display("i_select = %h, i_write_data = %h, i_write_enable = %h, i_byte_enable = %h, i_data_access = %h, i_exclusive = %h, i_address = %h, i_cache_req = %h, i_wb_dat = %h, i_wb_ack = %h, i_wb_err = %h, o_stall_dut = %h, o_wb_adr_dut = %h, o_wb_sel_dut = %h, o_wb_we_dut = %h, o_wb_dat_dut = %h, o_wb_cyc_dut = %h, o_wb_stb_dut = %h, o_stall_ref = %h, o_wb_adr_ref = %h, o_wb_sel_ref = %h, o_wb_we_ref = %h, o_wb_dat_ref = %h, o_wb_cyc_ref = %h, o_wb_stb_ref = %h", i_select, i_write_data, i_write_enable, i_byte_enable, i_data_access, i_exclusive, i_address, i_cache_req, i_wb_dat, i_wb_ack, i_wb_err, o_stall_dut, o_wb_adr_dut, o_wb_sel_dut, o_wb_we_dut, o_wb_dat_dut, o_wb_cyc_dut, o_wb_stb_dut, o_stall_ref, o_wb_adr_ref, o_wb_sel_ref, o_wb_we_ref, o_wb_dat_ref, o_wb_cyc_ref, o_wb_stb_ref);      //displaying inputs, outputs and result
			end

		else begin
			//$display("\033[1;31mtestcase is failed!!!\033[0m");
            //$display("i_select = %h, i_write_data = %h, i_write_enable = %h, i_byte_enable = %h, i_data_access = %h, i_exclusive = %h, i_address = %h, i_cache_req = %h, i_wb_dat = %h, i_wb_ack = %h, i_wb_err = %h, o_stall_dut = %h, o_wb_adr_dut = %h, o_wb_sel_dut = %h, o_wb_we_dut = %h, o_wb_dat_dut = %h, o_wb_cyc_dut = %h, o_wb_stb_dut = %h, o_stall_ref = %h, o_wb_adr_ref = %h, o_wb_sel_ref = %h, o_wb_we_ref = %h, o_wb_dat_ref = %h, o_wb_cyc_ref = %h, o_wb_stb_ref = %h", i_select, i_write_data, i_write_enable, i_byte_enable, i_data_access, i_exclusive, i_address, i_cache_req, i_wb_dat, i_wb_ack, i_wb_err, o_stall_dut, o_wb_adr_dut, o_wb_sel_dut, o_wb_we_dut, o_wb_dat_dut, o_wb_cyc_dut, o_wb_stb_dut, o_stall_ref, o_wb_adr_ref, o_wb_sel_ref, o_wb_we_ref, o_wb_dat_ref, o_wb_cyc_ref, o_wb_stb_ref);      //displaying inputs, outputs and result
            failed_tests = failed_tests + 1; 
		end
    end
	endtask

    initial begin
        $dumpfile("sim.fsdb");
        $dumpvars(0);
    end


endmodule

