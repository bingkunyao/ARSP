
module ref_tbu
(
   clk,
   rst,
   enable,
   selection,
   d_in_0,
   d_in_1,
   ref_d_o,
   ref_wr_en
);
   input       clk;
   input       rst;
   input       enable;
   input       selection;
   input [7:0] d_in_0;
   input [7:0] d_in_1;
   output reg  ref_d_o;
   output reg  ref_wr_en;
   reg         d_o_reg;
   reg         wr_en_reg;
   reg   [2:0] pstate;
   reg   [2:0] nstate;
   reg         selection_buf;
   always @(posedge clk)
   begin
      selection_buf  <= selection;
      ref_wr_en          <= wr_en_reg;
      ref_d_o            <= d_o_reg;
   end
   always @(posedge clk or negedge rst)
   begin
      if(rst==1'b0)
         pstate   <= 3'b000;
      else if(enable==1'b0)
         pstate   <= 3'b000;
      else if(selection_buf==1'b1 && selection==1'b0)
         pstate   <= 3'b000;
      else
         pstate   <= nstate;
   end
   always @(*)
   begin
      case (pstate)
         3'b000:
         begin
            if(selection==1'b0)
            begin
               wr_en_reg =  1'b0;
               case(d_in_0[0])
                  1'b0: nstate   =  3'b000;
                  1'b1: nstate   =  3'b001;
               endcase
            end
            else
            begin
               d_o_reg   =  d_in_1[0];  
               wr_en_reg =  1'b1;
               case(d_in_1[0])
                  1'b0: nstate   =  3'b000;
                  1'b1: nstate   =  3'b001;
               endcase
           end
         end
         3'b001:
         begin
            if(selection==1'b0)
             begin
             wr_en_reg =  1'b0;
               case(d_in_0[1])
                  1'b0: nstate   =  3'b011;
                  1'b1: nstate   =  3'b010;
               endcase
            end
            else
            begin
               d_o_reg   =  d_in_1[1];  
               wr_en_reg =  1'b1;
               case(d_in_1[1])
                  1'b0: nstate   =  3'b011;
                  1'b1: nstate   =  3'b010;
               endcase
           end
         end
         3'b010:
         begin
            if(selection==1'b0)
            begin
               wr_en_reg =  1'b0;
               case(d_in_0[2])
                  1'b0: nstate   =  3'b100;
                  1'b1: nstate   =  3'b101;
               endcase
            end
            else
            begin
               d_o_reg   =  d_in_1[2];  
               wr_en_reg =  1'b1;
               case(d_in_1[2])
                  1'b0: nstate   =  3'b100;
                  1'b1: nstate   =  3'b101;
               endcase
            end
         end
         3'b011:
         begin
            if(selection==1'b0)
            begin
               wr_en_reg =  1'b0;
               case(d_in_0[3])
                  1'b0: nstate   =  3'b111;
                  1'b1: nstate   =  3'b110;
               endcase
            end
            else
            begin
               d_o_reg   =  d_in_1[3]; 
               wr_en_reg =  1'b1;
               case(d_in_1[3])
                  1'b0: nstate   =  3'b111;
                  1'b1: nstate   =  3'b110;
               endcase
            end
         end
         3'b100:
         begin
            if(selection==1'b0)
            begin
               wr_en_reg =  1'b0;
               case(d_in_0[4])
                  1'b0: nstate   =  3'b001;
                  1'b1: nstate   =  3'b000;
               endcase
            end
            else
            begin
               d_o_reg   =  d_in_1[4];  
               wr_en_reg =  1'b1;
               case(d_in_1[4])
                  1'b0: nstate   =  3'b001;
                  1'b1: nstate   =  3'b000;
               endcase
            end
         end
         3'b101:
         begin
            if(selection==1'b0)
            begin
               wr_en_reg =  1'b0;
               case(d_in_0[5])
                  1'b0: nstate   =  3'b010;
                  1'b1: nstate   =  3'b011;
               endcase
            end
            else
            begin
               d_o_reg   =  d_in_1[5];  
               wr_en_reg =  1'b1;
               case(d_in_1[5])
                  1'b0: nstate   =  3'b010;
                  1'b1: nstate   =  3'b011;
               endcase
            end
         end
         3'b110:
         begin
            if(selection==1'b0)
            begin
               wr_en_reg =  1'b0;
               case(d_in_0[6])
                  1'b0: nstate   =  3'b101;
                  1'b1: nstate   =  3'b100;
               endcase
            end
            else
            begin
               d_o_reg   =  d_in_1[6];  
               wr_en_reg =  1'b1;
               case(d_in_1[6])
                  1'b0: nstate   =  3'b101;
                  1'b1: nstate   =  3'b100;
               endcase
            end
         end
         3'b111:
         begin
            if(selection==1'b0)
            begin
               wr_en_reg =  1'b0;
               case(d_in_0[7])
                  1'b0: nstate   =  3'b110;
                  1'b1: nstate   =  3'b111;
               endcase
            end
            else
            begin
               d_o_reg   =  d_in_1[7];  
               wr_en_reg =  1'b1;
               case(d_in_1[7])
                  1'b0: nstate   =  3'b110;
                  1'b1: nstate   =  3'b111;
               endcase
            end
         end
      endcase
   end
endmodule




`timescale 1ns / 1ps

module tb;

// Inputs
reg clk;
reg rst;
reg enable;
reg selection;
reg [7:0] d_in_0;
reg [7:0] d_in_1;

// Outputs
wire d_o,ref_d_o;
wire wr_en,ref_wr_en;

wire       match;
integer    total_tests = 0;
integer    failed_tests = 0;
integer    passed_tests = 0;

reg    [2:0] pstate;

assign match = ({ref_d_o, ref_wr_en} === {d_o, wr_en});

// Instantiate the Unit Under Test (UUT)
tbu uut (
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .selection(selection),
    .d_in_0(d_in_0),
    .d_in_1(d_in_1),
    .d_o(d_o),
    .wr_en(wr_en)
);

ref_tbu ref_model (
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .selection(selection),
    .d_in_0(d_in_0),
    .d_in_1(d_in_1),
    .ref_d_o(ref_d_o),
    .ref_wr_en(ref_wr_en)
);

// Clock generation
initial begin
    clk = 0;
    forever #5 clk = ~clk; // 100 MHz clock
end

// Test procedure
initial begin
    // Initialize Inputs
    rst = 1;
    enable = 0;
    selection = 0;
    d_in_0 = 8'b00000000;
    d_in_1 = 8'b00000000;

    // Wait for reset
    #20;
    rst = 0;
    compare();

    // Test Case 1: Write from d_in_0
    enable = 1;
    d_in_0 = 8'b10101010;
    selection = 0;
    #10;
    compare();
    check_output(0, 1'b0, "Test Case 1: Write from d_in_0");

    // Test Case 2: Write from d_in_1
    d_in_1 = 8'b11001100;
    selection = 1;
    #10;
    compare();
    check_output(1, 1'b1, "Test Case 2: Write from d_in_1");

    // Test Case 3: Reset
    rst = 1;
    #10;
    compare();
    check_output(0, 1'b0, "Test Case 3: Reset");
    rst = 0;

    // Test Case 4: Enable Low
    enable = 0;
    #10;
    compare();
    check_output(0, 1'b0, "Test Case 4: Enable Low");

    // Test Case 5: Transition Test
    enable = 1;
    selection = 1;
    d_in_1 = 8'b00000001;
    #10;
    compare();
    check_output(1, 1'b1, "Test Case 5: Transition Test");

    // Display overall result
    if (passed_tests == total_tests) begin
        //$display("All tests passed: design passed");
    end else begin
        //$display("%d out of %d tests passed: debug failed", passed_tests, total_tests);
    end

repeat(400) begin
         #10;
        rst = 0;
         #10;

        enable = 1;

         #10;
        test_state(3'b000);
        compare();

         #10;
        test_state(3'b001);
        compare();

         #10;
        test_state(3'b010);
        compare();

         #10;
        test_state(3'b011);
        compare();

         #10;
        test_state(3'b100);
        compare();

         #10;
        test_state(3'b101);
        compare();

         #10;
        test_state(3'b110);
        compare();

         #10;
        test_state(3'b111);
        compare();
end
    
    $display("\033[1;34mAll tests completed.\033[0m");
    $display("\033[1;34mTotal testcases: %d, Failed testcases: %d\033[0m", total_tests, failed_tests);
    if (failed_tests==0) begin
            $display("=====================Your Design Passed======================");
    end
    $finish;
end


    task test_state;
        input [2:0] state;
        begin
            force uut.pstate = state;
            force ref_model.pstate = state;
            selection = 0;
            d_in_0 = $random;
            d_in_1 = $random;
            #10; 
            selection = 1;
            d_in_0 = $random;
            d_in_1 = $random;
            #10;
            release uut.pstate;
        end
    endtask


// Helper task to check outputs
task check_output(input expected_d_o, input expected_wr_en, input [128*8:1] test_name);
    begin
    total_tests = total_tests + 1;
    if (d_o !== expected_d_o || wr_en !== expected_wr_en) begin
        //$display("Test failed: %s - Expected d_o = %b, wr_en = %b, Got d_o = %b, wr_en = %b", test_name, expected_d_o, expected_wr_en, d_o, wr_en);
    end else begin
        //$display("Test passed: %s", test_name);
        passed_tests = passed_tests + 1;
    end
    end
endtask

task compare;
 begin
     total_tests = total_tests + 1;
     if (match)                                //condition to check DUT outputs and calculated 
                                                    //outputs from task are equal 
	   begin
	   //$display("\033[1;32mtestcase is passed!!!\033[0m");
	   end
	   else begin
	   //$display("\033[1;31mtestcase is failed!!!\033[0m");
         failed_tests = failed_tests + 1; 
         end
        end
endtask

endmodule

