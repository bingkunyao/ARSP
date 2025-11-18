 
module ref_spi_master(
        clk,
        rst,
        data,
        wr,
        rd,
        ref_buffempty,
        prescaller,
        ref_sck,
        ref_mosi,
        miso,
        ref_ss,
        lsbfirst,
        mode,
        ref_senderr,
        res_senderr,
        ref_charreceived
    );
parameter WORD_LEN = 8;
parameter PRESCALLER_SIZE = 8;
input clk;
input rst;
inout [WORD_LEN - 1:0] data;
input wr;
input rd;
output ref_buffempty;
input [2:0]prescaller;
output ref_sck;
output ref_mosi;
reg _mosi;
input miso;
output reg ref_ss;
input lsbfirst;
input [1:0]mode;
output reg ref_senderr;
input res_senderr;
output ref_charreceived;
reg charreceivedp;
reg charreceivedn;
reg inbufffullp = 1'b0;
reg inbufffulln = 1'b0;
reg [WORD_LEN - 1:0]input_buffer;
reg [WORD_LEN - 1:0]output_buffer;
assign ref_buffempty = ~(inbufffullp ^ inbufffulln);
reg [2:0]prescallerbuff;
`ifdef WRITE_ON_NEG_EDGE == 1
always @ (negedge wr)
`else
always @ (posedge wr)
`endif
begin
    if(wr && inbufffullp == inbufffulln && ref_buffempty)
    begin
            input_buffer <= data;
    end
end
`ifdef WRITE_ON_NEG_EDGE == 1
always @ (negedge wr or posedge res_senderr or posedge rst)
`else
always @ (posedge wr or posedge res_senderr or posedge rst)
`endif
begin
    if(rst)
    begin
        inbufffullp <= 1'b0;
        ref_senderr <= 1'b0;
        prescallerbuff <= 3'b000;
    end
    else
    if(res_senderr)
        ref_senderr <= 1'b0;
    else
    if(wr && inbufffullp == inbufffulln && ref_buffempty)
    begin
            inbufffullp <= ~inbufffullp;
            prescallerbuff = prescaller;
    end
    else
    if(!ref_buffempty)
        ref_senderr <= 1'b1;
end
parameter state_idle = 1'b0;
parameter state_busy = 1'b1;
reg state;
reg [PRESCALLER_SIZE - 1:0]prescaller_cnt;
reg [WORD_LEN - 1:0]shift_reg_out;
reg [WORD_LEN - 1:0]shift_reg_in;
reg [4:0]sckint;
reg [2:0]prescallerint;
reg [7:0]prescdemux;
always @ (*)
begin
    if(prescallerint < PRESCALLER_SIZE)
    begin
        case(prescallerint)
        3'b000: prescdemux <= 8'b00000001;
        3'b001: prescdemux <= 8'b00000011;
        3'b010: prescdemux <= 8'b00000111;
        3'b011: prescdemux <= 8'b00001111;
        3'b100: prescdemux <= 8'b00011111;
        3'b101: prescdemux <= 8'b00111111;
        3'b110: prescdemux <= 8'b01111111;
        3'b111: prescdemux <= 8'b11111111;
        endcase
    end
    else
        prescdemux <= 8'b00000001;
end
reg lsbfirstint;
reg [1:0]modeint;
always @ (posedge clk or posedge rst)
begin
    if(rst)
    begin
        inbufffulln <= 1'b0;
        ref_ss <= 1'b1;
        state <= state_idle;
        prescaller_cnt <= {PRESCALLER_SIZE{1'b0}};
        prescallerint <= {PRESCALLER_SIZE{3'b0}};
        shift_reg_out <= {WORD_LEN{1'b0}};
        shift_reg_in <= {WORD_LEN{1'b0}};
        sckint <=  {5{1'b0}};
        _mosi <= 1'b1;
        output_buffer <= {WORD_LEN{1'b0}};
        charreceivedp <= 1'b0;
        lsbfirstint <= 1'b0;
        modeint <= 2'b00;
    end
    else
    begin
        case(state)
        state_idle:
            begin
                if(inbufffullp != inbufffulln)
                begin
                    inbufffulln <= ~inbufffulln;
                    ref_ss <= 1'b0;
                    prescaller_cnt <= {PRESCALLER_SIZE{1'b0}};
                    prescallerint <= prescallerbuff;
                    lsbfirstint <= lsbfirst;
                    modeint <= mode;
                    shift_reg_out <= input_buffer;
                    state <= state_busy;
                    if(!mode[0])
                    begin
                        if(!lsbfirst)
                            _mosi <= input_buffer[WORD_LEN - 1];
                        else
                            _mosi <= input_buffer[0];
                    end
                end
            end
        state_busy:
            begin
                if(prescaller_cnt != prescdemux)
                begin
                    prescaller_cnt <= prescaller_cnt + 1;
                end
                else
                begin
                    prescaller_cnt <= {PRESCALLER_SIZE{1'b0}};
                    sckint <= sckint + 1;
                    if(sckint[0] == modeint[0])
                    begin
                        if(!lsbfirstint)
                        begin
                            shift_reg_in <= {miso, shift_reg_in[7:1]};
                            shift_reg_out <= {shift_reg_out[6:0], 1'b1};
                        end
                        else
                        begin
                            shift_reg_in <= {shift_reg_in[6:0], miso};
                            shift_reg_out <= {1'b1, shift_reg_out[7:1]};
                        end
                    end
                    else
                    begin
                        if(!lsbfirstint)
                            _mosi <= shift_reg_out[WORD_LEN - 1];
                        else
                            _mosi <= shift_reg_out[0];
                        if(sckint[4:1] == WORD_LEN)
                        begin
                            sckint <= {5{1'b0}};
                            if(inbufffullp == inbufffulln)
                            begin
                                ref_ss <= 1'b1;
                            end
                            output_buffer <= shift_reg_in;
                            if(charreceivedp == charreceivedn)
                                charreceivedp <= ~charreceivedp;
                            state <= state_idle;
                        end
                    end
                end
            end
        endcase
    end
end
`ifdef READ_ON_NEG_EDGE == 1
always @ (negedge rd or posedge rst)
`else
always @ (posedge rd or posedge rst)
`endif
begin
    if(rst)
        charreceivedn <= 1'b0;
    else
    if(charreceivedp != charreceivedn)
        charreceivedn <= ~charreceivedn;
end
assign data = (rd) ? output_buffer : {WORD_LEN{1'bz}};
assign ref_sck = (modeint[1])? ~sckint : sckint;
assign ref_mosi = (ref_ss) ? 1'b1:_mosi;
assign ref_charreceived = (charreceivedp ^ charreceivedn);
endmodule




 
`timescale 1ns / 1ps

module tb;

    // Parameters
    parameter WORD_LEN = 8;
    parameter PRESCALLER_SIZE = 8;

    // Inputs
    reg clk;
    reg rst;
    reg wr;
    reg rd;
    reg [2:0] prescaller;
    reg lsbfirst;
    reg [1:0] mode;
    reg miso;
    reg res_senderr;

    // Outputs
    wire buffempty,ref_buffempty;
    wire sck,ref_sck;
    wire mosi,ref_mosi;
    wire ss,ref_ss;
    wire senderr,ref_senderr;
    wire charreceived,ref_charreceived;

    wire       match;
    integer total_tests = 0;
    integer failed_tests = 0;

    reg [2:0] prescallerint;
    reg [7:0] prescdemux;
    integer i;
    parameter NUM_TESTS = 1000;

wire [WORD_LEN - 1:0] data, TestOut;
reg  [WORD_LEN - 1:0] TestIn;
wire Write;
assign data = (Write == 1) ? TestIn : 32'bz;

    assign match = ({ref_buffempty, ref_sck, ref_mosi, ref_ss, ref_senderr, ref_charreceived} === {buffempty, sck, mosi, ss, senderr, charreceived});

    // Instantiate the SPI Master
    spi_master #(.WORD_LEN(WORD_LEN), .PRESCALLER_SIZE(PRESCALLER_SIZE)) uut (

        .clk(clk),
        .rst(rst),
        .data(data),
        .wr(wr),
        .rd(rd),
        .buffempty(buffempty),
        .prescaller(prescaller),
        .sck(sck),
        .mosi(mosi),
        .miso(miso),
        .ss(ss),
        .lsbfirst(lsbfirst),
        .mode(mode),
        .senderr(senderr),
        .res_senderr(res_senderr),
        .charreceived(charreceived)
    );

    ref_spi_master #(.WORD_LEN(WORD_LEN), .PRESCALLER_SIZE(PRESCALLER_SIZE)) ref_model (
        .clk(clk),
        .rst(rst),
        .data(data),
        .wr(wr),
        .rd(rd),
        .ref_buffempty(ref_buffempty),
        .prescaller(prescaller),
        .ref_sck(ref_sck),
        .ref_mosi(ref_mosi),
        .miso(miso),
        .ref_ss(ref_ss),
        .lsbfirst(lsbfirst),
        .mode(mode),
        .ref_senderr(ref_senderr),
        .res_senderr(res_senderr),
        .ref_charreceived(ref_charreceived)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end

    // Test Procedure
    initial begin
        // Initialize inputs
        rst = 1;
        wr = 0;
        rd = 0;
        prescaller = 3'b000;
        lsbfirst = 0;
        mode = 2'b00;
        miso = 0;
        res_senderr = 0;

        // Release reset
        #10;
        rst = 0;
        #10;
        rst = 1;

        #10;
        repeat(2000) begin
          #20 // Random delay to simulate different arrival times
            rst = 0; // Randomly assert or deassert reset
             #20
            wr = $random % 2;
            rd = $random % 2;
            prescaller = $random % 8;
            lsbfirst = $random % 2;
            mode = $random % 4;
            res_senderr = $random % 2;
            miso = $random % 2;

            // Simulate continuous operations
               #200
             compare();

        end


        // Finish simulation
        $display("\033[1;34mAll tests completed.\033[0m");
        $display("\033[1;34mTotal testcases: %d, Failed testcases: %d\033[0m", total_tests, failed_tests);
        if (failed_tests==0) begin
            $display("=====================Your Design Passed======================");
    end
        $finish;
    end


    task compare;
    begin
        total_tests = total_tests + 1;
        if (match)                                //condition to check DUT outputs and calculated 
                                                    //outputs from task are equal 
	   begin
	  // $display("\033[1;32mtestcase is passed!!!\033[0m");
	   end
	   else begin
	  // $display("\033[1;31mtestcase is failed!!!\033[0m");
         failed_tests = failed_tests + 1; 
         end
         end
    endtask

endmodule
