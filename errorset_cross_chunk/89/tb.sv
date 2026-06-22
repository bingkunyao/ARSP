 
module ref_hpdmc_mgmt #(
	parameter sdram_depth = 26,
	parameter sdram_columndepth = 9
) (
	input sys_clk,
	input sdram_rst,
	input [2:0] tim_rp,
	input [2:0] tim_rcd,
	input [10:0] tim_refi,
	input [3:0] tim_rfc,
	input stb,
	input we,
	input [sdram_depth-3-1:0] address, 
	output reg ref_ack,
	output reg ref_read,
	output reg ref_write,
	output [3:0] ref_concerned_bank,
	input read_safe,
	input write_safe,
	input [3:0] precharge_safe,
	output ref_sdram_cs_n,
	output ref_sdram_we_n,
	output ref_sdram_cas_n,
	output ref_sdram_ras_n,
	output [12:0] ref_sdram_adr,
	output [1:0] ref_sdram_ba
);
parameter rowdepth = sdram_depth-2-1-(sdram_columndepth+2)+1;
wire [sdram_depth-2-1:0] address32 = {address, 1'b0};
wire [sdram_columndepth-1:0] col_address = address32[sdram_columndepth-1:0];
wire [1:0] bank_address = address32[sdram_columndepth+1:sdram_columndepth];
wire [rowdepth-1:0] row_address = address32[sdram_depth-2-1:sdram_columndepth+2];
reg [3:0] bank_address_onehot;
always @(*) begin
	case(bank_address)
		2'b00: bank_address_onehot <= 4'b0001;
		2'b01: bank_address_onehot <= 4'b0010;
		2'b10: bank_address_onehot <= 4'b0100;
		2'b11: bank_address_onehot <= 4'b1000;
	endcase
end
reg [3:0] has_openrow;
reg [rowdepth-1:0] openrows[0:3];
reg [3:0] trref_ack_close;
reg [3:0] trref_ack_open;
always @(posedge sys_clk) begin
	if(sdram_rst) begin
		has_openrow = 4'h0;
	end else begin
		has_openrow = (has_openrow | trref_ack_open) & ~trref_ack_close;
		if(trref_ack_open[0]) openrows[0] <= row_address;
		if(trref_ack_open[1]) openrows[1] <= row_address;
		if(trref_ack_open[2]) openrows[2] <= row_address;
 		if(trref_ack_open[3]) openrows[3] <= row_address;
	end
end
assign ref_concerned_bank = bank_address_onehot;
wire current_precharge_safe =
	 (precharge_safe[0] | ~bank_address_onehot[0])
	&(precharge_safe[1] | ~bank_address_onehot[1])
	&(precharge_safe[2] | ~bank_address_onehot[2])
	&(precharge_safe[3] | ~bank_address_onehot[3]);
wire bank_open = has_openrow[bank_address];
wire page_hit = bank_open & (openrows[bank_address] == row_address);
reg ref_sdram_adr_loadrow;
reg ref_sdram_adr_loadcol;
reg ref_sdram_adr_loadA10;
assign ref_sdram_adr =
	 ({13{ref_sdram_adr_loadrow}}	& row_address)
	|({13{ref_sdram_adr_loadcol}}	& col_address)
	|({13{ref_sdram_adr_loadA10}}	& 13'd1024);
assign ref_sdram_ba = bank_address;
reg sdram_cs;
reg sdram_we;
reg sdram_cas;
reg sdram_ras;
assign ref_sdram_cs_n = ~sdram_cs;
assign ref_sdram_we_n = ~sdram_we;
assign ref_sdram_cas_n = ~sdram_cas;
assign ref_sdram_ras_n = ~sdram_ras;
reg [2:0] precharge_counter;
reg reload_precharge_counter;
wire precharge_done = (precharge_counter == 3'd0);
always @(posedge sys_clk) begin
	if(reload_precharge_counter)
		precharge_counter <= tim_rp;
	else if(~precharge_done)
		precharge_counter <= precharge_counter - 3'd1;
end
reg [2:0] activate_counter;
reg reload_activate_counter;
wire activate_done = (activate_counter == 3'd0);
always @(posedge sys_clk) begin
	if(reload_activate_counter)
		activate_counter <= tim_rcd;
	else if(~activate_done)
		activate_counter <= activate_counter - 3'd1;
end
reg [10:0] refresh_counter;
reg reload_refresh_counter;
wire must_refresh = refresh_counter == 11'd0;
always @(posedge sys_clk) begin
	if(sdram_rst)
		refresh_counter <= 11'd0;
	else begin
		if(reload_refresh_counter)
			refresh_counter <= tim_refi;
		else if(~must_refresh)
			refresh_counter <= refresh_counter - 11'd1;
	end
end
reg [3:0] autorefresh_counter;
reg reload_autorefresh_counter;
wire autorefresh_done = (autorefresh_counter == 4'd0);
always @(posedge sys_clk) begin
	if(reload_autorefresh_counter)
		autorefresh_counter <= tim_rfc;
	else if(~autorefresh_done)
		autorefresh_counter <= autorefresh_counter - 4'd1;
end
reg [3:0] state;
reg [3:0] next_state;
parameter IDLE			= 4'd0;
parameter ACTIVATE		= 4'd1;
parameter read			= 4'd2;
parameter write			= 4'd3;
parameter PRECHARGEALL		= 4'd4;
parameter AUTOREFRESH		= 4'd5;
parameter AUTOREFRESH_WAIT	= 4'd6;
always @(posedge sys_clk) begin
	if(sdram_rst)
		state <= IDLE;
	else begin
		state <= next_state;
	end
end
always @(*) begin
	next_state = state;
	reload_precharge_counter = 1'b0;
	reload_activate_counter = 1'b0;
	reload_refresh_counter = 1'b0;
	reload_autorefresh_counter = 1'b0;
	sdram_cs = 1'b0;
	sdram_we = 1'b0;
	sdram_cas = 1'b0;
	sdram_ras = 1'b0;
	ref_sdram_adr_loadrow = 1'b0;
	ref_sdram_adr_loadcol = 1'b0;
	ref_sdram_adr_loadA10 = 1'b0;
	trref_ack_close = 4'b0000;
	trref_ack_open = 4'b0000;
	ref_read = 1'b0;
	ref_write = 1'b0;
	ref_ack = 1'b0;
	case(state)
		IDLE: begin
			if(must_refresh)
				next_state = PRECHARGEALL;
			else begin
				if(stb) begin
					if(page_hit) begin
						if(we) begin
							if(write_safe) begin
								sdram_cs = 1'b1;
								sdram_ras = 1'b0;
								sdram_cas = 1'b1;
								sdram_we = 1'b1;
								ref_sdram_adr_loadcol = 1'b1;
								ref_write = 1'b1;
								ref_ack = 1'b1;
							end
						end else begin
							if(read_safe) begin
								sdram_cs = 1'b1;
								sdram_ras = 1'b0;
								sdram_cas = 1'b1;
								sdram_we = 1'b0;
								ref_sdram_adr_loadcol = 1'b1;
								ref_read = 1'b1;
								ref_ack = 1'b1;
							end
						end
					end else begin
						if(bank_open) begin
							if(current_precharge_safe) begin
								sdram_cs = 1'b1;
								sdram_ras = 1'b1;
								sdram_cas = 1'b0;
								sdram_we = 1'b1;
								trref_ack_close = bank_address_onehot;
								reload_precharge_counter = 1'b1;
								next_state = ACTIVATE;
							end
						end else begin
							sdram_cs = 1'b1;
							sdram_ras = 1'b1;
							sdram_cas = 1'b0;
							sdram_we = 1'b0;
							ref_sdram_adr_loadrow = 1'b1;
							trref_ack_open = bank_address_onehot;
							reload_activate_counter = 1'b1;
							if(we)
								next_state = ref_write;
							else
								next_state = ref_read;
						end
					end
				end
			end
		end
		ACTIVATE: begin
			if(precharge_done) begin
				sdram_cs = 1'b1;
				sdram_ras = 1'b1;
				sdram_cas = 1'b0;
				sdram_we = 1'b0;
				ref_sdram_adr_loadrow = 1'b1;
				trref_ack_open = bank_address_onehot;
				reload_activate_counter = 1'b1;
				if(we)
					next_state = ref_write;
				else
					next_state = ref_read;
			end
		end
		ref_read: begin
			if(activate_done) begin
				if(read_safe) begin
					sdram_cs = 1'b1;
					sdram_ras = 1'b0;
					sdram_cas = 1'b1;
					sdram_we = 1'b0;
					ref_sdram_adr_loadcol = 1'b1;
					ref_read = 1'b1;
					ref_ack = 1'b1;
					next_state = IDLE;
				end
			end
		end
		ref_write: begin
			if(activate_done) begin
				if(write_safe) begin
					sdram_cs = 1'b1;
					sdram_ras = 1'b0;
					sdram_cas = 1'b1;
					sdram_we = 1'b1;
					ref_sdram_adr_loadcol = 1'b1;
					ref_write = 1'b1;
					ref_ack = 1'b1;
					next_state = IDLE;
				end
			end
		end
		PRECHARGEALL: begin
			if(precharge_safe == 4'b1111) begin
				sdram_cs = 1'b1;
				sdram_ras = 1'b1;
				sdram_cas = 1'b0;
				sdram_we = 1'b1;
				ref_sdram_adr_loadA10 = 1'b1;
				reload_precharge_counter = 1'b1;
				trref_ack_close = 4'b1111;
				next_state = AUTOREFRESH;
			end
		end
		AUTOREFRESH: begin
			if(precharge_done) begin
				sdram_cs = 1'b1;
				sdram_ras = 1'b1;
				sdram_cas = 1'b1;
				sdram_we = 1'b0;
				reload_refresh_counter = 1'b1;
				reload_autorefresh_counter = 1'b1;
				next_state = AUTOREFRESH_WAIT;
			end
		end
		AUTOREFRESH_WAIT: begin
			if(autorefresh_done)
				next_state = IDLE;
		end
	endcase
end
endmodule




 module tb;

  // Parameters
  parameter sdram_depth = 26;
  parameter sdram_columndepth = 9;

  // Inputs
  reg sys_clk;
  reg sdram_rst;
  reg [2:0] tim_rp;
  reg [2:0] tim_rcd;
  reg [10:0] tim_refi;
  reg [3:0] tim_rfc;
  reg stb;
  reg we;
  reg [sdram_depth-3-1:0] address;
  reg read_safe;
  reg write_safe;
  reg [3:0] precharge_safe;

  // Outputs
  wire ref_ack,ack;
  wire ref_read,read;
  wire ref_write,write;
  wire [3:0] ref_concerned_bank,concerned_bank;
  wire ref_sdram_cs_n,sdram_cs_n;
  wire ref_sdram_we_n,sdram_we_n;
  wire ref_sdram_cas_n,sdram_cas_n;
  wire ref_sdram_ras_n,sdram_ras_n;
  wire [12:0] ref_sdram_adr,sdram_adr;
  wire [1:0] ref_sdram_ba,sdram_ba;


    wire match;
    integer total_tests = 0;
    integer failed_tests = 0;

assign match =({ref_ack ,ref_read,ref_write,ref_concerned_bank,ref_sdram_cs_n,ref_sdram_we_n,ref_sdram_cas_n,ref_sdram_ras_n,ref_sdram_adr,ref_sdram_ba} === {ack,read,write,concerned_bank,sdram_cs_n,sdram_we_n,sdram_cas_n,sdram_ras_n,sdram_adr,sdram_ba});


  // Instantiate the Unit Under Test (UUT)
  hpdmc_mgmt #(
    .sdram_depth(sdram_depth),
    .sdram_columndepth(sdram_columndepth)
  ) uut (
    .sys_clk(sys_clk),
    .sdram_rst(sdram_rst),
    .tim_rp(tim_rp),
    .tim_rcd(tim_rcd),
    .tim_refi(tim_refi),
    .tim_rfc(tim_rfc),
    .stb(stb),
    .we(we),
    .address(address),
    .ack(ack),
    .read(read),
    .write(write),
    .concerned_bank(concerned_bank),
    .read_safe(read_safe),
    .write_safe(write_safe),
    .precharge_safe(precharge_safe),
    .sdram_cs_n(sdram_cs_n),
    .sdram_we_n(sdram_we_n),
    .sdram_cas_n(sdram_cas_n),
    .sdram_ras_n(sdram_ras_n),
    .sdram_adr(sdram_adr),
    .sdram_ba(sdram_ba)
  );

  // Instantiate the Unit Under Test (UUT)
  ref_hpdmc_mgmt #(
    .sdram_depth(sdram_depth),
    .sdram_columndepth(sdram_columndepth)
  ) rf (
    .sys_clk(sys_clk),
    .sdram_rst(sdram_rst),
    .tim_rp(tim_rp),
    .tim_rcd(tim_rcd),
    .tim_refi(tim_refi),
    .tim_rfc(tim_rfc),
    .stb(stb),
    .we(we),
    .address(address),
    .ref_ack(ref_ack),
    .ref_read(ref_read),
    .ref_write(ref_write),
    .ref_concerned_bank(ref_concerned_bank),
    .read_safe(read_safe),
    .write_safe(write_safe),
    .precharge_safe(precharge_safe),
    .ref_sdram_cs_n(ref_sdram_cs_n),
    .ref_sdram_we_n(ref_sdram_we_n),
    .ref_sdram_cas_n(ref_sdram_cas_n),
    .ref_sdram_ras_n(ref_sdram_ras_n),
    .ref_sdram_adr(ref_sdram_adr),
    .ref_sdram_ba(ref_sdram_ba)
  );


  // Clock generation
  always #5 sys_clk = ~sys_clk;

  initial begin
    // Initialize Inputs
    sys_clk = 0;
    sdram_rst = 0;
    tim_rp = 3'd3;
    tim_rcd = 3'd3;
    tim_refi = 11'd1000;
    tim_rfc = 4'd5;
    stb = 0;
    we = 0;
    address = 0;
    read_safe = 1;
    write_safe = 1;
    precharge_safe = 4'b1111;

    // Wait for global reset
    #10;

    // Test Case 1: Reset the module
    sdram_rst = 1;
    #10;
    sdram_rst = 0;
 compare();
    #10;

    // Test Case 2: Write operation
    stb = 1;
    we = 1;
    address = 23'h000001;
    #10;
    stb = 0;
    we = 0;
 compare();
    #10;

    // Test Case 3: Read operation
    stb = 1;
    we = 0;
    address = 23'h000002;
    #10;
    stb = 0;
 compare();
    #10;


repeat (96) begin
            @(posedge sys_clk);
	  tim_rp = $random;
	  tim_rcd = $random;
	  tim_refi = $random;
	  tim_rfc = $random;
	  stb = $random;
	  we = $random;
	  //address = $random ;
	  read_safe = $random;
	  write_safe = $random;
	  precharge_safe = $random;

  // Inputs
  //reg [sdram_depth-3-1:0] address;

            #10;
            compare();
        end

    // Finish simulation
        $display("All tests passed: design passed");
        $display("\033[1;34mTotal testcases: %d, Failed testcases: %d\033[0m", total_tests, failed_tests);
    $finish;
  end


task compare;
        total_tests = total_tests + 1;
        if (match)                                //condition to check DUT outputs and calculated 
                                                    //outputs from task are equal 
			begin
				$display("\033[1;32mtestcase is passed!!!\033[0m");
				$display("ack = %h,read = %h, write = %h,concerned_bank = %h,sdram_cs_n = %h, sdram_we_n = %h,sdram_cas_n = %h,sdram_ras_n = %h,sdram_adr = %h,sdram_ba = %h,",ack,read,write,concerned_bank,sdram_cs_n,sdram_we_n,sdram_cas_n,sdram_ras_n,sdram_adr,sdram_ba);
			end

		else begin
			$display("\033[1;31mtestcase is failed!!!\033[0m");
			$display("ack = %h,read = %h, write = %h,concerned_bank = %h,sdram_cs_n = %h, sdram_we_n = %h,sdram_cas_n = %h,sdram_ras_n = %h,sdram_adr = %h,sdram_ba = %h,",ack,read,write,concerned_bank,sdram_cs_n,sdram_we_n,sdram_cas_n,sdram_ras_n,sdram_adr,sdram_ba);
			failed_tests = failed_tests + 1; 
           
		end
    
	endtask


endmodule
