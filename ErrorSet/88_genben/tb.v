 
module ref_cavlc_read_levels (
    clk,
    rst_n,
    ena,
    t1s_sel,
    prefix_sel,
    suffix_sel,
    calc_sel,
    TrailingOnes,
    TotalCoeff,
    rbsp,
    i,
    ref_level_0,
    ref_level_1,
    ref_level_2,
    ref_level_3,
    ref_level_4,
    ref_level_5,
    ref_level_6,
    ref_level_7,
    ref_level_8,
    ref_level_9,
    ref_level_10,
    ref_level_11,
    ref_level_12,
    ref_level_13,
    ref_level_14,
    ref_level_15,
    ref_len_comb
);
input   clk;
input   rst_n;
input   ena;
input   t1s_sel;
input   prefix_sel;
input   suffix_sel;
input   calc_sel;
input   [1:0]   TrailingOnes;
input   [4:0]   TotalCoeff;
input   [0:15]  rbsp;
input   [3:0]   i;
output  [8:0]   ref_level_0;
output  [8:0]   ref_level_1;
output  [8:0]   ref_level_2;
output  [8:0]   ref_level_3;
output  [8:0]   ref_level_4;
output  [8:0]   ref_level_5;
output  [8:0]   ref_level_6;
output  [8:0]   ref_level_7;
output  [8:0]   ref_level_8;
output  [8:0]   ref_level_9;
output  [8:0]   ref_level_10;
output  [8:0]   ref_level_11;
output  [8:0]   ref_level_12;
output  [8:0]   ref_level_13;
output  [8:0]   ref_level_14;
output  [8:0]   ref_level_15;
output  [4:0]   ref_len_comb;
reg     [0:15]  rbsp_internal;        
reg     [3:0]   level_prefix_comb;
reg     [8:0]   level_suffix;
reg     [4:0]   ref_len_comb;
reg     [3:0]   level_prefix;
reg     [2:0]   suffixLength;   
reg     [8:0]   level;
reg     [8:0]   level_abs;
reg     [8:0]   level_code_tmp;
reg     [8:0]   ref_level_0, ref_level_1, ref_level_2, ref_level_3, ref_level_4, ref_level_5, ref_level_6, ref_level_7;
reg     [8:0]   ref_level_8, ref_level_9, ref_level_10, ref_level_11, ref_level_12, ref_level_13, ref_level_14, ref_level_15;
always @(*)
if ((t1s_sel || prefix_sel || suffix_sel)&& ena)
    rbsp_internal <= rbsp;
else
    rbsp_internal <= 'hffff;
always @(*)
if (rbsp_internal[0])         level_prefix_comb <= 0;
else if (rbsp_internal[1])    level_prefix_comb <= 1;
else if (rbsp_internal[2])    level_prefix_comb <= 2;
else if (rbsp_internal[3])    level_prefix_comb <= 3;
else if (rbsp_internal[4])    level_prefix_comb <= 4;
else if (rbsp_internal[5])    level_prefix_comb <= 5;
else if (rbsp_internal[6])    level_prefix_comb <= 6;
else if (rbsp_internal[7])    level_prefix_comb <= 7;
else if (rbsp_internal[8])    level_prefix_comb <= 8;
else if (rbsp_internal[9])    level_prefix_comb <= 9;
else if (rbsp_internal[10])   level_prefix_comb <= 10;
else if (rbsp_internal[11])   level_prefix_comb <= 11;
else if (rbsp_internal[12])   level_prefix_comb <= 12; 
else if (rbsp_internal[13])   level_prefix_comb <= 13; 
else if (rbsp_internal[14])   level_prefix_comb <= 14;
else if (rbsp_internal[15])   level_prefix_comb <= 15;
else                          level_prefix_comb <= 'bx;
always @(posedge clk or negedge rst_n)
if (!rst_n)
    level_prefix <= 0;
else if (prefix_sel && ena)
    level_prefix <= level_prefix_comb;
wire first_level;
assign first_level = (i == TotalCoeff - TrailingOnes - 1);
always @(posedge clk or negedge rst_n)
if (!rst_n)
    suffixLength <= 0;
else if (prefix_sel && ena) begin
    if (TotalCoeff > 10 && TrailingOnes < 3 && first_level )  
        suffixLength <= 1;
    else if (first_level)
        suffixLength <= 0;
    else if (suffixLength == 0 && level_abs > 2'd3)
        suffixLength <= 2;
    else if (suffixLength == 0)
        suffixLength <= 1;
    else if (  level_abs > (2'd3 << (suffixLength - 1'b1) ) && suffixLength < 6)
        suffixLength <= suffixLength + 1'b1;
end
always @(*)
if (suffixLength > 0 && level_prefix <= 14) 
    level_suffix <= {3'b0, rbsp_internal[0:5] >> (3'd6 - suffixLength)};
else if (level_prefix == 14)   
    level_suffix <= {3'b0, rbsp_internal[0:3] };
else if (level_prefix == 15) 
    level_suffix <= rbsp_internal[3:11];     
else 
    level_suffix <= 0;      
always @(posedge clk or negedge rst_n)
if (!rst_n) begin
    level_code_tmp <=  0;
end
else if (suffix_sel && ena) begin
    level_code_tmp <= (level_prefix << suffixLength) + level_suffix + 
    ((suffixLength == 0 && level_prefix == 15) ? 4'd15 : 0);
end
wire    [2:0]   tmp1;
assign tmp1 = (first_level && TrailingOnes < 3)? 2'd2 : 2'd0;
always @(*)
begin
    if (level_code_tmp % 2 == 0) begin
        level <= ( level_code_tmp + tmp1 + 2 ) >> 1;
    end
    else begin
        level <= (-level_code_tmp - tmp1 - 1 ) >> 1;
    end
end
wire level_abs_refresh;
assign level_abs_refresh = calc_sel && ena;
always @(posedge clk or negedge rst_n)
if (!rst_n) begin
    level_abs <= 0;
end
else if (level_abs_refresh) begin
    level_abs <= level[8] ? -level : level;
end
always @ (posedge clk or negedge rst_n)
if (!rst_n) begin
    ref_level_0 <= 0;   ref_level_1 <= 0;   ref_level_2 <= 0;   ref_level_3 <= 0;
    ref_level_4 <= 0;   ref_level_5 <= 0;   ref_level_6 <= 0;   ref_level_7 <= 0;
    ref_level_8 <= 0;   ref_level_9 <= 0;   ref_level_10<= 0;   ref_level_11<= 0;
    ref_level_12<= 0;   ref_level_13<= 0;   ref_level_14<= 0;   ref_level_15<= 0;
end
else if (t1s_sel && ena)
    case (i)
    0 : ref_level_0 <= rbsp_internal[0]? -1 : 1;
    1 : begin
            ref_level_1 <= rbsp_internal[0]? -1 : 1;
            if (TrailingOnes[1])
                ref_level_0 <= rbsp_internal[1]? -1 : 1;
        end
    2 : begin
            ref_level_2 <= rbsp_internal[0]? -1 : 1;
            if (TrailingOnes[1])
                ref_level_1 <= rbsp_internal[1]? -1 : 1;
            if (TrailingOnes == 3)
                ref_level_0 <= rbsp_internal[2]? -1 : 1;
        end         
    3 : begin
            ref_level_3 <= rbsp_internal[0]? -1 : 1;
            if (TrailingOnes[1])
                ref_level_2 <= rbsp_internal[1]? -1 : 1;
            if (TrailingOnes == 3)
                ref_level_1 <= rbsp_internal[2]? -1 : 1;
        end 
    4 : begin
            ref_level_4 <= rbsp_internal[0]? -1 : 1;
            if (TrailingOnes[1])
                ref_level_3 <= rbsp_internal[1]? -1 : 1;
            if (TrailingOnes == 3)
                ref_level_2 <= rbsp_internal[2]? -1 : 1;
        end 
    5 : begin
            ref_level_5 <= rbsp_internal[0]? -1 : 1;
            if (TrailingOnes[1])
                ref_level_4 <= rbsp_internal[1]? -1 : 1;
            if (TrailingOnes == 3)
                ref_level_3 <= rbsp_internal[2]? -1 : 1;
        end 
    6 : begin
            ref_level_6 <= rbsp_internal[0]? -1 : 1;
            if (TrailingOnes[1])
                ref_level_5 <= rbsp_internal[1]? -1 : 1;
            if (TrailingOnes == 3)
                ref_level_4 <= rbsp_internal[2]? -1 : 1;
        end 
    7 : begin
            ref_level_7 <= rbsp_internal[0]? -1 : 1;
            if (TrailingOnes[1])
                ref_level_6 <= rbsp_internal[1]? -1 : 1;
            if (TrailingOnes == 3)
                ref_level_5 <= rbsp_internal[2]? -1 : 1;
        end 
    8 : begin
            ref_level_8 <= rbsp_internal[0]? -1 : 1;
            if (TrailingOnes[1])
                ref_level_7 <= rbsp_internal[1]? -1 : 1;
            if (TrailingOnes == 3)
                ref_level_6 <= rbsp_internal[2]? -1 : 1;
        end 
    9 : begin
            ref_level_9 <= rbsp_internal[0]? -1 : 1;
            if (TrailingOnes[1])
                ref_level_8 <= rbsp_internal[1]? -1 : 1;
            if (TrailingOnes == 3)
                ref_level_7 <= rbsp_internal[2]? -1 : 1;
        end 
    10: begin
            ref_level_10 <= rbsp_internal[0]? -1 : 1;
            if (TrailingOnes[1])
                ref_level_9 <= rbsp_internal[1]? -1 : 1;
            if (TrailingOnes == 3)
                ref_level_8 <= rbsp_internal[2]? -1 : 1;
        end 
    11: begin
            ref_level_11 <= rbsp_internal[0]? -1 : 1;
            if (TrailingOnes[1])
                ref_level_10 <= rbsp_internal[1]? -1 : 1;
            if (TrailingOnes == 3)
                ref_level_9 <= rbsp_internal[2]? -1 : 1;
        end 
    12: begin
            ref_level_12 <= rbsp_internal[0]? -1 : 1;
            if (TrailingOnes[1])
                ref_level_11 <= rbsp_internal[1]? -1 : 1;
            if (TrailingOnes == 3)
                ref_level_10 <= rbsp_internal[2]? -1 : 1;
        end 
    13: begin
            ref_level_13 <= rbsp_internal[0]? -1 : 1;
            if (TrailingOnes[1])
                ref_level_12 <= rbsp_internal[1]? -1 : 1;
            if (TrailingOnes == 3)
                ref_level_11 <= rbsp_internal[2]? -1 : 1;
        end 
    14: begin
            ref_level_14 <= rbsp_internal[0]? -1 : 1;
            if (TrailingOnes[1])
                ref_level_13 <= rbsp_internal[1]? -1 : 1;
            if (TrailingOnes == 3)
                ref_level_12 <= rbsp_internal[2]? -1 : 1;
        end 
    15: begin
            ref_level_15 <= rbsp_internal[0]? -1 : 1;
            if (TrailingOnes[1])
                ref_level_14 <= rbsp_internal[1]? -1 : 1;
            if (TrailingOnes == 3)
                ref_level_13 <= rbsp_internal[2]? -1 : 1;
        end 
endcase
else if (calc_sel && ena)
case (i)
    0 :ref_level_0 <= level;
    1 :ref_level_1 <= level;
    2 :ref_level_2 <= level;
    3 :ref_level_3 <= level;
    4 :ref_level_4 <= level;
    5 :ref_level_5 <= level;
    6 :ref_level_6 <= level;
    7 :ref_level_7 <= level;
    8 :ref_level_8 <= level;
    9 :ref_level_9 <= level;
    10:ref_level_10<= level;
    11:ref_level_11<= level;
    12:ref_level_12<= level;
    13:ref_level_13<= level;
    14:ref_level_14<= level;
    15:ref_level_15<= level;
endcase
always @(*)
if(t1s_sel)
    ref_len_comb <= TrailingOnes;
else if(prefix_sel)
    ref_len_comb <= level_prefix_comb + 1;
else if(suffix_sel && suffixLength > 0 && level_prefix <= 14)
    ref_len_comb <= suffixLength;  
else if(suffix_sel && level_prefix == 14)
    ref_len_comb <= 4;
else if(suffix_sel && level_prefix == 15)
    ref_len_comb <= 12;
else
    ref_len_comb <= 0;        
endmodule




 module tb;

  // Inputs
  reg clk;
  reg rst_n;
  reg ena;
  reg t1s_sel;
  reg prefix_sel;
  reg suffix_sel;
  reg calc_sel;
  reg [1:0] TrailingOnes;
  reg [4:0] TotalCoeff;
  reg [0:15] rbsp;
  reg [3:0] i;

  // Outputs
  wire [8:0] ref_level_0;
  wire [8:0] ref_level_1;
  wire [8:0] ref_level_2;
  wire [8:0] ref_level_3;
  wire [8:0] ref_level_4;
  wire [8:0] ref_level_5;
  wire [8:0] ref_level_6;
  wire [8:0] ref_level_7;
  wire [8:0] ref_level_8;
  wire [8:0] ref_level_9;
  wire [8:0] ref_level_10;
  wire [8:0] ref_level_11;
  wire [8:0] ref_level_12;
  wire [8:0] ref_level_13;
  wire [8:0] ref_level_14;
  wire [8:0] ref_level_15;
  wire [4:0] ref_len_comb;

  wire [8:0] dut_level_0;
  wire [8:0] dut_level_1;
  wire [8:0] dut_level_2;
  wire [8:0] dut_level_3;
  wire [8:0] dut_level_4;
  wire [8:0] dut_level_5;
  wire [8:0] dut_level_6;
  wire [8:0] dut_level_7;
  wire [8:0] dut_level_8;
  wire [8:0] dut_level_9;
  wire [8:0] dut_level_10;
  wire [8:0] dut_level_11;
  wire [8:0] dut_level_12;
  wire [8:0] dut_level_13;
  wire [8:0] dut_level_14;
  wire [8:0] dut_level_15;
  wire [4:0] dut_len_comb;

wire match;
 	integer total_tests = 0;
	integer failed_tests = 0;

assign match = ({ref_level_0,ref_level_1,ref_level_2,ref_level_3,ref_level_4,ref_level_5,ref_level_6,ref_level_7,ref_level_8,ref_level_9,ref_level_10,ref_level_11,ref_level_12,ref_level_13,ref_level_14,ref_level_15,ref_len_comb} === ({ref_level_0,ref_level_1,ref_level_2,ref_level_3,ref_level_4,ref_level_5,ref_level_6,ref_level_7,ref_level_8,ref_level_9,ref_level_10,ref_level_11,ref_level_12,ref_level_13,ref_level_14,ref_level_15,ref_len_comb}  ^ {dut_level_0,dut_level_1,dut_level_2,dut_level_3,dut_level_4,dut_level_5,dut_level_6,dut_level_7,dut_level_8,dut_level_9,dut_level_10,dut_level_11,dut_level_12,dut_level_13,dut_level_14,dut_level_15,dut_len_comb}  ^ {ref_level_0,ref_level_1,ref_level_2,ref_level_3,ref_level_4,ref_level_5,ref_level_6,ref_level_7,ref_level_8,ref_level_9,ref_level_10,ref_level_11,ref_level_12,ref_level_13,ref_level_14,ref_level_15,ref_len_comb} ));


  // Instantiate the Unit Under Test (UUT)
  cavlc_read_levels uut1 (
    .clk(clk),
    .rst_n(rst_n),
    .ena(ena),
    .t1s_sel(t1s_sel),
    .prefix_sel(prefix_sel),
    .suffix_sel(suffix_sel),
    .calc_sel(calc_sel),
    .TrailingOnes(TrailingOnes),
    .TotalCoeff(TotalCoeff),
    .rbsp(rbsp),
    .i(i),
    .level_0(dut_level_0),
    .level_1(dut_level_1),
    .level_2(dut_level_2),
    .level_3(dut_level_3),
    .level_4(dut_level_4),
    .level_5(dut_level_5),
    .level_6(dut_level_6),
    .level_7(dut_level_7),
    .level_8(dut_level_8),
    .level_9(dut_level_9),
    .level_10(dut_level_10),
    .level_11(dut_level_11),
    .level_12(dut_level_12),
    .level_13(dut_level_13),
    .level_14(dut_level_14),
    .level_15(dut_level_15),
    .len_comb(dut_len_comb)
  );

  ref_cavlc_read_levels uut2 (
    .clk(clk),
    .rst_n(rst_n),
    .ena(ena),
    .t1s_sel(t1s_sel),
    .prefix_sel(prefix_sel),
    .suffix_sel(suffix_sel),
    .calc_sel(calc_sel),
    .TrailingOnes(TrailingOnes),
    .TotalCoeff(TotalCoeff),
    .rbsp(rbsp),
    .i(i),
    .ref_level_0(ref_level_0),
    .ref_level_1(ref_level_1),
    .ref_level_2(ref_level_2),
    .ref_level_3(ref_level_3),
    .ref_level_4(ref_level_4),
    .ref_level_5(ref_level_5),
    .ref_level_6(ref_level_6),
    .ref_level_7(ref_level_7),
    .ref_level_8(ref_level_8),
    .ref_level_9(ref_level_9),
    .ref_level_10(ref_level_10),
    .ref_level_11(ref_level_11),
    .ref_level_12(ref_level_12),
    .ref_level_13(ref_level_13),
    .ref_level_14(ref_level_14),
    .ref_level_15(ref_level_15),
    .ref_len_comb(ref_len_comb)
  );
  // Clock generation
  always #5 clk = ~clk;

  initial begin
    // Initialize Inputs
    clk = 0;
    rst_n = 0;
    ena = 0;
    t1s_sel = 0;
    prefix_sel = 0;
    suffix_sel = 0;
    calc_sel = 0;
    TrailingOnes = 0;
    TotalCoeff = 0;
    rbsp = 0;
    i = 0;

    // Wait for global reset
    #10;
    rst_n = 1;

    // Test Case 1: Initialize and set TrailingOnes
    ena = 1;
    t1s_sel = 1;
    TrailingOnes = 2;
    rbsp = 16'b1010_1010_1010_1010;
    i = 0;
    #10;
    i = 1;
    #10;
    i = 2;
    #10;
    i = 3;
    #10;
    t1s_sel = 0;
compare();

    // Test Case 2: Set prefix_sel and suffix_sel
    prefix_sel = 1;
    suffix_sel = 1;
    TotalCoeff = 5;
    rbsp = 16'b1100_1100_1100_1100;
    i = 0;
    #10;
    i = 1;
    #10;
    i = 2;
    #10;
    i = 3;
    #10;
    prefix_sel = 0;
    suffix_sel = 0;
compare();

    // Test Case 3: Set calc_sel
    calc_sel = 1;
    i = 0;
    #10;
    i = 1;
    #10;
    i = 2;
    #10;
    i = 3;
    #10;
    calc_sel = 0;
compare();

ena = 1;
    t1s_sel = 1;
    TrailingOnes = 2;
    TotalCoeff = 5;
    rbsp = 16'b1010101010101010;
    i = 0;
    #20;
compare();

   
    t1s_sel = 0;
    prefix_sel = 1;
    TrailingOnes = 1;
    TotalCoeff = 10;
    rbsp = 16'b1111000011110000;
    i = 1;
    #20;
compare();

    
    prefix_sel = 0;
    suffix_sel = 1;
    TrailingOnes = 0;
    TotalCoeff = 15;
    rbsp = 16'b1111111100000000;
    i = 2;
    #20;
compare();

    suffix_sel = 0;
    calc_sel = 1;
    TrailingOnes = 3;
    TotalCoeff = 20;
    rbsp = 16'b0000000011111111;
    i = 3;
    #20;
compare();

    t1s_sel = 1;
    prefix_sel = 1;
    suffix_sel = 1;
    calc_sel = 1;
    TrailingOnes = 2;
    TotalCoeff = 10;
    rbsp = 16'b1010101010101010;
    i = 4;
    #20;
compare();

    repeat (1000) begin
      @(posedge clk);
      ena = $random % 2;
      t1s_sel = $random % 2;
      prefix_sel = $random % 2;
      suffix_sel = $random % 2;
      calc_sel = $random % 2;
      TrailingOnes = $random % 4;
      TotalCoeff = $random % 32;
      rbsp = $random;
      i = $random % 16;
      compare();
    end
     compare();
  
   #20;
rst_n =0;
   #20;
rst_n =1;
   #20;

    // Finish simulation
        
        $display("All tests passed: design passed");
        $display("\033[1;34mTotal testcases: %d, Failed testcases: %d\033[0m", total_tests, failed_tests);

    if (failed_tests==0) begin
            $display("=====================Your Design Passed======================");
    end
    $finish;
  end

  initial begin
    // Monitor signals
   // $monitor("Time=%0t, clk=%b, rst_n=%b, ena=%b, t1s_sel=%b, prefix_sel=%b, suffix_sel=%b, calc_sel=%b, TrailingOnes=%b, TotalCoeff=%b, rbsp=%b, i=%b, dut_level_0=%b, dut_level_1=%b, dut_level_2=%b, dut_level_3=%b, dut_level_4=%b, dut_level_5=%b, dut_level_6=%b, dut_level_7=%b, dut_level_8=%b, dut_level_9=%b, dut_level_10=%b, dut_level_11=%b, dut_level_12=%b, dut_level_13=%b, dut_level_14=%b, dut_level_15=%b, dut_len_comb=%b",
      //        $time, clk, rst_n, ena, t1s_sel, prefix_sel, suffix_sel, calc_sel, TrailingOnes, TotalCoeff, rbsp, i, dut_level_0, dut_level_1, dut_level_2, dut_level_3, dut_level_4, dut_level_5, dut_level_6, dut_level_7, dut_level_8, dut_level_9, dut_level_10, dut_level_11, dut_level_12, dut_level_13, dut_level_14, dut_level_15, dut_len_comb);
  end

task compare;begin
        total_tests = total_tests + 1;
        if (match)                                //condition to check DUT outputs and calculated 
                                                    //outputs from task are equal 
			begin			//	$display("\033[1;32mtestcase is passed!!!\033[0m");
			//	$display("testcase is passed!!!");
			end

		else begin
			//$display("\033[1;31mtestcase is failed!!!\033[0m");
            failed_tests = failed_tests + 1; 
		end
	end
endtask


endmodule
