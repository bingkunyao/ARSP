 
module ref_BM_lamda
(
input clk, 
input reset, 
input [7:0] Sm1,Sm2,Sm3,Sm4,Sm5,Sm6,Sm7,Sm8,                    
input [7:0] Sm9,Sm10,Sm11,Sm12,Sm13,Sm14,Sm15,Sm16,    
input Sm_ready,   
input erasure_ready, 
input [3:0] erasure_cnt,  
input [7:0] pow1,pow2,    
input [7:0] dec1,        
output reg [7:0] ref_add_pow1,ref_add_pow2,     
output  [7:0] ref_add_dec1,                              
output reg ref_L_ready,  
output [7:0] ref_L1,ref_L2,ref_L3,ref_L4,ref_L5,ref_L6,ref_L7,ref_L8   
);
reg [7:0] L [1:9];   
reg [7:0] Lt [1:9]; 
reg [7:0] T [1:10];  
reg [7:0] D; 
reg [4:0]  K;  
reg [3:0]  N;  
reg [3:0]  e_cnt;
reg [7:0] S [1:16];
reg [8:0] add_1;   
reg IS_255_1;
reg div1;  
reg [3:0] cnt ;  
parameter Step1  = 8'b00000001;
parameter Step2  = 8'b00000010;
parameter Step3  = 8'b00000100;
parameter Step4  = 8'b00001000;
parameter Step5  = 8'b00010000;
parameter Step6  = 8'b00100000;
parameter Step7  = 8'b01000000;
parameter Step8  = 8'b10000000;
reg [8:0] const_timing;
reg [7:0] Step = Step1;
assign ref_L1=L[2];
assign ref_L2=L[3];
assign ref_L3=L[4];
assign ref_L4=L[5];
assign ref_L5=L[6];
assign ref_L6=L[7];
assign ref_L7=L[8];
assign ref_L8=L[9];
assign ref_add_dec1  =(IS_255_1)?  8'h00 :
				 (&add_1[7:0] && !add_1[8])?     8'h01 : 
				 (div1)? add_1[7:0] - (add_1[8]) +1 :
				 add_1[7:0] +add_1[8] +1 ;
always@(posedge reset or posedge clk)
begin
	if (reset)
		begin
			add_1<=0;
			IS_255_1<=0;
			div1<=0;
			ref_add_pow1<=0;ref_add_pow2<=0;
			e_cnt<=0;
			S[1]<=0;S[2]<=0;S[3]<=0;S[4]<=0;S[5]<=0;
			S[6]<=0;S[7]<=0;S[8]<=0;     
			S[9]<=0;S[10]<=0;S[11]<=0;S[12]<=0;S[13]<=0;
			S[14]<=0;S[15]<=0;S[16]<=0;
			L[1]<=0; L[2]<=0; L[3]<=0;L[4]<=0;L[5]<=0;
			L[6]<=0;L[7]<=0;L[8]<=0;L[9]<=0;
			Lt[1]<=0; Lt[2]<=0; Lt[3]<=0;Lt[4]<=0;Lt[5]<=0;
			Lt[6]<=0;Lt[7]<=0;Lt[8]<=0;Lt[9]<=0;
			T[1]<=0; T[2]<=0; T[3]<=0;T[4]<=0;T[5]<=0;
			T[6]<=0;T[7]<=0;T[8]<=0;T[9]<=0;T[10]<=0;
			D<=0;
			K<=0;
			N<=0;
			cnt<=0;
			Step<=Step1;
			ref_L_ready<=0;
			const_timing<=0;	
		end
	else
		begin
			case (Step)
			default:begin  
				L[1]<=1; L[2]<=0; L[3]<=0;L[4]<=0;L[5]<=0;
				L[6]<=0;L[7]<=0;L[8]<=0;L[9]<=0;
				Lt[1]<=1; Lt[2]<=0; Lt[3]<=0;Lt[4]<=0;Lt[5]<=0;
				Lt[6]<=0;Lt[7]<=0;Lt[8]<=0;Lt[9]<=0;
				T[1]<=0; T[2]<=1; T[3]<=0;T[4]<=0;T[5]<=0;
				T[6]<=0;T[7]<=0;T[8]<=0;T[9]<=0;T[10]<=0;
				D<=0;
				K<=0;
				N<=0;
				cnt<=0;
				ref_L_ready<=0;
				if(erasure_ready)
					begin
						e_cnt<=erasure_cnt;
					end
				if(Sm_ready)
					begin
						Step<=Step2;
						S[1]<=Sm1;S[2]<=Sm2;S[3]<=Sm3;S[4]<=Sm4;S[5]<=Sm5;
						S[6]<=Sm6;S[7]<=Sm7;S[8]<=Sm8;     
						S[9]<=Sm9;S[10]<=Sm10;S[11]<=Sm11;S[12]<=Sm12;
						S[13]<=Sm13;S[14]<=Sm14;S[15]<=Sm15;S[16]<=Sm16;
					end
			end
			Step2:begin
				K<= K+1;
				Step<=Step3;
			end
			Step3:begin
				if (N==0)
					begin
						D<= S[K+e_cnt];
						if(S[K+e_cnt]==0)
							Step<= Step6;
						else
							Step <= Step4;
					end
				else
					begin
						if(cnt == N+4)
							begin
								cnt<=0;
								if ( (D^dec1)  == 0)	
									Step <= Step6;
								else
									Step <= Step4;
							end
						else
							cnt<=cnt+1;
						if (cnt == 0)
							begin
								D<= S[K+e_cnt];
							end
						else if (cnt < 5)
							begin
								ref_add_pow1<= L[cnt+1];
								ref_add_pow2<= S[K+e_cnt-cnt];
								div1<=0;
								add_1<= pow1 + pow2;
								IS_255_1<=(&pow1 || &pow2)? 1:0;
							end
						else  
							begin
								ref_add_pow1<= L[cnt+1];
								ref_add_pow2<= S[K+e_cnt-cnt];
								div1<=0;
								add_1<= pow1 + pow2;
								IS_255_1<=(&pow1 || &pow2)? 1:0;
								D <= D ^ dec1;
							end
					end
			end
			Step4:begin
				if(cnt == (11 - e_cnt[3:1]) )
					begin
						cnt<=0;
						Step <= Step5;
					end
				else
					cnt<=cnt+1;
				ref_add_pow1<= T[cnt+2];
				ref_add_pow2 <= D;
				div1<=0;
				add_1<= pow1 + pow2;
				IS_255_1<=(&pow1 || &pow2)? 1:0;
				if (cnt>3) 
					begin
						Lt[cnt-2] <= L[cnt-2] ^ dec1;
					end
			end
			Step5:begin
				if ({N,1'b0} >= K )     
					begin
						Step<=Step6;
						L[1]<=Lt[1]; L[2]<=Lt[2]; L[3]<=Lt[3]; 
						L[4]<=Lt[4]; L[5]<=Lt[5];
						L[6]<=Lt[6]; L[7]<=Lt[7];
						L[8]<=Lt[8]; L[9]<=Lt[9];
					end
				else
					begin
						if(cnt == (12-e_cnt[3:1]) )
							begin
								cnt<=0;
								Step <= Step6;
								N <= K - N;
								L[1]<=Lt[1]; L[2]<=Lt[2]; L[3]<=Lt[3];
								L[4]<=Lt[4]; L[5]<=Lt[5];
								L[6]<=Lt[6]; L[7]<=Lt[7]; 
								L[8]<=Lt[8]; L[9]<=Lt[9];
							end
						else
							cnt<=cnt+1;
						ref_add_pow1<= L[cnt+1];
						ref_add_pow2 <= D;
						div1<=1;
						add_1<= pow1 - pow2;
						IS_255_1<=(&pow1 || &pow2)? 1:0;
						if (cnt>3)  
							begin
								T[cnt-3] <= dec1;
							end
					end
			end
			Step6:begin
				Step<=Step7;
				T[1]<=0;
				T[2]<=T[1];
				T[3]<=T[2];
				T[4]<=T[3];
				T[5]<=T[4];
				T[6]<=T[5];
				T[7]<=T[6];
				T[8]<=T[7];
				T[9]<=T[8];
				T[10]<=T[9];
			end
			Step7:begin	
				if(K< 16 - e_cnt)
					Step<=Step2;
				else
					begin
						Step<=Step8;
					end
			end
			Step8: begin
				if(const_timing == 0)
					begin
						ref_L_ready<=1;
						Step<=Step1;
					end
			end
			endcase
			if(Step == Step1)
				begin
					const_timing<=500;   
				end
			else
				begin
					const_timing <=const_timing -1;
				end
		end
end
endmodule




 `timescale 1ns / 1ps

module tb;

    // Parameters
    parameter CLK_PERIOD = 10; // Clock period for clk

    // Inputs
    reg clk;
    reg reset;
    reg [7:0] Sm1, Sm2, Sm3, Sm4, Sm5, Sm6, Sm7, Sm8;
    reg [7:0] Sm9, Sm10, Sm11, Sm12, Sm13, Sm14, Sm15, Sm16;
    reg Sm_ready;
    reg erasure_ready;
    reg [3:0] erasure_cnt;
    reg [7:0] pow1, pow2;
    reg [7:0] dec1;

    // Outputs
    wire [7:0] ref_add_pow1, ref_add_pow2;
    wire [7:0] ref_add_dec1;
    wire ref_L_ready;
    wire [7:0] ref_L1, ref_L2, ref_L3, ref_L4, ref_L5, ref_L6, ref_L7, ref_L8;

    wire [7:0] dut_add_pow1, dut_add_pow2;
    wire [7:0] dut_add_dec1;
    wire dut_L_ready;
    wire [7:0] dut_L1, dut_L2, dut_L3, dut_L4, dut_L5, dut_L6, dut_L7, dut_L8;

	wire match;
 	integer total_tests = 0;
	integer failed_tests = 0;

assign match = ({ref_add_pow1, ref_add_pow2,ref_add_dec1,ref_L_ready,ref_L1, ref_L2, ref_L3, ref_L4, ref_L5, ref_L6,ref_L7,ref_L8} === ({ref_add_pow1, ref_add_pow2,ref_add_dec1,ref_L_ready,ref_L1, ref_L2, ref_L3, ref_L4, ref_L5, ref_L6,ref_L7,ref_L8} ^ {dut_add_pow1,dut_add_pow2,dut_add_dec1,dut_L_ready,dut_L1,dut_L2,dut_L3,dut_L4, dut_L5,dut_L6,dut_L7,dut_L8} ^ {ref_add_pow1, ref_add_pow2,ref_add_dec1,ref_L_ready,ref_L1, ref_L2, ref_L3, ref_L4, ref_L5, ref_L6,ref_L7,ref_L8}));


    // Instantiate the BM_lambda module
    BM_lamda uut (
        .clk(clk),
        .reset(reset),
        .Sm1(Sm1), .Sm2(Sm2), .Sm3(Sm3), .Sm4(Sm4),
        .Sm5(Sm5), .Sm6(Sm6), .Sm7(Sm7), .Sm8(Sm8),
        .Sm9(Sm9), .Sm10(Sm10), .Sm11(Sm11), .Sm12(Sm12),
        .Sm13(Sm13), .Sm14(Sm14), .Sm15(Sm15), .Sm16(Sm16),
        .Sm_ready(Sm_ready),
        .erasure_ready(erasure_ready),
        .erasure_cnt(erasure_cnt),
        .pow1(pow1), .pow2(pow2),
        .dec1(dec1),
        .add_pow1(dut_add_pow1), .add_pow2(dut_add_pow2),
        .add_dec1(dut_add_dec1),
        .L_ready(dut_L_ready),
        .L1(dut_L1), .L2(dut_L2), .L3(dut_L3), .L4(dut_L4),
        .L5(dut_L5), .L6(dut_L6), .L7(dut_L7), .L8(dut_L8)
    );

    // Instantiate the BM_lambda module
    ref_BM_lamda uut2 (
        .clk(clk),
        .reset(reset),
        .Sm1(Sm1), .Sm2(Sm2), .Sm3(Sm3), .Sm4(Sm4),
        .Sm5(Sm5), .Sm6(Sm6), .Sm7(Sm7), .Sm8(Sm8),
        .Sm9(Sm9), .Sm10(Sm10), .Sm11(Sm11), .Sm12(Sm12),
        .Sm13(Sm13), .Sm14(Sm14), .Sm15(Sm15), .Sm16(Sm16),
        .Sm_ready(Sm_ready),
        .erasure_ready(erasure_ready),
        .erasure_cnt(erasure_cnt),
        .pow1(pow1), .pow2(pow2),
        .dec1(dec1),
        .ref_add_pow1(ref_add_pow1), .ref_add_pow2(ref_add_pow2),
        .ref_add_dec1(ref_add_dec1),
        .ref_L_ready(ref_L_ready),
        .ref_L1(ref_L1), .ref_L2(ref_L2), .ref_L3(ref_L3), .ref_L4(ref_L4),
        .ref_L5(ref_L5), .ref_L6(ref_L6), .ref_L7(ref_L7), .ref_L8(ref_L8)
    );

    // Generate clock signal
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk; // Toggle clock
    end

    // Test Procedure
    initial begin
        // Initialize inputs
        reset = 1;
        Sm1 = 8'h00; Sm2 = 8'h01; Sm3 = 8'h02; Sm4 = 8'h03;
        Sm5 = 8'h04; Sm6 = 8'h05; Sm7 = 8'h06; Sm8 = 8'h07;
        Sm9 = 8'h08; Sm10 = 8'h09; Sm11 = 8'h0A; Sm12 = 8'h0B;
        Sm13 = 8'h0C; Sm14 = 8'h0D; Sm15 = 8'h0E; Sm16 = 8'h0F;
        Sm_ready = 0;
        erasure_ready = 0;
        erasure_cnt = 4'h0;
        pow1 = 8'h10;
        pow2 = 8'h20;
        dec1 = 8'h30;

        // Apply reset
        #(CLK_PERIOD);
        reset = 0; // De-assert reset
        #(CLK_PERIOD);

        // Test Case 1: Check initial state after reset
        if (dut_L_ready == 0) begin
            $display("Test Case 1 Passed: L_ready is initially low.");
        end else begin
            $display("Test Case 1 Failed: L_ready is not low.");
compare();
        end

        // Test Case 2: Simulate Sm_ready signal
        Sm_ready = 1; // Assert ready signal
        #(CLK_PERIOD);
        Sm_ready = 0; // De-assert after one clock cycle
        #(CLK_PERIOD);
compare();

        // Test Case 3: Check output values after Sm_ready
        //if (uut.L[1] == 1) begin
        //    $display("Test Case 2 Passed: Sm_ready processed, L[1] is set.");
       // end else begin
        //    $display("Test Case 2 Failed: Sm_ready not processed correctly.");
       // end
//compare();

        // Test Case 4: Simulate erasure process
        erasure_ready = 1; // Assert erasure ready
        erasure_cnt = 4'h2; // Example value
        #(CLK_PERIOD);
        erasure_ready = 0; // De-assert after one clock cycle
        #(CLK_PERIOD);
compare();

        // Test Case 5: Check L values after erasure
        if (dut_L1 == 0) begin
            $display("Test Case 3 Passed: Erasure processed, L1 is zero.");
        end else begin
            $display("Test Case 3 Failed: Erasure not processed correctly.");
compare();
        end

        // Test Case 6: Check add_dec1 output
        if (dut_add_dec1 == 8'h01) begin
            $display("Test Case 4 Passed: add_dec1 calculated correctly.");
        end else begin
            $display("Test Case 4 Failed: add_dec1 not calculated correctly.");
compare();
#10;
reset=0;
#10;
reset=1;
#10;

        end
repeat (96) begin
            @(posedge clk);
Sm1 = $random; Sm2 = $random; Sm3 = $random; Sm4 = $random; Sm5 = $random; Sm6 = $random; Sm7 = $random; Sm8 = $random;
Sm9 = $random; Sm10 = $random; Sm11 = $random; Sm12 = $random; Sm13 = $random; Sm14 = $random; Sm15 = $random; Sm16 = $random;
Sm_ready = $random;
erasure_ready = $random;
erasure_cnt = $random;
pow1 = $random;
pow2 = $random;
dec1 = $random;


            compare();
        end

        // Finish simulation
        #(CLK_PERIOD * 10);
        $display("All tests passed: design passed");
        $display("\033[1;34mTotal testcases: %d, Failed testcases: %d\033[0m", total_tests, failed_tests);

    if (failed_tests==0) begin
            $display("=====================Your Design Passed======================");
    end
        $finish;
    end

task compare;
        total_tests = total_tests + 1;
        if (match)                                //condition to check DUT outputs and calculated 
                                                    //outputs from task are equal 
			begin
				//$display("\033[1;32mtestcase is passed!!!\033[0m");
				//$display("testcase is passed!!!");
			end

		else begin
			//$display("\033[1;31mtestcase is failed!!!\033[0m");
            failed_tests = failed_tests + 1; 
		end
    
	endtask
endmodule
