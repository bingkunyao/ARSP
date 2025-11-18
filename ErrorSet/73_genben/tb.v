 
module ref_tiny_spi(
   input	  rst_i,
   input	  clk_i,
   input	  stb_i,
   input	  we_i,
   output [31:0]  ref_dat_o,
   input [31:0]   dat_i,
   output	  ref_int_o,
   input [2:0]	  adr_i,
   output	  ref_MOSI,
   output	  ref_SCLK,
   input	  MISO
   );
   parameter BAUD_WIDTH = 8;
   parameter BAUD_DIV = 0;
   parameter SPI_MODE = 0;
   parameter BC_WIDTH = 3;
   parameter DIV_WIDTH = BAUD_DIV ? $clog2(BAUD_DIV / 2 - 1) : BAUD_WIDTH;
   reg [7:0]	  sr8, bb8;
   wire [7:0]	  sr8_sf;
   reg [BC_WIDTH - 1:0]		bc, bc_next;
   reg [DIV_WIDTH - 1:0]	ccr;
   reg [DIV_WIDTH - 1:0]	cc, cc_next;
   wire		  misod;
   wire		  cstb, wstb, bstb, istb;
   reg		  sck;
   reg		  sf, ld;
   reg		  bba;   
   reg		  txren, txeen;
   wire 	  txr, txe;
   wire		  cpol, cpha;
   reg		  cpolr, cphar;
   wire 	  wr;
   wire 	  cyc_i; 
   wire 	  ack_o; 
   assign cyc_i = 1'b1;  
   assign ack_o = stb_i & cyc_i; 
   assign wr = stb_i & cyc_i & we_i & ack_o;
   assign wstb = wr & (adr_i == 1);
   assign istb = wr & (adr_i == 2);
   assign cstb = wr & (adr_i == 3);
   assign bstb = wr & (adr_i == 4);
   assign sr8_sf = { sr8[6:0],misod };
   assign ref_dat_o =
		      (sr8 & {8{(adr_i == 0)}})
		    | (bb8 & {8{(adr_i == 1)}})
		    | ({ txr, txe } & {8{(adr_i == 2)}})
		      ;
   parameter
     IDLE = 0,
     PHASE1 = 1,
     PHASE2 = 2
     ;
   reg [1:0] spi_seq, spi_seq_next;
   always @(posedge clk_i or posedge rst_i)
     if (rst_i)
       spi_seq <= IDLE;
     else
       spi_seq <= spi_seq_next;
   always @(posedge clk_i)
     begin
	cc <= cc_next;
	bc <= bc_next;
     end
   always @(bba or bc or cc or ccr or cpha or cpol or spi_seq)
     begin
	sck = cpol;
	cc_next = BAUD_DIV ? (BAUD_DIV / 2 - 1) : ccr;
	bc_next = bc;
	ld = 1'b0;
	sf = 1'b0;
	case (spi_seq)
	  IDLE:
	    begin
	       if (bba)
		 begin
		    bc_next = 7;
		    ld = 1'b1;
		    spi_seq_next = PHASE2;
		 end
	       else
		 spi_seq_next = IDLE;
	    end
	  PHASE2:
	    begin
	       sck = (cpol ^ cpha);
	       if (cc == 0)
		 spi_seq_next = PHASE1;
	       else
		 begin
		    cc_next = cc - 1;
		    spi_seq_next = PHASE2;
		 end
	    end
	  PHASE1:
	    begin
	       sck = ~(cpol ^ cpha);
	       if (cc == 0)
		 begin
		    bc_next = bc -1;
		    sf = 1'b1;
		    if (bc == 0)
		      begin
			 if (bba)
			   begin
			      bc_next = 7;
			      ld = 1'b1;
			      spi_seq_next = PHASE2;
			   end
			 else
			   spi_seq_next = IDLE;
		      end
		    else
		      spi_seq_next = PHASE2;
		 end
	       else
		 begin
		    cc_next = cc - 1;
		    spi_seq_next = PHASE1;
		 end
	    end
	endcase
     end 
   always @(posedge clk_i)
     begin
	if (cstb) 
	  { cpolr, cphar } <= dat_i;
	else
	  { cpolr, cphar } <= { cpolr, cphar };
	if (istb) 
	  { txren, txeen } <= dat_i;
	else
	  { txren, txeen } <= { txren, txeen };
	if (bstb) 
	  ccr <= dat_i;
	else
	  ccr <= ccr;
	if (ld)   
	  sr8 <= bb8;
	else if (sf)
	  sr8 <= sr8_sf;
	else
	  sr8 <= sr8;
	if (wstb) 
	  bb8 <= dat_i;
	else if (ld)
	  bb8 <= (spi_seq == IDLE) ? sr8 : sr8_sf;
	else
	  bb8 <= bb8;
     end 
   always @(posedge clk_i or posedge rst_i)
     begin
	if (rst_i)
	  bba <= 1'b0;
	else if (wstb)
	  bba <= 1'b1;
	else if (ld)
	  bba <= 1'b0;
	else
	  bba <= bba;
     end
   assign { cpol, cpha } = ((SPI_MODE >= 0) & (SPI_MODE < 4)) ?
			   SPI_MODE : { cpolr, cphar };
   assign txe = (spi_seq == IDLE);
   assign txr = ~bba;
   assign ref_int_o = (txr & txren) | (txe & txeen);
   assign ref_SCLK = sck;
   assign ref_MOSI = sr8[7];
   assign misod = MISO;
endmodule




`timescale 1ns / 1ps

module tb;

  // Inputs
  reg rst_i;
  reg clk_i;
  reg stb_i;
  reg we_i;
  reg [31:0] dat_i;
  reg [2:0] adr_i;
  reg MISO;

  // Outputs
  wire [31:0] dat_o,ref_dat_o;
  wire int_o,ref_int_o;
  wire SCLK,ref_SCLK;
  wire MOSI,ref_MOSI;

wire       match;
integer    total_tests = 0;
integer    failed_tests = 0;
integer    txr;
integer    txren;

integer       bc;
integer       bc_next;
integer       sck;
integer       sf;
integer       cpol;
integer       cpha;
integer       cyc_i;

assign match = ({ref_dat_o, ref_int_o, ref_SCLK, ref_MOSI} === {dat_o, int_o, SCLK, MOSI});

  tiny_spi uut (
    .rst_i(rst_i), 
    .clk_i(clk_i), 
    .stb_i(stb_i), 
    .we_i(we_i), 
    .dat_o(dat_o), 
    .dat_i(dat_i), 
    .int_o(int_o), 
    .adr_i(adr_i), 
    .MOSI(MOSI), 
    .SCLK(SCLK), 
    .MISO(MISO)
  );

  ref_tiny_spi ref_model (
    .rst_i(rst_i), 
    .clk_i(clk_i), 
    .stb_i(stb_i), 
    .we_i(we_i), 
    .ref_dat_o(ref_dat_o), 
    .dat_i(dat_i), 
    .ref_int_o(ref_int_o), 
    .adr_i(adr_i), 
    .ref_MOSI(ref_MOSI), 
    .ref_SCLK(ref_SCLK), 
    .MISO(MISO)
  );

  always #5 clk_i = ~clk_i; 

  initial begin
    rst_i = 1;
    clk_i = 0;
    stb_i = 0;
    we_i = 0;
    dat_i = 0;
    adr_i = 0;
    MISO = 0;
    #10;
    rst_i = 0; 

    stb_i = 1; we_i = 1; adr_i = 0; dat_i = 32'hA5A5A5A5; #10;
    stb_i = 1; we_i = 0; adr_i = 0; #10;
    check_value(dat_o, 32'hA5A5A5A5, "Read register 0 failed");
    compare();


    stb_i = 1; we_i = 1; adr_i = 3; dat_i = 32'h00000001; #10;
    stb_i = 1; we_i = 1; adr_i = 1; dat_i = 32'hA5A5A5A5; #10;
    check_SPI_signals(1);
    compare();


    stb_i = 1; we_i = 1; adr_i = 2; dat_i = 32'h00000003; #10;
    check_interrupt();
    compare();

    toggle_signals();
    compare();

    repeat (2000) begin
       #10;
       bc = uut.bc;
       bc_next = uut.bc_next;
       sck = uut.sck;
       sf = uut.sf;
       cpol = uut.cpol;
       cpha = uut.cpha;
       cyc_i = uut.cyc_i;
       #10;
       rst_i = 0;
       stb_i = $random;
       we_i = $random;
       dat_i = $random;
       adr_i = $random % 8;
       MISO = $random;

       bc = $random % 8;
       bc_next = $random;
       sck = $random;
       sf = $random;
       cpol = $random;
       cpha = $random;
       cyc_i = $random;

       #10;
       compare();
    end


      $display("\033[1;34mAll tests completed.\033[0m");
      $display("\033[1;34mTotal testcases: %d, Failed testcases: %d\033[0m", total_tests, failed_tests);
      if (failed_tests==0) begin
            $display("=====================Your Design Passed======================");
    end
      $finish;
  end

  task check_value;
    input [31:0] expected;
    input [31:0] actual;
    input string message;
    begin
      if (actual !== expected) begin
        $display("%s at time %t", message, $time);
      end
    end
  endtask

  task check_SPI_signals;
    input [31:0] mode;
    begin
      case (mode)
        1: begin // CPOL=0, CPHA=1
          #10;
          if (MOSI !== 1'b0) begin
            $display("MOSI should be low on SCLK rising edge in mode 1 at time %t", $time);
          end
          #10;
          if (MOSI !== 1'b1) begin
            $display("MOSI should be high on SCLK falling edge in mode 1 at time %t", $time);
          end
        end
      endcase
    end
  endtask

  task check_interrupt;
    begin
      force uut.txr = txr;
      force ref_model.txr = txr;
      force uut.txren = txren;
      force ref_model.txren = txren;
      if (txr && txren) begin
        if (int_o !== 1'b1) begin
          $display("Interrupt should be high when txr and txren are high at time %t", $time);
        end
      end
        #10;
      release uut.txr;
      release uut.txren;
      release ref_model.txr;
      release ref_model.txren;
    end
  endtask


  task toggle_signals;
    begin
      rst_i = ~rst_i;
      stb_i = ~stb_i;
      we_i = ~we_i;
      dat_i = ~dat_i;
      adr_i = ~adr_i;
      MISO = ~MISO;
    end
  endtask

  task compare;
  begin
     total_tests = total_tests + 1;
     if (match)      
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
