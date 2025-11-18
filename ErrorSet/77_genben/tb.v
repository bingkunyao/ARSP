 

module ref_vga_colproc(clk, srst, vdat_buffer_di, ColorDepth, PseudoColor, 
	vdat_buffer_empty, ref_vdat_buffer_rreq, rgb_fifo_full,
	ref_rgb_fifo_wreq, ref_r, ref_g, ref_b,
	ref_clut_req, clut_ack, ref_clut_offs, clut_q
	);
	input clk;                    
	input srst;                   
	input [31:0] vdat_buffer_di;  
	input [1:0] ColorDepth;       
	input       PseudoColor;      
	input  vdat_buffer_empty;
	output ref_vdat_buffer_rreq;      
	reg    ref_vdat_buffer_rreq;
	input  rgb_fifo_full;
	output ref_rgb_fifo_wreq;
	reg    ref_rgb_fifo_wreq;
	output [7:0] ref_r, ref_g, ref_b;         
	reg    [7:0] ref_r, ref_g, ref_b;
	output        ref_clut_req;       
	reg ref_clut_req;
	input         clut_ack;       
	output [ 7:0] ref_clut_offs;      
	reg [7:0] ref_clut_offs;
	input  [23:0] clut_q;         
	reg [31:0] DataBuffer;
	reg [7:0] Ra, Ga, Ba;
	reg [1:0] colcnt;
	reg RGBbuf_wreq;
	always @(posedge clk)
		if (ref_vdat_buffer_rreq)
			DataBuffer <= #1 vdat_buffer_di;
	parameter idle        = 7'b000_0000, 
	          fill_buf    = 7'b000_0001,
	          bw_8bpp     = 7'b000_0010,
	          col_8bpp    = 7'b000_0100,
	          col_16bpp_a = 7'b000_1000,
	          col_16bpp_b = 7'b001_0000,
	          col_24bpp   = 7'b010_0000,
	          col_32bpp   = 7'b100_0000;
	reg [6:0] c_state;   
	reg [6:0] nxt_state; 
	always @(c_state or vdat_buffer_empty or ColorDepth or PseudoColor or rgb_fifo_full or colcnt or clut_ack)
	begin : nxt_state_decoder
		nxt_state = c_state;
		case (c_state) 
			idle:
				if (!vdat_buffer_empty && !rgb_fifo_full)
					nxt_state = fill_buf;
			fill_buf:
				case (ColorDepth) 
					2'b00: 
						if (PseudoColor)
							nxt_state = col_8bpp;
						else
							nxt_state = bw_8bpp;
					2'b01:
						nxt_state = col_16bpp_a;
					2'b10:
						nxt_state = col_24bpp;
					2'b11:
						nxt_state = col_32bpp;
				endcase
			bw_8bpp:
				if (!rgb_fifo_full && !(|colcnt) )
					if (!vdat_buffer_empty)
						nxt_state = fill_buf;
					else
						nxt_state = idle;
			col_8bpp:
				if (!(|colcnt))
					if (!vdat_buffer_empty && !rgb_fifo_full)
						nxt_state = fill_buf;
					else
						nxt_state = idle;
			col_16bpp_a:
				if (!rgb_fifo_full)
					nxt_state = col_16bpp_b;
			col_16bpp_b:
				if (!rgb_fifo_full)
					if (!vdat_buffer_empty)
						nxt_state = fill_buf;
					else
						nxt_state = idle;
			col_24bpp:
				if (!rgb_fifo_full)
					if (colcnt == 2'h1) 
						nxt_state = col_24bpp; 
					else if (!vdat_buffer_empty)
						nxt_state = fill_buf;
					else
						nxt_state = idle;
			col_32bpp:
				if (!rgb_fifo_full)
					if (!vdat_buffer_empty)
						nxt_state = fill_buf;
					else
						nxt_state = idle;
		endcase
	end 
	always @(posedge clk)
			if (srst)
				c_state <= #1 idle;
			else
				c_state <= #1 nxt_state;
	reg iclut_req;
	reg ivdat_buf_rreq;
	reg [7:0] iR, iG, iB, iRa, iGa, iBa;
	always @(c_state or vdat_buffer_empty or colcnt or DataBuffer or rgb_fifo_full or clut_ack or clut_q or Ba or Ga or Ra)
	begin : output_decoder
		ivdat_buf_rreq = 1'b0;
		RGBbuf_wreq = 1'b0;
		iclut_req = 1'b0;
		iR  = 'h0;
		iG  = 'h0;
		iB  = 'h0;
		iRa = 'h0;
		iGa = 'h0;
		iBa = 'h0;
		case (c_state) 
			idle:
				begin
					if (!rgb_fifo_full)
						if (!vdat_buffer_empty)
							ivdat_buf_rreq = 1'b1;
					RGBbuf_wreq = clut_ack;
					iR = clut_q[23:16];
					iG = clut_q[15: 8];
					iB = clut_q[ 7: 0];
				end
			fill_buf:
				begin
					RGBbuf_wreq = clut_ack;
					iR = clut_q[23:16];
					iG = clut_q[15: 8];
					iB = clut_q[ 7: 0];
				end
			bw_8bpp:
			begin
				if (!rgb_fifo_full)
					begin
						RGBbuf_wreq = 1'b1;
						if ( (!vdat_buffer_empty) && !(|colcnt) )
							ivdat_buf_rreq = 1'b1;
					end
				case (colcnt) 
					2'b11:
					begin
						iR = DataBuffer[31:24];
						iG = DataBuffer[31:24];
						iB = DataBuffer[31:24];
					end
					2'b10:
					begin
						iR = DataBuffer[23:16];
						iG = DataBuffer[23:16];
						iB = DataBuffer[23:16];
					end
					2'b01:
					begin
						iR = DataBuffer[15:8];
						iG = DataBuffer[15:8];
						iB = DataBuffer[15:8];
					end
					default:
					begin
						iR = DataBuffer[7:0];
						iG = DataBuffer[7:0];
						iB = DataBuffer[7:0];
					end
				endcase
			end
			col_8bpp:
			begin
				if (!(|colcnt))
					if (!vdat_buffer_empty && !rgb_fifo_full)
						ivdat_buf_rreq = 1'b1;
				RGBbuf_wreq = clut_ack;
				iR = clut_q[23:16];
				iG = clut_q[15: 8];
				iB = clut_q[ 7: 0];
				iclut_req = !rgb_fifo_full || (colcnt[1] ^ colcnt[0]);
			end
			col_16bpp_a:
			begin
				if (!rgb_fifo_full)
					RGBbuf_wreq = 1'b1;
				iR[7:3] = DataBuffer[31:27];
				iG[7:2] = DataBuffer[26:21];
				iB[7:3] = DataBuffer[20:16];
			end
			col_16bpp_b:
			begin
				if (!rgb_fifo_full)
					begin
						RGBbuf_wreq = 1'b1;
						if (!vdat_buffer_empty)
							ivdat_buf_rreq = 1'b1;
					end
				iR[7:3] = DataBuffer[15:11];
				iG[7:2] = DataBuffer[10: 5];
				iB[7:3] = DataBuffer[ 4: 0];
			end
			col_24bpp:
			begin
				if (!rgb_fifo_full)
					begin
						RGBbuf_wreq = 1'b1;
						if ( (colcnt != 2'h1) && !vdat_buffer_empty)
							ivdat_buf_rreq = 1'b1;
					end
				case (colcnt) 
					2'b11:
					begin
						iR  = DataBuffer[31:24];
						iG  = DataBuffer[23:16];
						iB  = DataBuffer[15: 8];
						iRa = DataBuffer[ 7: 0];
					end
					2'b10:
					begin
						iR  = Ra;
						iG  = DataBuffer[31:24];
						iB  = DataBuffer[23:16];
						iRa = DataBuffer[15: 8];
						iGa = DataBuffer[ 7: 0];
					end
					2'b01:
					begin
						iR  = Ra;
						iG  = Ga;
						iB  = DataBuffer[31:24];
						iRa = DataBuffer[23:16];
						iGa = DataBuffer[15: 8];
						iBa = DataBuffer[ 7: 0];
					end
					default:
					begin
						iR = Ra;
						iG = Ga;
						iB = Ba;
					end
				endcase
			end
			col_32bpp:
			begin
				if (!rgb_fifo_full)
					begin
						RGBbuf_wreq = 1'b1;
						if (!vdat_buffer_empty)
							ivdat_buf_rreq = 1'b1;
					end
				iR[7:0] = DataBuffer[23:16];
				iG[7:0] = DataBuffer[15:8];
				iB[7:0] = DataBuffer[7:0];
			end
		endcase
	end 
	always @(posedge clk)
		begin
			ref_r  <= #1 iR;
			ref_g  <= #1 iG;
			ref_b  <= #1 iB;
			if (RGBbuf_wreq)
				begin
					Ra <= #1 iRa;
					Ba <= #1 iBa;
					Ga <= #1 iGa;
				end
			if (srst)
				begin
					ref_vdat_buffer_rreq <= #1 1'b0;
					ref_rgb_fifo_wreq <= #1 1'b0;
					ref_clut_req <= #1 1'b0;
				end
			else
				begin
					ref_vdat_buffer_rreq <= #1 ivdat_buf_rreq;
					ref_rgb_fifo_wreq <= #1 RGBbuf_wreq;
					ref_clut_req <= #1 iclut_req;
				end
	end
	always @(colcnt or DataBuffer)
	  case (colcnt) 
	      2'b11: ref_clut_offs = DataBuffer[31:24];
	      2'b10: ref_clut_offs = DataBuffer[23:16];
	      2'b01: ref_clut_offs = DataBuffer[15: 8];
	      2'b00: ref_clut_offs = DataBuffer[ 7: 0];
	  endcase
	always @(posedge clk)
	  if (srst)
	    colcnt <= #1 2'b11;
	  else if (RGBbuf_wreq)
	    colcnt <= #1 colcnt -2'h1;
endmodule




module tb;

    // Parameters
    parameter CLK_PERIOD = 10; // Clock period for 100 MHz
    parameter COLOR_DEPTH = 2'b01; // Example: 16bpp
    parameter PSEUDO_COLOR = 0; // Example: Not using pseudo color

    // Inputs
    reg clk;
    reg srst;
    reg [31:0] vdat_buffer_di;
    reg [1:0] ColorDepth;
    reg PseudoColor;
    reg vdat_buffer_empty;
    reg rgb_fifo_full;
    reg clut_ack;
    reg [23:0] clut_q;

    // Outputs
    wire vdat_buffer_rreq,ref_vdat_buffer_rreq;
    wire rgb_fifo_wreq,ref_rgb_fifo_wreq;
    wire [7:0] r, g, b,ref_r,ref_g,ref_b;
    wire clut_req,ref_clut_req;
    wire [7:0] clut_offs,ref_clut_offs;

wire       match;
integer total_tests = 0;
integer failed_tests = 0;
assign  match = ({ref_vdat_buffer_rreq, ref_rgb_fifo_wreq, ref_r, ref_g, ref_b, ref_clut_req, ref_clut_offs} === {vdat_buffer_rreq, rgb_fifo_wreq, r, g, b, clut_req, clut_offs});

    // Instantiate the vga_colproc module
    ref_vga_colproc ref_model (
        .clk(clk),
        .srst(srst),
        .vdat_buffer_di(vdat_buffer_di),
        .ColorDepth(ColorDepth),
        .PseudoColor(PseudoColor),
        .vdat_buffer_empty(vdat_buffer_empty),
        .ref_vdat_buffer_rreq(ref_vdat_buffer_rreq),
        .rgb_fifo_full(rgb_fifo_full),
        .ref_rgb_fifo_wreq(ref_rgb_fifo_wreq),
        .ref_r(ref_r),
        .ref_g(ref_g),
        .ref_b(ref_b),
        .ref_clut_req(ref_clut_req),
        .clut_ack(clut_ack),
        .ref_clut_offs(ref_clut_offs),
        .clut_q(clut_q)
    );

    vga_colproc uut (
        .clk(clk),
        .srst(srst),
        .vdat_buffer_di(vdat_buffer_di),
        .ColorDepth(ColorDepth),
        .PseudoColor(PseudoColor),
        .vdat_buffer_empty(vdat_buffer_empty),
        .vdat_buffer_rreq(vdat_buffer_rreq),
        .rgb_fifo_full(rgb_fifo_full),
        .rgb_fifo_wreq(rgb_fifo_wreq),
        .r(r),
        .g(g),
        .b(b),
        .clut_req(clut_req),
        .clut_ack(clut_ack),
        .clut_offs(clut_offs),
        .clut_q(clut_q)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk; // Toggle clock
    end

    // Test Procedure
    initial begin
        // Initialize inputs
        srst = 1;
        vdat_buffer_di = 32'h0;
        ColorDepth = COLOR_DEPTH;
        PseudoColor = PSEUDO_COLOR;
        vdat_buffer_empty = 1;
        rgb_fifo_full = 0;
        clut_ack = 0;
        clut_q = 24'hFF_00_00; // Example CLUT data (red)

        // Release reset
        #(CLK_PERIOD);
        srst = 0;

        // Test Case 1: Request data from the vdat buffer
        vdat_buffer_empty = 0; // Buffer has data
        #(CLK_PERIOD);
        
        // Simulate writing data to the buffer
        vdat_buffer_di = 32'hA5A5A5A5; // Example data
        #(CLK_PERIOD);
        
        // Request data once the buffer is not empty
        #(CLK_PERIOD);
        if (!vdat_buffer_rreq) begin
            compare();
            $display("Test Case 1 Failed: Expected vdat_buffer_rreq = 1");
        end

        // Test Case 2: Processing in 8bpp mode with pseudo color
        ColorDepth = 2'b00; // 8bpp
        PseudoColor = 1;
        #(CLK_PERIOD);
        if (rgb_fifo_wreq !== 1) begin
            compare();
            $display("Test Case 2 Failed: Expected rgb_fifo_wreq = 1");
        end
        if (clut_req !== 1) begin
            compare();
            $display("Test Case 2 Failed: Expected clut_req = 1");
        end

        // Test Case 3: Check RGB output values
        #(CLK_PERIOD);
        if (r !== 8'hFF || g !== 8'h00 || b !== 8'h00) begin
            compare();
            $display("Test Case 3 Failed: Expected RGB = (FF, 00, 00), got (%h, %h, %h)", r, g, b);
        end

        // Test Case 4: Check color depth 16bpp
        ColorDepth = 2'b01; // 16bpp
        #(CLK_PERIOD);
        if (rgb_fifo_wreq !== 1) begin
            compare();
            $display("Test Case 4 Failed: Expected rgb_fifo_wreq = 1");
        end

        // Test Case 5: Resetting the module
        srst = 1; // Assert reset
        #(CLK_PERIOD);
        srst = 0; // Deassert reset
        if (vdat_buffer_rreq !== 0) begin
            compare();
            $display("Test Case 5 Failed: Expected vdat_buffer_rreq = 0 after reset");
        end

        // Test Case 6: Full RGB FIFO
        rgb_fifo_full = 1; // Simulate full FIFO
        #(CLK_PERIOD);
        if (vdat_buffer_rreq !== 0) begin
            compare();
            $display("Test Case 6 Failed: Expected vdat_buffer_rreq = 0 when rgb_fifo is full");
        end

        repeat(600) begin
            #10; // Wait for 10ns
            vdat_buffer_di = $random;
            ColorDepth = $random % 4;
            PseudoColor = $random % 2;
            vdat_buffer_empty = $random % 2;
            rgb_fifo_full = $random % 2;
            clut_ack = $random % 2;
            clut_q = $random;
            #20;
            compare();
        end

        // Finish simulation
        #(CLK_PERIOD * 10);
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
		//$display("\033[1;32mtestcase is passed!!!\033[0m");
		end

		else begin
		//$display("\033[1;31mtestcase is failed!!!\033[0m");
            failed_tests = failed_tests + 1; 
		end
    end
	endtask
endmodule
