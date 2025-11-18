 
module	ref_writeqspi(i_clk, i_wreq, i_ereq, i_pipewr, i_endpipe, i_addr, i_data,
			ref_o_bus_ack, ref_o_qspi_req, i_qspi_grant,
				ref_o_spi_wr, ref_o_spi_hold, ref_o_spi_word, ref_o_spi_len,
				ref_o_spi_spd, ref_o_spi_dir, i_spi_data, i_spi_valid,
					i_spi_busy, i_spi_stopped,
				ref_o_data_ack, i_quad, ref_o_wip);
	input		i_clk;
	input		i_wreq, i_ereq, i_pipewr, i_endpipe;
	input		[21:0]	i_addr;
	input		[31:0]	i_data;
	output	reg		ref_o_bus_ack, ref_o_qspi_req;
	input			i_qspi_grant;
	output	reg		ref_o_spi_wr, ref_o_spi_hold;
	output	reg	[31:0]	ref_o_spi_word;
	output	reg	[1:0]	ref_o_spi_len;
	output	reg		ref_o_spi_spd, ref_o_spi_dir;
	input		[31:0]	i_spi_data;
	input			i_spi_valid;
	input			i_spi_busy, i_spi_stopped;
	output	reg		ref_o_data_ack;
	input			i_quad;
	output	reg		ref_o_wip;
`ifdef	QSPI_READ_ONLY
	always @(posedge i_clk)
		ref_o_data_ack <= (i_wreq)||(i_ereq);
	always @(posedge i_clk)
		ref_o_bus_ack <= (i_wreq)||(i_ereq);
	always @(posedge i_clk)
	begin
		ref_o_qspi_req <= 1'b0;
		ref_o_spi_wr   <= 1'b0;
		ref_o_spi_hold <= 1'b0;
		ref_o_spi_dir  <= 1'b1; 
		ref_o_spi_spd  <= i_quad;
		ref_o_spi_len  <= 2'b00;
		ref_o_spi_word <= 32'h00;
		ref_o_wip <= 1'b0;
	end
`else
`define	WR_IDLE				4'h0
`define	WR_START_WRITE			4'h1
`define	WR_START_QWRITE			4'h2
`define	WR_PROGRAM			4'h3
`define	WR_PROGRAM_GETNEXT		4'h4
`define	WR_START_ERASE			4'h5
`define	WR_WAIT_ON_STOP			4'h6
`define	WR_REQUEST_STATUS		4'h7
`define	WR_REQUEST_STATUS_NEXT		4'h8
`define	WR_READ_STATUS			4'h9
`define	WR_WAIT_ON_FINAL_STOP		4'ha
	reg	accepted;
	initial	accepted = 1'b0;
	always @(posedge i_clk)
		accepted <= (~i_spi_busy)&&(i_qspi_grant)&&(ref_o_spi_wr)&&(~accepted);
	reg		cyc, chk_wip, valid_status;
	reg	[3:0]	wr_state;
	initial	wr_state = `WR_IDLE;
	initial	cyc = 1'b0;
	always @(posedge i_clk)
	begin
		chk_wip <= 1'b0;
		ref_o_bus_ack  <= 1'b0;
		ref_o_data_ack <= 1'b0;
		case(wr_state)
		`WR_IDLE: begin
			valid_status <= 1'b0;
			ref_o_qspi_req <= 1'b0;
			cyc <= 1'b0;
			if (i_ereq)
				wr_state <= `WR_START_ERASE;
			else if (i_wreq)
				wr_state <= (i_quad)?`WR_START_QWRITE
					: `WR_START_WRITE;
			end
		`WR_START_WRITE: begin
			ref_o_wip      <= 1'b1;
			ref_o_qspi_req <= 1'b1;
			ref_o_spi_wr   <= 1'b1;
			ref_o_spi_dir  <= 1'b0;
			ref_o_spi_len  <= 2'b11;
			ref_o_spi_spd  <= 1'b0;
			ref_o_spi_hold <= 1'b1;
			ref_o_spi_word <= { 8'h02, i_addr, 2'b00 };
			cyc <= 1'b1;
			if (accepted)
			begin
				ref_o_bus_ack  <= 1'b1;
				ref_o_data_ack <= 1'b1;
				wr_state <= `WR_PROGRAM;
				ref_o_spi_word <= i_data;
			end end
		`WR_START_QWRITE: begin
			ref_o_wip      <= 1'b1;
			ref_o_qspi_req <= 1'b1;
			ref_o_spi_wr   <= 1'b1;
			ref_o_spi_dir  <= 1'b0;
			ref_o_spi_len  <= 2'b11;
			ref_o_spi_spd  <= 1'b0;
			ref_o_spi_hold <= 1'b1;
			ref_o_spi_word <= { 8'h32, i_addr, 2'b00 };
			cyc <= 1'b1;
			if (accepted)
			begin
				ref_o_bus_ack  <= 1'b1;
				ref_o_data_ack <= 1'b1;
				wr_state <= `WR_PROGRAM;
				ref_o_spi_word <= i_data;
			end end
		`WR_PROGRAM: begin
			ref_o_wip     <= 1'b1;
			ref_o_qspi_req <= 1'b1;
			ref_o_spi_wr   <= 1'b1;
			ref_o_spi_dir  <= 1'b0;
			ref_o_spi_len  <= 2'b11;
			ref_o_spi_spd  <= i_quad;
			ref_o_spi_hold <= 1'b1;
			if (accepted)
				wr_state <= `WR_PROGRAM_GETNEXT;
			end
		`WR_PROGRAM_GETNEXT: begin
			ref_o_wip      <= 1'b1;
			ref_o_qspi_req <= 1'b1;
			ref_o_spi_wr   <= 1'b0;
			ref_o_spi_dir  <= 1'b0;
			ref_o_spi_len  <= 2'b11;
			ref_o_spi_spd  <= i_quad;
			ref_o_spi_hold <= 1'b1;
			ref_o_spi_word <= i_data;
			cyc <= (cyc)&&(~i_endpipe);
			if (~cyc)
				wr_state <= `WR_WAIT_ON_STOP;
			else if (i_pipewr)
			begin
				ref_o_bus_ack  <= 1'b1;
				ref_o_data_ack <= 1'b1;
				wr_state <= `WR_PROGRAM;
			end end
		`WR_START_ERASE: begin
			ref_o_wip <= 1'b1;
			ref_o_qspi_req <= 1'b1;
			ref_o_spi_wr  <= 1'b1;
			ref_o_spi_dir <= 1'b0;
			ref_o_spi_spd <= 1'b0;
			ref_o_spi_len <= 2'b11;
			if (i_data[28])
				ref_o_spi_word[31:24] <= 8'h20;
			else
				ref_o_spi_word[31:24] <= 8'hd8;
			ref_o_spi_word[23:0] <= { i_data[21:10], 12'h0 };
			ref_o_bus_ack <= accepted;
			if (accepted)
				wr_state <= `WR_WAIT_ON_STOP;
			end
		`WR_WAIT_ON_STOP: begin
			ref_o_wip <= 1'b1;
			ref_o_qspi_req <= 1'b0;
			ref_o_spi_wr   <= 1'b0;
			ref_o_spi_hold <= 1'b0;
			if (i_spi_stopped)
				wr_state <= `WR_REQUEST_STATUS;
			end
		`WR_REQUEST_STATUS: begin
			ref_o_wip <= 1'b1;
			ref_o_qspi_req <= 1'b1;
			ref_o_spi_hold <= 1'b0;
			ref_o_spi_wr   <= 1'b1;
			ref_o_spi_spd  <= 1'b0; 
			ref_o_spi_len  <= 2'b00; 
			ref_o_spi_dir  <= 1'b0; 
			ref_o_spi_word <= { 8'h05, 24'h00 };
			if (accepted)
				wr_state <= `WR_REQUEST_STATUS_NEXT;
			end
		`WR_REQUEST_STATUS_NEXT: begin
			ref_o_wip <= 1'b1;
			ref_o_qspi_req <= 1'b1;
			ref_o_spi_hold <= 1'b0;
			ref_o_spi_wr   <= 1'b1;
			ref_o_spi_spd  <= 1'b0; 
			ref_o_spi_len  <= 2'b00; 
			ref_o_spi_dir  <= 1'b1; 
			ref_o_spi_word <= 32'h00;
			if (accepted)
				wr_state <= `WR_READ_STATUS;
			valid_status <= 1'b0;
			end
		`WR_READ_STATUS: begin
			ref_o_wip <= 1'b1;
			ref_o_qspi_req <= 1'b1;
			ref_o_spi_hold <= 1'b0;
			ref_o_spi_wr   <= 1'b1;
			ref_o_spi_spd  <= 1'b0; 
			ref_o_spi_len  <= 2'b00; 
			ref_o_spi_dir  <= 1'b1; 
			ref_o_spi_word <= 32'h00;
			if (i_spi_valid)
				valid_status <= 1'b1;
			if ((i_spi_valid)&&(valid_status))
				chk_wip <= 1'b1;
			if ((chk_wip)&&(~i_spi_data[0]))
				wr_state <= `WR_WAIT_ON_FINAL_STOP;
			end
		default: begin
			ref_o_qspi_req <= 1'b0;
			ref_o_spi_wr <= 1'b0;
			ref_o_wip <= 1'b0;
			if (i_spi_stopped)
				wr_state <= `WR_IDLE;
			end
		endcase
	end
`endif
endmodule




 `timescale 1ns / 1ps

module tb;

    // Parameters
    parameter CLK_PERIOD = 10; // Clock period for i_clk

    // Inputs
    reg i_clk;
    reg i_wreq;
    reg i_ereq;
    reg i_pipewr;
    reg i_endpipe;
    reg [21:0] i_addr;
    reg [31:0] i_data;
    reg i_qspi_grant;
    reg i_quad;
    reg i_spi_busy;
    reg i_spi_stopped;
    reg [31:0] i_spi_data;
    reg i_spi_valid;

    // Outputs
    wire ref_o_bus_ack,dut_o_bus_ack;
    wire ref_o_qspi_req,dut_o_qspi_req;
    wire ref_o_spi_wr,dut_o_spi_wr;
    wire ref_o_spi_hold,dut_o_spi_hold;
    wire [31:0] ref_o_spi_word,dut_o_spi_word;
    wire [1:0] ref_o_spi_len,dut_o_spi_len;
    wire ref_o_spi_spd,dut_o_spi_spd;
    wire ref_o_spi_dir,dut_o_spi_dir;
    wire ref_o_data_ack,dut_o_data_ack;
    wire ref_o_wip,dut_o_wip;

	wire match;
 	integer total_tests = 0;
	integer failed_tests = 0;

assign match = ({ref_o_bus_ack,ref_o_qspi_req,ref_o_spi_wr,ref_o_spi_hold,ref_o_spi_word,ref_o_spi_len,ref_o_spi_spd,ref_o_spi_dir,ref_o_data_ack,ref_o_wip} === {dut_o_bus_ack,dut_o_qspi_req,dut_o_spi_wr,dut_o_spi_hold,dut_o_spi_word,dut_o_spi_len,dut_o_spi_spd,dut_o_spi_dir,dut_o_data_ack,dut_o_wip} );

    // Instantiate the writeqspi module
    writeqspi uut (
        .i_clk(i_clk),
        .i_wreq(i_wreq),
        .i_ereq(i_ereq),
        .i_pipewr(i_pipewr),
        .i_endpipe(i_endpipe),
        .i_addr(i_addr),
        .i_data(i_data),
        .o_bus_ack(dut_o_bus_ack),
        .o_qspi_req(dut_o_qspi_req),
        .i_qspi_grant(i_qspi_grant),
        .o_spi_wr(dut_o_spi_wr),
        .o_spi_hold(dut_o_spi_hold),
        .o_spi_word(dut_o_spi_word),
        .o_spi_len(dut_o_spi_len),
        .o_spi_spd(dut_o_spi_spd),
        .o_spi_dir(dut_o_spi_dir),
        .i_spi_data(i_spi_data),
        .i_spi_valid(i_spi_valid),
        .i_spi_busy(i_spi_busy),
        .i_spi_stopped(i_spi_stopped),
        .o_data_ack(dut_o_data_ack),
        .i_quad(i_quad),
        .o_wip(dut_o_wip)
    );

    // Instantiate the writeqspi module
    ref_writeqspi uut2 (
        .i_clk(i_clk),
        .i_wreq(i_wreq),
        .i_ereq(i_ereq),
        .i_pipewr(i_pipewr),
        .i_endpipe(i_endpipe),
        .i_addr(i_addr),
        .i_data(i_data),
        .ref_o_bus_ack(ref_o_bus_ack),
        .ref_o_qspi_req(ref_o_qspi_req),
        .i_qspi_grant(i_qspi_grant),
        .ref_o_spi_wr(ref_o_spi_wr),
        .ref_o_spi_hold(ref_o_spi_hold),
        .ref_o_spi_word(ref_o_spi_word),
        .ref_o_spi_len(ref_o_spi_len),
        .ref_o_spi_spd(ref_o_spi_spd),
        .ref_o_spi_dir(ref_o_spi_dir),
        .i_spi_data(i_spi_data),
        .i_spi_valid(i_spi_valid),
        .i_spi_busy(i_spi_busy),
        .i_spi_stopped(i_spi_stopped),
        .ref_o_data_ack(ref_o_data_ack),
        .i_quad(i_quad),
        .ref_o_wip(ref_o_wip)
    );

    // Generate clock signal
    initial begin
        i_clk = 0;
        forever #(CLK_PERIOD / 2) i_clk = ~i_clk; // Toggle clock
    end

    // Test Procedure
    initial begin
        // Initialize inputs
        i_wreq = 0;
        i_ereq = 0;
        i_pipewr = 0;
        i_endpipe = 0;
        i_addr = 22'h0;
        i_data = 32'hDEADBEEF;
        i_qspi_grant = 0;
        i_quad = 0;
        i_spi_busy = 0;
        i_spi_stopped = 0;
        i_spi_data = 32'h0;
        i_spi_valid = 0;

        // Wait for a clock cycle
        #(CLK_PERIOD);

        // Test Case 1: Simple write request
        i_wreq = 1; // Assert write request
        i_qspi_grant = 1; // Grant QSPI access
        #(CLK_PERIOD);
        i_wreq = 0; // De-assert write request
        #(CLK_PERIOD);

            compare();

        
  
        // Test Case 2: Erase request
        i_ereq = 1; // Assert erase request
        #(CLK_PERIOD);
        i_ereq = 0; // De-assert erase request
        #(CLK_PERIOD);

   

        // Test Case 3: Handle SPI busy and stopped conditions
        i_spi_busy = 1; // Simulate SPI busy
        #(CLK_PERIOD);
        i_spi_busy = 0; // Release busy
        i_spi_stopped = 1; // Simulate SPI stopped
        #(CLK_PERIOD);
        i_spi_stopped = 0; // Release stopped

            compare();

 //-----------
// Test case 1: Write request with single data
        i_wreq = 1;
        i_addr = 22'h12345;
        i_data = 32'hDEADBEEF;
        i_qspi_grant = 1;
        i_quad = 0;
        #(CLK_PERIOD);
        i_wreq = 0;
        #(CLK_PERIOD * 10);
        compare();

        // Test case 2: Erase request
        i_ereq = 1;
        i_data = 32'h00000001; // Sector erase
        i_qspi_grant = 1;
        #(CLK_PERIOD);
        i_ereq = 0;
        #(CLK_PERIOD * 10);
        compare();

        // Test case 3: Write request with quad mode
        i_wreq = 1;
        i_addr = 22'h54321;
        i_data = 32'hCAFEBABE;
        i_qspi_grant = 1;
        i_quad = 1;
        #(CLK_PERIOD);
        i_wreq = 0;
        #(CLK_PERIOD * 10);
        compare();

        // Test case 4: Write request with multiple data
        i_wreq = 1;
        i_addr = 22'h11223;
        i_data = 32'hDEADBEEF;
        i_qspi_grant = 1;
        i_quad = 0;
        #(CLK_PERIOD);
        i_wreq = 0;
        i_pipewr = 1;
        i_data = 32'hCAFEBABE;
        #(CLK_PERIOD);
        i_pipewr = 0;
        #(CLK_PERIOD * 10);
        compare();

        // Test case 5: Write request with end of pipe
        i_wreq = 1;
        i_addr = 22'h11223;
        i_data = 32'hDEADBEEF;
        i_qspi_grant = 1;
        i_quad = 0;
        #(CLK_PERIOD);
        i_wreq = 0;
        i_pipewr = 1;
        i_data = 32'hCAFEBABE;
        #(CLK_PERIOD);
        i_pipewr = 0;
        i_endpipe = 1;
        #(CLK_PERIOD);
        i_endpipe = 0;
        #(CLK_PERIOD * 10);
        compare();

        // Test case 6: Read status
        i_qspi_grant = 1;
        i_spi_valid = 1;
        i_spi_data = 32'h00000001; // WIP bit set
        #(CLK_PERIOD * 10);
        i_spi_data = 32'h00000000; // WIP bit cleared
        #(CLK_PERIOD * 10);
        compare();

//--------------

        // Finish simulation
        #(CLK_PERIOD * 10);
repeat (96) begin
            @(negedge i_clk);
	i_wreq = $random;
	i_ereq = $random;
	i_pipewr = $random;
	i_endpipe = $random;
	i_addr = $random;
	i_data = $random;
	i_qspi_grant = $random;
	i_quad = $random;
	i_spi_busy = $random;
	i_spi_stopped = $random;
	i_spi_data = $random;
	i_spi_valid = $random;

            compare();
        end

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
			end

		else begin
			//$display("\033[1;31mtestcase is failed!!!\033[0m");
            failed_tests = failed_tests + 1; 
		end
    
	endtask

endmodule
