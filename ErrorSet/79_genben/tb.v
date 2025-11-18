 
module	ref_rtclight(i_clk, 
		i_wb_cyc, i_wb_stb, i_wb_we, i_wb_addr, i_wb_data,
		ref_o_data, 
		ref_o_interrupt,
		ref_o_ppd);
	parameter	DEFAULT_SPEED = 32'd2814750;	
	input	i_clk;
	input	i_wb_cyc, i_wb_stb, i_wb_we;
	input	[2:0]	i_wb_addr;
	input	[31:0]	i_wb_data;
	output	reg	[31:0]	ref_o_data;
	output	wire		ref_o_interrupt, ref_o_ppd;
	reg	[21:0]	clock;
	reg	[31:0]	stopwatch, ckspeed;
	reg	[25:0]	timer;
	wire	ck_sel, tm_sel, sw_sel, sp_sel, al_sel;
	assign	ck_sel = ((i_wb_stb)&&(i_wb_addr[2:0]==3'b000));
	assign	tm_sel = ((i_wb_stb)&&(i_wb_addr[2:0]==3'b001));
	assign	sw_sel = ((i_wb_stb)&&(i_wb_addr[2:0]==3'b010));
	assign	al_sel = ((i_wb_stb)&&(i_wb_addr[2:0]==3'b011));
	assign	sp_sel = ((i_wb_stb)&&(i_wb_addr[2:0]==3'b100));
	reg	[39:0]	ck_counter;
	reg		ck_carry;
	always @(posedge i_clk)
		{ ck_carry, ck_counter } <= ck_counter + { 8'h00, ckspeed };
	wire		ck_pps;
	reg		ck_prepps, ck_ppm, ck_pph, ck_ppd;
	reg	[7:0]	ck_sub;
	initial	clock = 22'h00000;
	assign	ck_pps = (ck_carry)&&(ck_prepps);
	always @(posedge i_clk)
	begin
		if (ck_carry)
			ck_sub <= ck_sub + 8'h1;
		ck_prepps <= (ck_sub == 8'hff);
		if (ck_pps)
		begin 
			if (clock[3:0] >= 4'h9)
				clock[3:0] <= 4'h0;
			else
				clock[3:0] <= clock[3:0] + 4'h1;
			if (clock[7:0] >= 8'h59)
				clock[7:4] <= 4'h0;
			else if (clock[3:0] >= 4'h9)
				clock[7:4] <= clock[7:4] + 4'h1;
		end
		ck_ppm <= (clock[7:0] == 8'h59);
		if ((ck_pps)&&(ck_ppm))
		begin 
			if (clock[11:8] >= 4'h9)
				clock[11:8] <= 4'h0;
			else
				clock[11:8] <= clock[11:8] + 4'h1;
			if (clock[15:8] >= 8'h59)
				clock[15:12] <= 4'h0;
			else if (clock[11:8] >= 4'h9)
				clock[15:12] <= clock[15:12] + 4'h1;
		end
		ck_pph <= (clock[15:0] == 16'h5959);
		if ((ck_pps)&&(ck_pph))
		begin 
			if (clock[21:16] >= 6'h23)
			begin
				clock[19:16] <= 4'h0;
				clock[21:20] <= 2'h0;
			end else if (clock[19:16] >= 4'h9)
			begin
				clock[19:16] <= 4'h0;
				clock[21:20] <= clock[21:20] + 2'h1;
			end else begin
				clock[19:16] <= clock[19:16] + 4'h1;
			end
		end
		ck_ppd <= (clock[21:0] == 22'h235959);
		if ((ck_sel)&&(i_wb_we))
		begin
			if (8'hff != i_wb_data[7:0])
			begin
				clock[7:0] <= i_wb_data[7:0];
				ck_ppm <= (i_wb_data[7:0] == 8'h59);
			end
			if (8'hff != i_wb_data[15:8])
			begin
				clock[15:8] <= i_wb_data[15:8];
				ck_pph <= (i_wb_data[15:8] == 8'h59);
			end
			if (6'h3f != i_wb_data[21:16])
				clock[21:16] <= i_wb_data[21:16];
			if (8'h00 == i_wb_data[7:0])
				ck_sub <= 8'h00;
		end
	end
	reg	[21:0]		ck_last_clock;
	always @(posedge i_clk)
		ck_last_clock <= clock[21:0];
	reg	tm_pps, tm_ppm, tm_int;
	wire	tm_stopped, tm_running, tm_alarm;
	assign	tm_stopped = ~timer[24];
	assign	tm_running =  timer[24];
	assign	tm_alarm   =  timer[25];
	reg	[23:0]		tm_start;
	reg	[7:0]		tm_sub;
	initial	tm_start = 24'h00;
	initial	timer    = 26'h00;
	initial	tm_int   = 1'b0;
	initial	tm_pps   = 1'b0;
	always @(posedge i_clk)
	begin
		if (ck_carry)
		begin
			tm_sub <= tm_sub + 8'h1;
			tm_pps <= (tm_sub == 8'hff);
		end else
			tm_pps <= 1'b0;
		if ((~tm_alarm)&&(tm_running)&&(tm_pps))
		begin 
			timer[25] <= 1'b0;
			if (timer[23:0] == 24'h00)
				timer[25] <= 1'b1;
			else if (timer[3:0] != 4'h0)
				timer[3:0] <= timer[3:0]-4'h1;
			else begin 
				timer[3:0] <= 4'h9;
				if (timer[7:4] != 4'h0)
					timer[7:4] <= timer[7:4]-4'h1;
				else begin 
					timer[7:4] <= 4'h5;
					if (timer[11:8] != 4'h0)
						timer[11:8] <= timer[11:8]-4'h1;
					else begin 
						timer[11:8] <= 4'h9;
						if (timer[15:12] != 4'h0)
							timer[15:12] <= timer[15:12]-4'h1;
						else begin
							timer[15:12] <= 4'h5;
							if (timer[19:16] != 4'h0)
								timer[19:16] <= timer[19:16]-4'h1;
							else begin
								timer[19:16] <= 4'h9;
								timer[23:20] <= timer[23:20]-4'h1;
							end
						end
					end
				end
			end
		end
		if((~tm_alarm)&&(tm_running))
		begin
			timer[25] <= (timer[23:0] == 24'h00);
			tm_int <= (timer[23:0] == 24'h00);
		end else tm_int <= 1'b0;
		if (tm_alarm)
			timer[24] <= 1'b0;
		if ((tm_sel)&&(i_wb_we)&&(tm_running)) 
			timer[24] <= i_wb_data[24];
		else if ((tm_sel)&&(i_wb_we)&&(tm_stopped)) 
		begin
			timer[24] <= i_wb_data[24];
			if ((timer[24])||(i_wb_data[24]))
				timer[25] <= 1'b0;
			if (i_wb_data[23:0] != 24'h0000)
			begin
				timer[23:0] <= i_wb_data[23:0];
				tm_start <= i_wb_data[23:0];
				tm_sub <= 8'h00;
			end else if (timer[23:0] == 24'h00)
			begin 
				timer[23:0] <= tm_start;
				tm_sub <= 8'h00;
			end
			timer[25] <= 1'b0;
		end
	end
	reg		sw_pps, sw_ppm, sw_pph;
	reg	[7:0]	sw_sub;
	wire	sw_running;
	assign	sw_running = stopwatch[0];
	initial	stopwatch = 32'h00000;
	always @(posedge i_clk)
	begin
		sw_pps <= 1'b0;
		if (sw_running)
		begin
			if (ck_carry)
			begin
				sw_sub <= sw_sub + 8'h1;
				sw_pps <= (sw_sub == 8'hff);
			end
		end
		stopwatch[7:1] <= sw_sub[7:1];
		if (sw_pps)
		begin 
			if (stopwatch[11:8] >= 4'h9)
				stopwatch[11:8] <= 4'h0;
			else
				stopwatch[11:8] <= stopwatch[11:8] + 4'h1;
			if (stopwatch[15:8] >= 8'h59)
				stopwatch[15:12] <= 4'h0;
			else if (stopwatch[11:8] >= 4'h9)
				stopwatch[15:12] <= stopwatch[15:12] + 4'h1;
			sw_ppm <= (stopwatch[15:8] == 8'h59);
		end else sw_ppm <= 1'b0;
		if (sw_ppm)
		begin 
			if (stopwatch[19:16] >= 4'h9)
				stopwatch[19:16] <= 4'h0;
			else
				stopwatch[19:16] <= stopwatch[19:16]+4'h1;
			if (stopwatch[23:16] >= 8'h59)
				stopwatch[23:20] <= 4'h0;
			else if (stopwatch[19:16] >= 4'h9)
				stopwatch[23:20] <= stopwatch[23:20]+4'h1;
			sw_pph <= (stopwatch[23:16] == 8'h59);
		end else sw_pph <= 1'b0;
		if (sw_pph)
		begin 
			if (stopwatch[27:24] >= 4'h9)
				stopwatch[27:24] <= 4'h0;
			else
				stopwatch[27:24] <= stopwatch[27:24]+4'h1;
			if((stopwatch[27:24] >= 4'h9)&&(stopwatch[31:28] < 4'hf))
				stopwatch[31:28] <= stopwatch[27:24]+4'h1;
		end
		if ((sw_sel)&&(i_wb_we))
		begin
			stopwatch[0] <= i_wb_data[0];
			if((i_wb_data[1])&&((~stopwatch[0])||(~i_wb_data[0])))
			begin
				stopwatch[31:1] <= 31'h00;
				sw_sub <= 8'h00;
				sw_pps <= 1'b0;
				sw_ppm <= 1'b0;
				sw_pph <= 1'b0;
			end
		end
	end
	reg	[21:0]		alarm_time;
	reg			al_int,		
				al_enabled,	
				al_tripped;	
	initial	al_enabled= 1'b0;
	initial	al_tripped= 1'b0;
	always @(posedge i_clk)
	begin
		if ((al_sel)&&(i_wb_we))
		begin
			if (i_wb_data[21:16] != 6'h3f)
				alarm_time[21:16] <= i_wb_data[21:16];
			if (i_wb_data[15:8] != 8'hff)
				alarm_time[15:8] <= i_wb_data[15:8];
			if (i_wb_data[7:0] != 8'hff)
				alarm_time[7:0] <= i_wb_data[7:0];
			al_enabled <= i_wb_data[24];
			if ((i_wb_data[25])||(~i_wb_data[24]))
				al_tripped <= 1'b0;
		end
		al_int <= 1'b0;
		if ((ck_last_clock != alarm_time)&&(clock[21:0] == alarm_time)
			&&(al_enabled))
		begin
			al_tripped <= 1'b1;
			al_int <= 1'b1;
		end
	end
	initial	ckspeed = DEFAULT_SPEED; 
	always @(posedge i_clk)
		if ((sp_sel)&&(i_wb_we))
			ckspeed <= i_wb_data;
	assign	ref_o_interrupt = tm_int || al_int;
	assign	ref_o_ppd = (ck_ppd)&&(ck_pps);
	always @(posedge i_clk)
		case(i_wb_addr[2:0])
		3'b000: ref_o_data <= { 10'h0, ck_last_clock };
		3'b001: ref_o_data <= { 6'h00, timer };
		3'b010: ref_o_data <= stopwatch;
		3'b011: ref_o_data <= { 6'h00, al_tripped, al_enabled, 2'b00, alarm_time };
		3'b100: ref_o_data <= ckspeed;
		default: ref_o_data <= 32'h000;
		endcase
endmodule




 `timescale 1ns / 1ps

module tb;

    // Parameters
    parameter DEFAULT_SPEED = 32'd2814750;

    // Inputs
    reg i_clk;
    reg i_wb_cyc, i_wb_stb, i_wb_we;
    reg [2:0] i_wb_addr;
    reg [31:0] i_wb_data;

    // ref Outputs
    wire [31:0] ref_o_data;
    wire ref_o_interrupt, ref_o_ppd;

    // Outputs
    wire [31:0] o_data;
    wire o_interrupt, o_ppd;

	wire match;
 	integer total_tests = 0;
	integer failed_tests = 0;

assign match = ({ref_o_data,ref_o_interrupt, ref_o_ppd} === {o_data,o_interrupt,o_ppd});
//assign match = ({ref_o_data,ref_o_interrupt, ref_o_ppd} === ({ref_o_data,ref_o_interrupt, ref_o_ppd}  ^ {o_data,o_interrupt, o_ppd}  ^ {ref_o_data,ref_o_interrupt, ref_o_ppd} ));

    // Instantiate the rtclight module
    ref_rtclight rf(
        .i_clk(i_clk),
        .i_wb_cyc(i_wb_cyc),
        .i_wb_stb(i_wb_stb),
        .i_wb_we(i_wb_we),
        .i_wb_addr(i_wb_addr),
        .i_wb_data(i_wb_data),
        .ref_o_data(ref_o_data),
        .ref_o_interrupt(ref_o_interrupt),
        .ref_o_ppd(ref_o_ppd)
    );

  // Instantiate the rtclight module
    rtclight uut(
        .i_clk(i_clk),
        .i_wb_cyc(i_wb_cyc),
        .i_wb_stb(i_wb_stb),
        .i_wb_we(i_wb_we),
        .i_wb_addr(i_wb_addr),
        .i_wb_data(i_wb_data),
        .o_data(o_data),
        .o_interrupt(o_interrupt),
        .o_ppd(o_ppd)
    );

    // Clock generation
    initial begin
        i_clk = 0;
        forever #5 i_clk = ~i_clk; // 100MHz clock
    end

    // Test Procedure
    initial begin
        // Initialize inputs
       // i_wb_cyc = 0;
       /// i_wb_stb = 0;
       // i_wb_we = 0;
       // i_wb_addr = 3'b000;
      //  i_wb_data = 32'h0;


        i_wb_cyc = 0;
        i_wb_stb = 0;
        i_wb_we = 0;
        i_wb_addr = 0;
        i_wb_data = 0;

        // Wait for a few clock cycles
        #10;

        // Test Case 1: Write to clock register
        i_wb_cyc = 1;
        i_wb_stb = 1;
        i_wb_we = 1;
        i_wb_addr = 3'b000; // Clock register
        i_wb_data = 32'h123456; // Set time to 12:34:56
        #10;
        i_wb_stb = 0; // End the write transaction
        #10;
compare();


        // Test Case 2: Read clock register
        i_wb_cyc = 1;
        i_wb_stb = 1;
        i_wb_we = 0; // Read
        i_wb_addr = 3'b000; // Clock register
        #10;
        i_wb_stb = 0; // End the read transaction
        #10;
compare();

   
        // Test Case 3: Write to timer register
        i_wb_cyc = 1;
        i_wb_stb = 1;
        i_wb_we = 1;
        i_wb_addr = 3'b001; // Timer register
        i_wb_data = {1'b0, 24'hFFFFFF}; // Set timer to 24 hours
        #10;
        i_wb_stb = 0; // End the write transaction
        #10;
compare();



        // Test Case 4: Start stopwatch
        i_wb_cyc = 1;
        i_wb_stb = 1;
        i_wb_we = 1;
        i_wb_addr = 3'b010; // Stopwatch register
        i_wb_data = 32'h1; // Start stopwatch
        #10;
        i_wb_stb = 0; // End the write transaction
        #10;
compare();

        // Wait for some time and check stopwatch
        #50;

 
        // Test Case 5: Set alarm time
        i_wb_cyc = 1;
        i_wb_stb = 1;
        i_wb_we = 1;
        i_wb_addr = 3'b011; // Alarm register
        i_wb_data = {1'b1, 6'h3F, 8'h59, 8'h59}; // Set alarm time to 23:59:59
        #10;
        i_wb_stb = 0; // End the write transaction
        #10;
compare();



        // Test Case 6: Set clock speed
        i_wb_cyc = 1;
        i_wb_stb = 1;
        i_wb_we = 1;
        i_wb_addr = 3'b100; // Clock speed register
        i_wb_data = 32'd3000000; // Set speed
        #10;
        i_wb_stb = 0; // End the write transaction
        #10;
compare();


repeat (2000) begin
      @(posedge i_clk);
	i_wb_cyc = $random;
	 i_wb_stb = $random;
	i_wb_we = $random;
	i_wb_addr = $random;
	i_wb_data = $random;   
      compare();
    end
        // Additional test cases can be added similarly...
	  $display("All tests passed: design passed");
        $display("\033[1;34mTotal testcases: %d, Failed testcases: %d\033[0m", total_tests, failed_tests);

        // Finish simulation
        if (failed_tests==0) begin
            $display("=====================Your Design Passed======================");
    end
        #100;
        $finish;
    end

task compare;
        total_tests = total_tests + 1;
        if (match)                                //condition to check DUT outputs and calculated 
                                                    //outputs from task are equal 
			begin				//$display("\033[1;32mtestcase is passed!!!\033[0m",$time);
							//$display("o_data = %h,o_interrupt = %h, o_ppd = %h,ref_o_data = %h,ref_o_interrupt = %h, ref_o_ppd = %h",o_data,o_interrupt, o_ppd,ref_o_data,ref_o_interrupt, ref_o_ppd);
				//$display("testcase is passed!!!");
			end

		else begin
			//$display("\033[1;31mtestcase is failed!!!\033[0m",$time);
			//$display("o_data = %h,o_interrupt = %h, o_ppd = %h,ref_o_data = %h,ref_o_interrupt = %h, ref_o_ppd = %h",o_data,o_interrupt, o_ppd,ref_o_data,ref_o_interrupt, ref_o_ppd);
            failed_tests = failed_tests + 1; 
		end
	
endtask



endmodule
