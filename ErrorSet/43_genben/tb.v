 
module aeMB_regf_ref (
   rREGA_ref, rREGB_ref, rDWBDI_ref, dwb_dat_o_ref, fsl_dat_o_ref,
   rOPC, rRA, rRB, rRW, rRD, rMXDST, rPCLNK, rRESULT, rDWBSEL, rBRA,
   rDLY, dwb_dat_i, fsl_dat_i, gclk, grst, gena
   );
   output [31:0] rREGA_ref, rREGB_ref;
   output [31:0] rDWBDI_ref;
   input [5:0] 	 rOPC;   
   input [4:0] 	 rRA, rRB, rRW, rRD;
   input [1:0] 	 rMXDST;
   input [31:2]  rPCLNK;
   input [31:0]  rRESULT;
   input [3:0] 	 rDWBSEL;   
   input 	 rBRA, rDLY;   
   output [31:0] dwb_dat_o_ref;   
   input [31:0]  dwb_dat_i;   
   output [31:0] fsl_dat_o_ref;
   input [31:0]	 fsl_dat_i;   
   input 	 gclk, grst, gena;   
   wire [31:0] 	 wDWBDI = dwb_dat_i; 
   wire [31:0] 	 wFSLDI = fsl_dat_i; 
   reg [31:0] 	 rDWBDI_ref;
   reg [1:0] 	 rSIZ;
   always @(rDWBSEL or wDWBDI or wFSLDI) begin
      case (rDWBSEL)
	4'h8: rDWBDI_ref <= {24'd0, wDWBDI[31:24]};
	4'h4: rDWBDI_ref <= {24'd0, wDWBDI[23:16]};
	4'h2: rDWBDI_ref <= {24'd0, wDWBDI[15:8]};
	4'h1: rDWBDI_ref <= {24'd0, wDWBDI[7:0]};
	4'hC: rDWBDI_ref <= {16'd0, wDWBDI[31:16]};
	4'h3: rDWBDI_ref <= {16'd0, wDWBDI[15:0]};
	4'hF: rDWBDI_ref <= wDWBDI;
	4'h0: rDWBDI_ref <= wFSLDI;       
	default: rDWBDI_ref <= 32'hX;       
      endcase
   end
   always @(posedge gclk)
     if (grst) begin
	rSIZ <= 2'h0;
     end else if (gena) begin
	rSIZ <= rOPC[1:0];	
     end
   reg [31:0] 	 mARAM[0:31],
		 mBRAM[0:31],
		 mDRAM[0:31];
   wire [31:0] 	 rREGW = mDRAM[rRW];   
   wire [31:0] 	 rREGD = mDRAM[rRD];   
   assign 	 rREGA_ref = mARAM[rRA];
   assign 	 rREGB_ref = mBRAM[rRB];
   wire 	 fRDWE = |rRW;   
   reg [31:0] 	 xWDAT;
   always @(rDWBDI_ref or rMXDST or rPCLNK or rREGW
	    or rRESULT)
     case (rMXDST)
       2'o2: xWDAT <= rDWBDI_ref;
       2'o1: xWDAT <= {rPCLNK, 2'o0};
       2'o0: xWDAT <= rRESULT;       
       2'o3: xWDAT <= rREGW; 
     endcase 
   always @(posedge gclk)
     if (grst | fRDWE) begin
	mARAM[rRW] <= xWDAT;
	mBRAM[rRW] <= xWDAT;
	mDRAM[rRW] <= xWDAT;	
     end
   reg [31:0] 	 rDWBDO, xDWBDO;
   wire [31:0] 	 xFSL;   
   wire 	 fFFWD_M = (rRA == rRW) & (rMXDST == 2'o2) & fRDWE;
   wire 	 fFFWD_R = (rRA == rRW) & (rMXDST == 2'o0) & fRDWE;   
   assign 	 fsl_dat_o_ref = rDWBDO;
   assign 	 xFSL = (fFFWD_M) ? rDWBDI_ref :
			(fFFWD_R) ? rRESULT :
			rREGA_ref;   
   wire [31:0] 	 xDST;   
   wire 	 fDFWD_M = (rRW == rRD) & (rMXDST == 2'o2) & fRDWE;
   wire 	 fDFWD_R = (rRW == rRD) & (rMXDST == 2'o0) & fRDWE;   
   assign 	 dwb_dat_o_ref = rDWBDO;
   assign 	 xDST = (fDFWD_M) ? rDWBDI_ref :
			(fDFWD_R) ? rRESULT :
			rREGD;   
   always @(rOPC or xDST or xFSL)
     case (rOPC[1:0])
       2'h0: xDWBDO <= {(4){xDST[7:0]}};
       2'h1: xDWBDO <= {(2){xDST[15:0]}};
       2'h2: xDWBDO <= xDST;
       2'h3: xDWBDO <= xFSL;       
     endcase 
   always @(posedge gclk)
     if (grst) begin
	rDWBDO <= 32'h0;
     end else if (gena) begin
	rDWBDO <= #1 xDWBDO;	
     end
   integer i;
   initial begin
      for (i=0; i<32; i=i+1) begin
	 mARAM[i] <= i;
	 mBRAM[i] <= i + 1;
	 mDRAM[i] <= i + 2;
      end
   end
endmodule






module tb;

    // Testbench signals
    reg [31:0] dwb_dat_i, fsl_dat_i;
    reg [5:0] rOPC;
    reg [4:0] rRA, rRB, rRW, rRD;
    reg [1:0] rMXDST;
    reg [31:2] rPCLNK;
    reg [31:0] rRESULT;
    reg [3:0] rDWBSEL;
    reg rBRA, rDLY;
    reg gclk, grst, gena;

    // Outputs
    wire [31:0] rREGA_ref, rREGA_dut, rREGB_ref, rREGB_dut;
    wire [31:0] rDWBDI_ref, rDWBDI_dut;
    wire [31:0] dwb_dat_o_ref, dwb_dat_o_dut;
    wire [31:0] fsl_dat_o_ref, fsl_dat_o_dut;

    wire match;

    integer total_tests = 0;
	integer failed_tests = 0;

    assign match = ({rREGA_ref, rREGB_ref, rDWBDI_ref, dwb_dat_o_ref, fsl_dat_o_ref} === ({rREGA_ref, rREGB_ref, rDWBDI_ref, dwb_dat_o_ref, fsl_dat_o_ref}^ {rREGA_dut, rREGB_dut, rDWBDI_dut, dwb_dat_o_dut, fsl_dat_o_dut} ^ {rREGA_ref, rREGB_ref, rDWBDI_ref, dwb_dat_o_ref, fsl_dat_o_ref}));

    // Instantiate the aeMB_regf module
    aeMB_regf_ref ref_model (
        .rREGA_ref(rREGA_ref),
        .rREGB_ref(rREGB_ref),
        .rDWBDI_ref(rDWBDI_ref),
        .rOPC(rOPC),
        .rRA(rRA),
        .rRB(rRB),
        .rRW(rRW),
        .rRD(rRD),
        .rMXDST(rMXDST),
        .rPCLNK(rPCLNK),
        .rRESULT(rRESULT),
        .rDWBSEL(rDWBSEL),
        .rBRA(rBRA),
        .rDLY(rDLY),
        .dwb_dat_o_ref(dwb_dat_o_ref),
        .dwb_dat_i(dwb_dat_i),
        .fsl_dat_o_ref(fsl_dat_o_ref),
        .fsl_dat_i(fsl_dat_i), 
        .gclk(gclk),
        .grst(grst),
        .gena(gena)
    );

    aeMB_regf uut (
        .rREGA(rREGA_dut),
        .rREGB(rREGB_dut),
        .rDWBDI(rDWBDI_dut),
        .rOPC(rOPC),
        .rRA(rRA),
        .rRB(rRB),
        .rRW(rRW),
        .rRD(rRD),
        .rMXDST(rMXDST),
        .rPCLNK(rPCLNK),
        .rRESULT(rRESULT),
        .rDWBSEL(rDWBSEL),
        .rBRA(rBRA),
        .rDLY(rDLY),
        .dwb_dat_o(dwb_dat_o_dut),
        .dwb_dat_i(dwb_dat_i),
        .fsl_dat_o(fsl_dat_o_dut),
        .fsl_dat_i(fsl_dat_i), 
        .gclk(gclk),
        .grst(grst),
        .gena(gena)
    );

    // Clock generation
    initial begin
        gclk = 0;
        forever #5 gclk = ~gclk; // 100 MHz clock
    end

    // Test procedure
    initial begin
        // Initialize signals
        grst = 1;
        gena = 0;
        rBRA = 0;
        rDLY = 0;
        rDWBSEL = 0;
        rOPC = 0;
        rRA = 0;
        rRB = 0;
        rRW = 0;
        rRD = 0;
        rMXDST = 0;
        rPCLNK = 0;
        rRESULT = 0;
        dwb_dat_i = 0;
        fsl_dat_i = 0;

        // Release reset
        #10;
        grst = 0;

        // Test Case 1: Write to register and read back
        @(posedge gclk);
        rRW = 5'd1; // Write to register 1
        rMXDST = 2'b00; // Write result
        rRESULT = 32'hAABBCCDD; // Data to write
        gena = 1; // Enable
        @(posedge gclk);
        compare();

        // Test Case 2: Read from register
        rRA = 5'd1; // Read from register 1
        @(posedge gclk);
        compare();

        // Test Case 3: Test different DWBSEL values
        dwb_dat_i = 32'h12345678; // Sample data for DWB
        rDWBSEL = 4'hF; // Select all bits
        @(posedge gclk);
        compare();

        // Test Case 4: Test FSL data output
        rDWBSEL = 4'h0; // Select FSL data
        @(posedge gclk);
        compare();

        // Test Case 5: Test data forwarding logic
        rRW = 5'd2; // Write to register 2
        rMXDST = 2'b10; // Select write to RAM
        rRESULT = 32'hDEADBEEF; // Result to write
        gena = 1; // Enable
        @(posedge gclk);
        compare();
        rRA = 5'd3;
        rRW = 5'd3;
        rRD = 5'd3;
        rMXDST = 2'o2;
        @(posedge gclk);
        compare();
        rMXDST = 2'o0;
        @(posedge gclk);
        compare();

        repeat (91) begin
            rBRA = $random;
            rDLY = $random;
            rDWBSEL = $random;
            rOPC = $random;
            rRA = $random;
            rRB = $random;
            rRW = $random;
            rRD = $random;
            rMXDST = $random;
            rPCLNK = $random;
            rRESULT = $random;
            dwb_dat_i = $random;
            fsl_dat_i = $random;
            @(posedge gclk);
            compare();            
        end

        // Test Case 6: Check default reset behavior
        gena = 0;
        @(posedge gclk);
        compare();
        grst = 1;
        @(posedge gclk);
        @(posedge gclk);
        compare();


        $display("\033[1;34mTotal testcases: %d, Failed testcases: %d\033[0m", total_tests, failed_tests);
        // Finish simulation
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
//				$display("testcase is passed!!!");
            	//$display("grst = %h, gena = %h, rOPC = %h, rRA = %h, rRB = %h, rRW = %h, rRD = %h, rMXDST = %h, rPCLNK = %h, rRESULT = %h, rDWBSEL = %h, rBRA = %h, rDLY = %h, dwb_dat_i = %h, fsl_dat_i = %h, rREGA_dut = %h, rREGB_dut = %h, rDWBDI_dut = %h, dwb_dat_o_dut = %h, fsl_dat_o_dut = %h, rREGA_ref = %h, rREGB_ref = %h, rDWBDI_ref = %h, dwb_dat_o_ref = %h, fsl_dat_o_ref = %h", grst, gena, rOPC, rRA, rRB, rRW, rRD, rMXDST, rPCLNK, rRESULT, rDWBSEL, rBRA, rDLY, dwb_dat_i, fsl_dat_i, rREGA_dut, rREGB_dut, rDWBDI_dut, dwb_dat_o_dut, fsl_dat_o_dut, rREGA_ref, rREGB_ref, rDWBDI_ref, dwb_dat_o_ref, fsl_dat_o_ref);      //displaying inputs, outputs and result
			end

		else begin
			//$display("\033[1;31mtestcase is failed!!!\033[0m");
           // $display("grst = %h, gena = %h, rOPC = %h, rRA = %h, rRB = %h, rRW = %h, rRD = %h, rMXDST = %h, rPCLNK = %h, rRESULT = %h, rDWBSEL = %h, rBRA = %h, rDLY = %h, dwb_dat_i = %h, fsl_dat_i = %h, rREGA_dut = %h, rREGB_dut = %h, rDWBDI_dut = %h, dwb_dat_o_dut = %h, fsl_dat_o_dut = %h, rREGA_ref = %h, rREGB_ref = %h, rDWBDI_ref = %h, dwb_dat_o_ref = %h, fsl_dat_o_ref = %h", grst, gena, rOPC, rRA, rRB, rRW, rRD, rMXDST, rPCLNK, rRESULT, rDWBSEL, rBRA, rDLY, dwb_dat_i, fsl_dat_i, rREGA_dut, rREGB_dut, rDWBDI_dut, dwb_dat_o_dut, fsl_dat_o_dut, rREGA_ref, rREGB_ref, rDWBDI_ref, dwb_dat_o_ref, fsl_dat_o_ref);      //displaying inputs, outputs and resultinputs, outputs and result
            failed_tests = failed_tests + 1; 
		end
       end
	endtask

    initial begin
        $dumpfile("sim.fsdb");
        $dumpvars(0);
    end

endmodule

