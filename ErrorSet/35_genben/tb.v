 `timescale 1ns/1ns
 
module FSM_ref (
	input clk,
	input rst_n,
	input [3:0] in_m,
	output reg goods_ref,
	output reg [3:0] out_m_ref
);
 
reg [4:0] CS, NS;
 
parameter [4:0]
	IDLE = 'b00001,
	S0   = 'b00010,
	S1   = 'b00100,
	S2   = 'b01000,
	S3   = 'b10000;
//第一always块，同步时序逻辑
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n)
		CS <= IDLE;
	else
		CS <= NS;
end
//第二always块，组合逻辑
always @ (*) begin
	case (CS)
		IDLE:
			if (in_m == 4'd1)		NS = S0;
			else if (in_m == 4'd2)	NS = S1;
			else if (in_m == 4'd5)	NS = IDLE;
			else					NS = IDLE;
		
		S0:
			if (in_m == 4'd1)		NS = S1;
			else if (in_m == 4'd2)	NS = S2;
			else if (in_m == 4'd5)	NS = IDLE;
			else					NS = S0;
		
		S1:
			if (in_m == 4'd1)		NS = S2;
			else if (in_m == 4'd2)	NS = S3;
			else if (in_m == 4'd5)	NS = IDLE;
			else					NS = S1;
		
		S2:
			if (in_m == 4'd1)		NS = S3;
			else if (in_m == 4'd2)	NS = IDLE;
			else if (in_m == 4'd5)	NS = IDLE;
			else					NS = S2;
		
		S3:
			if (in_m == 4'd1)		NS = IDLE;
			else if (in_m == 4'd2)	NS = IDLE;
			else if (in_m == 4'd5)	NS = IDLE;
			else					NS = S3;
	
		default:
			NS = IDLE;
	endcase
end
 
//第三always块，同步时序逻辑
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		out_m_ref <= 'd0;
		goods_ref <= 'd0;
	end
	else begin
		case (CS)
			IDLE: begin
				out_m_ref <= 'd0;
				if (in_m == 'd5)    goods_ref <= 'd1;
				else                goods_ref<= 'd0;
			end
			
			S0: begin
				out_m_ref <= 'd0;
				if (in_m == 'd1 || in_m == 'd2) begin
					goods_ref <= 'd0;
					out_m_ref <= 'd0;
				end
				else begin
					goods_ref <= 'd1;
					out_m_ref <= 'd1;
				end
			end
			
			S1: begin
				out_m_ref <= 'd0;
				if (in_m == 'd1 || in_m == 'd2) begin
					goods_ref <= 'd0;
					out_m_ref <= 'd0;
				end
				else begin
					goods_ref <= 'd1;
					out_m_ref <= 'd2;
				end
			end
				
			S2: begin
				out_m_ref <= 'd0;
				if (in_m == 'd1) begin
					goods_ref <= 'd0;
					out_m_ref <= 'd0;
				end
				else if (in_m == 'd2) begin
					goods_ref <= 'd1;
					out_m_ref <= 'd0;
				end
				else begin
					goods_ref <= 'd1;
					out_m_ref <= 'd3;
				end
			end
			
			S3: begin
				goods_ref <= 'd1;
				if (in_m == 'd1)		out_m_ref <= 'd0;
				else if (in_m == 'd2)	out_m_ref <= 'd1;
				else					out_m_ref <= 'd4;
			end
			
			default: begin
				goods_ref <= 'd1;
				out_m_ref <= 'd0;
			end
		endcase
	end
end
endmodule



 `timescale 1ns/1ns

module tb;

    // Signal Declarations
    reg clk;
    reg rst_n;
    reg [3:0] in_m;
    wire [3:0] out_m_ref, out_m_dut;
    wire goods_ref, goods_dut;
    wire match;
    reg [3:0] m[3:0];
    reg [1:0] index;

    initial begin
    m[0] = 1;
    m[1] = 2;
    m[2] = 5;
    end
    
    integer total_tests = 0;
	integer failed_tests = 0;

    assign match = ({goods_ref, out_m_ref} === ({goods_ref, out_m_ref} ^ {goods_dut, out_m_dut} ^ {goods_ref, out_m_ref}));
    // Instantiate the DUT (Device Under Test)

    FSM_ref ref_model (
        .clk(clk),
        .rst_n(rst_n),
        .in_m(in_m),
        .goods_ref(goods_ref),
        .out_m_ref(out_m_ref)
    );
    FSM uut (
        .clk(clk),
        .rst_n(rst_n),
        .in_m(in_m),
        .goods(goods_dut),
        .out_m(out_m_dut)
    );

    // Clock Generation
    always #20 clk = ~clk;  // Clock toggles every 20 ns

    // Initialization Block
    initial begin
        rst_n = 1'b0;
        clk = 1'b0;
        #50 rst_n = 1'b1;  // Release reset after 50 ns
    end

    // Testbench Stimulus
    initial begin
        in_m = 4'b0000;
        #50;
        @(posedge clk);
        repeat(100) begin
            index = $urandom_range(0,2);
            in_m = m[index];
            @(posedge clk);
            compare();
        end
        repeat(100) begin
            in_m = $random;
            @(posedge clk);
            compare();
        end

        @(posedge clk);
        rst_n = 0;
        @(posedge clk);
        rst_n = 1;
        @(posedge clk);
        $display("\033[1;34mTotal testcases: %d, Failed testcases: %d\033[0m", total_tests, failed_tests);
        if (failed_tests==0) begin
            $display("=====================Your Design Passed======================");
        end
        $finish;  // Stop simulation
    end

    // VCD Dump for Waveform Viewing
    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb);
    end

    task compare;
        begin
        total_tests = total_tests + 1;

        if (match)                                //condition to check DUT outputs and calculated 
                                                    //outputs from task are equal 
			begin
				//$display("\033[1;32mtestcase is passed!!!\033[0m");
            	//$display("rst_n = %b, in_m = %b, goods_dut = %b, out_m_dut = %b, goods_ref = %b, out_m_ref = %b", rst_n, in_m, goods_dut, out_m_dut, goods_ref, out_m_ref);      //displaying inputs, outputs and result
			end

		else begin
			//$display("\033[1;31mtestcase is failed!!!\033[0m");
            //$display("rst_n = %b, in_m = %b, goods_dut = %b, out_m_dut = %b, goods_ref = %b, out_m_ref = %b", rst_n, in_m, goods_dut, out_m_dut, goods_ref, out_m_ref);      //displaying inputs, outputs and result
            failed_tests = failed_tests + 1; 
		end
        end
	endtask


endmodule

