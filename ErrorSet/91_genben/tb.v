 
module ref_fpu_exceptions( clk, rst, enable, rmode, opa, opb, in_except,
exponent_in, mantissa_in, fpu_op, ref_out, ref_ex_enable, ref_underflow, ref_overflow, 
ref_inexact, ref_exception, ref_invalid);
input		clk;
input		rst;
input		enable;
input	[1:0]	rmode;
input	[63:0]	opa;
input	[63:0]	opb;
input	[63:0]	in_except;
input	[11:0]	exponent_in;
input	[1:0]	mantissa_in;
input	[2:0]	fpu_op;
output	[63:0]	ref_out;
output		ref_ex_enable;
output		ref_underflow;
output		ref_overflow;
output		ref_inexact;
output		ref_exception;
output		ref_invalid;
reg		[63:0]	ref_out;
reg		ref_ex_enable;
reg		ref_underflow;
reg		ref_overflow;
reg		ref_inexact;
reg		ref_exception;
reg		ref_invalid;
reg		in_et_zero;
reg		opa_et_zero;
reg		opb_et_zero;
reg		input_et_zero;
reg		add;
reg		subtract;
reg		multiply;
reg		divide;
reg		opa_QNaN;
reg		opb_QNaN;
reg		opa_SNaN;
reg		opb_SNaN;
reg		opa_pos_inf;
reg		opb_pos_inf;
reg		opa_neg_inf;
reg		opb_neg_inf;
reg		opa_inf;
reg		opb_inf;
reg		NaN_input;
reg		SNaN_input;
reg		a_NaN;
reg		div_by_0;
reg		div_0_by_0;
reg		div_inf_by_inf;
reg		div_by_inf;
reg		mul_0_by_inf;
reg		mul_inf;
reg		div_inf;
reg		add_inf;
reg		sub_inf;
reg		addsub_inf_invalid;
reg		addsub_inf;
reg		out_inf_trigger;
reg		out_pos_inf;
reg		out_neg_inf;
reg		round_nearest;
reg		round_to_zero;
reg		round_to_pos_inf;
reg		round_to_neg_inf;
reg		inf_round_down_trigger;
reg		mul_uf;
reg		div_uf;								
reg		underflow_trigger;			
reg		invalid_trigger;
reg		overflow_trigger;
reg		inexact_trigger;
reg	 	except_trigger;
reg		enable_trigger;
reg		NaN_out_trigger;
reg		SNaN_trigger;
wire	[10:0]  exp_2047 = 11'b11111111111;
wire	[10:0]  exp_2046 = 11'b11111111110;
reg		[62:0] NaN_output_0; 
reg		[62:0] NaN_output; 
wire	[51:0]  mantissa_max = 52'b1111111111111111111111111111111111111111111111111111;
reg		[62:0]	inf_round_down;
reg		[62:0]	out_inf;
reg		[63:0]	out_0;
reg		[63:0]	out_1;
reg		[63:0]	out_2;
always @(posedge clk)
begin
	if (rst) begin
		in_et_zero <=    0;
		opa_et_zero <=   0;
		opb_et_zero <=   0;
		input_et_zero <= 0;
		add 	<= 	0;
		subtract <= 0;
		multiply <= 0;
		divide 	<= 	0;
		opa_QNaN <= 0;
		opb_QNaN <= 0;
		opa_SNaN <= 0;
		opb_SNaN <= 0;
		opa_pos_inf <= 0;
		opb_pos_inf <= 0;
		opa_neg_inf <= 0;
		opb_neg_inf <= 0; 
		opa_inf <= 0;
		opb_inf <= 0;
		NaN_input <= 0; 
		SNaN_input <= 0;
		a_NaN <= 0;
		div_by_0 <= 0;
		div_0_by_0 <= 0;
		div_inf_by_inf <= 0;
		div_by_inf <= 0;
		mul_0_by_inf <= 0;
		mul_inf <= 0;
		div_inf <= 0;
		add_inf <= 0;
		sub_inf <= 0;
		addsub_inf_invalid <= 0;
		addsub_inf <= 0;
		out_inf_trigger <= 0;
		out_pos_inf <= 0;
		out_neg_inf <= 0;
		round_nearest <= 0;
		round_to_zero <= 0;
		round_to_pos_inf <= 0;
		round_to_neg_inf <= 0;
		inf_round_down_trigger <= 0;
		mul_uf <= 0;
		div_uf <= 0;															
		underflow_trigger <= 0;		
		invalid_trigger <= 0;
		overflow_trigger <= 0;
		inexact_trigger <= 0;
		except_trigger <= 0;
		enable_trigger <= 0;
		NaN_out_trigger <= 0;
		SNaN_trigger <= 0;
		NaN_output_0 <= 0;
		NaN_output <= 0;
		inf_round_down <= 0;
		out_inf <= 0;
		out_0 <= 0;
		out_1 <= 0;
		out_2 <= 0;
		end
	else if (enable) begin
		in_et_zero <= !(|in_except[62:0]);
		opa_et_zero <= !(|opa[62:0]);
		opb_et_zero <= !(|opb[62:0]);
		input_et_zero <= !(|in_except[62:0]);	
		add 	<= 	fpu_op == 3'b000;
		subtract <= 	fpu_op == 3'b001;
		multiply <= 	fpu_op == 3'b010;
		divide 	<= 	fpu_op == 3'b011;
		opa_QNaN <= (opa[62:52] == 2047) & |opa[51:0] & opa[51];
		opb_QNaN <= (opb[62:52] == 2047) & |opb[51:0] & opb[51];
		opa_SNaN <= (opa[62:52] == 2047) & |opa[51:0] & !opa[51];
		opb_SNaN <= (opb[62:52] == 2047) & |opb[51:0] & !opb[51];
		opa_pos_inf <= !opa[63] & (opa[62:52] == 2047) & !(|opa[51:0]);
		opb_pos_inf <= !opb[63] & (opb[62:52] == 2047) & !(|opb[51:0]);
		opa_neg_inf <= opa[63] & (opa[62:52] == 2047) & !(|opa[51:0]);
		opb_neg_inf <= opb[63] & (opb[62:52] == 2047) & !(|opb[51:0]);
		opa_inf <= (opa[62:52] == 2047) & !(|opa[51:0]);
		opb_inf <= (opb[62:52] == 2047) & !(|opb[51:0]);
		NaN_input <= opa_QNaN | opb_QNaN | opa_SNaN | opb_SNaN;
		SNaN_input <= opa_SNaN | opb_SNaN;
		a_NaN <= opa_QNaN | opa_SNaN;
		div_by_0 <= divide & opb_et_zero & !opa_et_zero;
		div_0_by_0 <= divide & opb_et_zero & opa_et_zero;
		div_inf_by_inf <= divide & opa_inf & opb_inf;
		div_by_inf <= divide & !opa_inf & opb_inf;
		mul_0_by_inf <= multiply & ((opa_inf & opb_et_zero) | (opa_et_zero & opb_inf));
		mul_inf <= multiply & (opa_inf | opb_inf) & !mul_0_by_inf;
		div_inf <= divide & opa_inf & !opb_inf;
		add_inf <= (add & (opa_inf | opb_inf));
		sub_inf <= (subtract & (opa_inf | opb_inf));
		addsub_inf_invalid <= (add & opa_pos_inf & opb_neg_inf) | (add & opa_neg_inf & opb_pos_inf) | 
					(subtract & opa_pos_inf & opb_pos_inf) | (subtract & opa_neg_inf & opb_neg_inf);
		addsub_inf <= (add_inf | sub_inf) & !addsub_inf_invalid;
		out_inf_trigger <= addsub_inf | mul_inf | div_inf | div_by_0 | (exponent_in > 2046);
		out_pos_inf <= out_inf_trigger & !in_except[63];
		out_neg_inf <= out_inf_trigger & in_except[63];
		round_nearest <= (rmode == 2'b00);
		round_to_zero <= (rmode == 2'b01);
		round_to_pos_inf <= (rmode == 2'b10);
		round_to_neg_inf <= (rmode == 2'b11);
		inf_round_down_trigger <= (out_pos_inf & round_to_neg_inf) | 
								(out_neg_inf & round_to_pos_inf) |
								(out_inf_trigger & round_to_zero);
		mul_uf <= multiply & !opa_et_zero & !opb_et_zero & in_et_zero;
		div_uf <= divide & !opa_et_zero & in_et_zero;																
		underflow_trigger <= div_by_inf | mul_uf | div_uf;								
		invalid_trigger <= SNaN_input | addsub_inf_invalid | mul_0_by_inf |
						div_0_by_0 | div_inf_by_inf;
		overflow_trigger <= out_inf_trigger & !NaN_input;
		inexact_trigger <= (|mantissa_in[1:0] | out_inf_trigger | underflow_trigger) &
						!NaN_input;
		except_trigger <= invalid_trigger | overflow_trigger | underflow_trigger |
						inexact_trigger;
		enable_trigger <= except_trigger | out_inf_trigger | NaN_input;	
		NaN_out_trigger <= NaN_input | invalid_trigger;
		SNaN_trigger <= invalid_trigger & !SNaN_input;
		NaN_output_0 <= a_NaN ? { exp_2047, 1'b1, opa[50:0]} : { exp_2047, 1'b1, opb[50:0]};
		NaN_output <= SNaN_trigger ? { exp_2047, 2'b01, opa[49:0]} : NaN_output_0;
		inf_round_down <= { exp_2046, mantissa_max };
		out_inf <= inf_round_down_trigger ? inf_round_down : { exp_2047, 52'b0 };
		out_0 <= underflow_trigger ? { in_except[63], 63'b0 } : in_except;
		out_1 <= out_inf_trigger ? { in_except[63], out_inf } : out_0;
		out_2 <= NaN_out_trigger ? { in_except[63], NaN_output} : out_1;
		end
end 
always @(posedge clk)
begin
	if (rst) begin
		ref_ex_enable <= 0;
		ref_underflow <= 0;
		ref_overflow <= 0;	   
		ref_inexact <= 0;
		ref_exception <= 0;
		ref_invalid <= 0;
		ref_out <= 0;
		end
	else if (enable) begin
		ref_ex_enable <= enable_trigger;
		ref_underflow <= underflow_trigger;
		ref_overflow <= overflow_trigger;	   
		ref_inexact <= inexact_trigger;
		ref_exception <= except_trigger;
		ref_invalid <= invalid_trigger;
		ref_out <= out_2;
		end
end 
endmodule




 `timescale 1ns / 1ps

module tb;

    // Parameters
    parameter CLK_PERIOD = 10; // Clock period

    // Inputs
    reg clk;
    reg rst;
    reg enable;
    reg [1:0] rmode;
    reg [63:0] opa;
    reg [63:0] opb;
    reg [63:0] in_except;
    reg [11:0] exponent_in;
    reg [1:0] mantissa_in;
    reg [2:0] fpu_op;

    // Outputs
    wire [63:0] ref_out;
    wire ref_ex_enable;
    wire ref_underflow;
    wire ref_overflow;
    wire ref_inexact;
    wire ref_exception;
    wire ref_invalid;

    // Outputs
    wire [63:0] dut_out;
    wire dut_ex_enable;
    wire dut_underflow;
    wire dut_overflow;
    wire dut_inexact;
    wire dut_exception;
    wire dut_invalid;

	wire match;
 	integer total_tests = 0;
	integer failed_tests = 0;

assign match = ({ref_out,ref_ex_enable,ref_underflow,ref_overflow,ref_inexact,ref_exception,ref_invalid} === ({ref_out,ref_ex_enable,ref_underflow,ref_overflow,ref_inexact,ref_exception,ref_invalid} ^ {dut_out,dut_ex_enable,dut_underflow,dut_overflow,dut_inexact,dut_exception,dut_invalid} ^ {ref_out,ref_ex_enable,ref_underflow,ref_overflow,ref_inexact,ref_exception,ref_invalid}));

    // Instantiate the fpu_exceptions module
    ref_fpu_exceptions ref1(
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .rmode(rmode),
        .opa(opa),
        .opb(opb),
        .in_except(in_except),
        .exponent_in(exponent_in),
        .mantissa_in(mantissa_in),
        .fpu_op(fpu_op),
        .ref_out(ref_out),
        .ref_ex_enable(ref_ex_enable),
        .ref_underflow(ref_underflow),
        .ref_overflow(ref_overflow),
        .ref_inexact(ref_inexact),
        .ref_exception(ref_exception),
        .ref_invalid(ref_invalid)
    );

    // Instantiate the fpu_exceptions module
    fpu_exceptions uut(
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .rmode(rmode),
        .opa(opa),
        .opb(opb),
        .in_except(in_except),
        .exponent_in(exponent_in),
        .mantissa_in(mantissa_in),
        .fpu_op(fpu_op),
        .out(dut_out),
        .ex_enable(dut_ex_enable),
        .underflow(dut_underflow),
        .overflow(dut_overflow),
        .inexact(dut_inexact),
        .exception(dut_exception),
        .invalid(dut_invalid)
    );

    // Generate clock signal
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // Test Procedure
    initial begin
        // Initialize inputs
        rst = 1;
        enable = 0;
        rmode = 2'b00; // Round to nearest
        opa = 64'h4000000000000000; // 2.0
        opb = 64'h4000000000000000; // 2.0
        in_except = 64'h0; // No exceptions
        exponent_in = 12'h7FF; // Example exponent
        mantissa_in = 2'b00; // Example mantissa
        fpu_op = 3'b000; // Example operation (addition)

        // Apply reset
        #(CLK_PERIOD);
        rst = 0; // De-assert reset
        #(CLK_PERIOD);

        // Test Case 1: Normal operation
        enable = 1;
        #(CLK_PERIOD);
        
        // Check outputs
        if (dut_ex_enable) begin
            $display("Test Case 1 Passed: Exception enabled.");
        end else begin
            $display("Test Case 1 Failed: Exception not enabled.");
        end

        // Test Case 2: Division by zero
        opa = 64'h4000000000000000; // 2.0
        opb = 64'h0000000000000000; // 0.0
        fpu_op = 3'b011; // Division
        #(CLK_PERIOD);
	compare();
        
        if (dut_exception && dut_overflow) begin
            $display("Test Case 2 Passed: Division by zero exception triggered.");
        end else begin
            $display("Test Case 2 Failed: Division by zero exception not triggered.");
        end

        // Test Case 3: Overflow
        opa = 64'h7FF0000000000000; // Positive infinity
        opb = 64'h4000000000000000; // 2.0
        fpu_op = 3'b000; // Addition
        #(CLK_PERIOD);
	compare();

        if (dut_overflow) begin
            $display("Test Case 3 Passed: Overflow exception triggered.");
        end else begin
            $display("Test Case 3 Failed: Overflow exception not triggered.");
        end

        // Test Case 4: Invalid operation (SNaN)
        opa = 64'h7FFFFFFFFFFFFFFF; // SNaN
        opb = 64'h4000000000000000; // 2.0
        #(CLK_PERIOD);
	compare();

    // Test Case 5: Basic Addition
    rmode = 2'b00; // Round to nearest
    opa = 64'h3FF0000000000000; // 1.0
    opb = 64'h3FF0000000000000; // 1.0
    in_except = 64'b0;
    exponent_in = 12'b0;
    mantissa_in = 2'b0;
    fpu_op = 3'b000; // Addition
    #CLK_PERIOD;
    $display("Test Case 1: Basic Addition - ref_out = %h", ref_out);
compare();

    // Test Case 6: Basic Subtraction
    opa = 64'h3FF0000000000000; // 1.0
    opb = 64'h3FF0000000000000; // 1.0
    fpu_op = 3'b001; // Subtraction
    #CLK_PERIOD;
    $display("Test Case 2: Basic Subtraction - ref_out = %h", ref_out);
compare();

    // Test Case 7: Basic Multiplication
    opa = 64'h3FF0000000000000; // 1.0
    opb = 64'h3FF0000000000000; // 1.0
    fpu_op = 3'b010; // Multiplication
    #CLK_PERIOD;
    $display("Test Case 3: Basic Multiplication - ref_out = %h", ref_out);
compare();

    // Test Case 8: Basic Division
    opa = 64'h3FF0000000000000; // 1.0
    opb = 64'h3FF0000000000000; // 1.0
    fpu_op = 3'b011; // Division
    #CLK_PERIOD;
    $display("Test Case 4: Basic Division - ref_out = %h", ref_out);
compare();

    // Test Case 9: Division by Zero
    opa = 64'h3FF0000000000000; // 1.0
    opb = 64'h0000000000000000; // 0.0
    fpu_op = 3'b011; // Division
    #CLK_PERIOD;
    $display("Test Case 5: Division by Zero - ref_out = %h", ref_out);
compare();

    // Test Case 10: QNaN Input
    opa = 64'h7FF8000000000000; // QNaN
    opb = 64'h3FF0000000000000; // 1.0
    fpu_op = 3'b000; // Addition
    #CLK_PERIOD;
    $display("Test Case 6: QNaN Input - ref_out = %h", ref_out);
compare();

    // Test Case 11: SNaN Input
    opa = 64'h7FF0000000000000; // SNaN
    opb = 64'h3FF0000000000000; // 1.0
    fpu_op = 3'b000; // Addition
    #CLK_PERIOD;
    $display("Test Case 7: SNaN Input - ref_out = %h", ref_out);
compare();

    // Test Case 12: Positive Infinity
    opa = 64'h7FF0000000000000; // +Inf
    opb = 64'h3FF0000000000000; // 1.0
    fpu_op = 3'b000; // Addition
    #CLK_PERIOD;
    $display("Test Case 8: Positive Infinity - ref_out = %h", ref_out);
compare();

    // Test Case 13: Negative Infinity
    opa = 64'hFFF0000000000000; // -Inf
    opb = 64'h3FF0000000000000; // 1.0
    fpu_op = 3'b000; // Addition
    #CLK_PERIOD;
    $display("Test Case 9: Negative Infinity - ref_out = %h", ref_out);
compare();

    // Test Case 14: Overflow
    opa = 64'h7FEFFFFFFFFFFFFF; // Large positive number
    opb = 64'h7FEFFFFFFFFFFFFF; // Large positive number
    fpu_op = 3'b000; // Addition
    #CLK_PERIOD;
    $display("Test Case 10: Overflow - ref_out = %h", ref_out);
compare();

    // Test Case 15: Underflow
    opa = 64'h0010000000000000; // Small positive number
    opb = 64'h0010000000000000; // Small positive number
    fpu_op = 3'b010; // Multiplication
    #CLK_PERIOD;
    $display("Test Case 11: Underflow - ref_out = %h", ref_out);
compare();

    // Test Case 16: Inexact Result
    opa = 64'h3FF0000000000001; // 1.0 + epsilon
    opb = 64'h3FF0000000000001; // 1.0 + epsilon
    fpu_op = 3'b000; // Addition
    #CLK_PERIOD;
    $display("Test Case 12: Inexact Result - ref_out = %h", ref_out);
compare();

    // Test Case 17: Invalid Operation
    opa = 64'h7FF0000000000000; // SNaN
    opb = 64'h7FF0000000000000; // SNaN
    fpu_op = 3'b000; // Addition
    #CLK_PERIOD;
    $display("Test Case 13: Invalid Operation - ref_out = %h", ref_out); 
compare();       

        if (dut_invalid) begin
            $display("Test Case 4 Passed: Invalid operation exception triggered.");
        end else begin
            $display("Test Case 4 Failed: Invalid operation exception not triggered.");
        end


   repeat (96) begin
      @(posedge clk);
	clk = $random;
	rst = $random;
	enable = $random;
	rmode = $random;
	opa = $random;
	opb = $random;
	in_except = $random;
	exponent_in = $random;
	mantissa_in = $random;
	fpu_op = $random;
     
      compare();
    end
     compare();


 $display("All tests passed: design passed");
        $display("\033[1;34mTotal testcases: %d, Failed testcases: %d\033[0m", total_tests, failed_tests);
        // Finish simulation

    if (failed_tests==0) begin
            $display("=====================Your Design Passed======================");
    end
        #(CLK_PERIOD * 10);
        $finish;
    end

task compare;
        total_tests = total_tests + 1;
        if (match)                                //condition to check DUT outputs and calculated 
                                                    //outputs from task are equal 
			begin				//$display("\033[1;32mtestcase is passed!!!\033[0m");
				//$display("testcase is passed!!!");
			end

		else begin
			//$display("\033[1;31mtestcase is failed!!!\033[0m");
            failed_tests = failed_tests + 1; 
		end
	
endtask
endmodule
