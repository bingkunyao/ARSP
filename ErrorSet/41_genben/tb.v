 
module aeMB_ctrl_ref (
   rMXDST_ref, rMXSRC_ref, rMXTGT_ref, rMXALT_ref, rMXALU_ref, rRW_ref, dwb_stb_o_ref, dwb_wre_o_ref,
   fsl_stb_o_ref, fsl_wre_o_ref,
   rDLY, rIMM, rALT, rOPC, rRD, rRA, rRB, rPC, rBRA, rMSR_IE, xIREG,
   dwb_ack_i, iwb_ack_i, fsl_ack_i, gclk, grst, gena
   );
   output [1:0]  rMXDST_ref;
   output [1:0]  rMXSRC_ref, rMXTGT_ref, rMXALT_ref;
   output [2:0]  rMXALU_ref;   
   output [4:0]  rRW_ref;
   input 	 rDLY;
   input [15:0]  rIMM;
   input [10:0]  rALT;
   input [5:0] 	 rOPC;
   input [4:0] 	 rRD, rRA, rRB;
   input [31:2]  rPC;
   input 	 rBRA;
   input 	 rMSR_IE;
   input [31:0]  xIREG;   
   output 	 dwb_stb_o_ref;
   output 	 dwb_wre_o_ref;
   input 	 dwb_ack_i;
   input 	 iwb_ack_i;
   output 	 fsl_stb_o_ref;
   output 	 fsl_wre_o_ref;
   input 	 fsl_ack_i;   
   input 	 gclk, grst, gena;
   wire [5:0] 	 wOPC;
   wire [4:0] 	 wRD, wRA, wRB;
   wire [10:0] 	 wALT;   
   assign 	 {wOPC, wRD, wRA, wRB, wALT} = xIREG; 
   wire 	 fSFT = (rOPC == 6'o44);
   wire 	 fLOG = ({rOPC[5:4],rOPC[2]} == 3'o4);   
   wire 	 fMUL = (rOPC == 6'o20) | (rOPC == 6'o30);
   wire 	 fBSF = (rOPC == 6'o21) | (rOPC == 6'o31);
   wire 	 fDIV = (rOPC == 6'o22);   
   wire 	 fRTD = (rOPC == 6'o55);
   wire 	 fBCC = (rOPC == 6'o47) | (rOPC == 6'o57);
   wire 	 fBRU = (rOPC == 6'o46) | (rOPC == 6'o56);
   wire 	 fBRA = fBRU & rRA[3];   
   wire 	 fIMM = (rOPC == 6'o54);
   wire 	 fMOV = (rOPC == 6'o45);   
   wire 	 fLOD = ({rOPC[5:4],rOPC[2]} == 3'o6);
   wire 	 fSTR = ({rOPC[5:4],rOPC[2]} == 3'o7);
   wire 	 fLDST = (&rOPC[5:4]);   
   wire          fPUT = (rOPC == 6'o33) & rRB[4];
   wire 	 fGET = (rOPC == 6'o33) & !rRB[4];   
   wire 	 wSFT = (wOPC == 6'o44);
   wire 	 wLOG = ({wOPC[5:4],wOPC[2]} == 3'o4);   
   wire 	 wMUL = (wOPC == 6'o20) | (wOPC == 6'o30);
   wire 	 wBSF = (wOPC == 6'o21) | (wOPC == 6'o31);
   wire 	 wDIV = (wOPC == 6'o22);   
   wire 	 wRTD = (wOPC == 6'o55);
   wire 	 wBCC = (wOPC == 6'o47) | (wOPC == 6'o57);
   wire 	 wBRU = (wOPC == 6'o46) | (wOPC == 6'o56);
   wire 	 wBRA = wBRU & wRA[3];   
   wire 	 wIMM = (wOPC == 6'o54);
   wire 	 wMOV = (wOPC == 6'o45);   
   wire 	 wLOD = ({wOPC[5:4],wOPC[2]} == 3'o6);
   wire 	 wSTR = ({wOPC[5:4],wOPC[2]} == 3'o7);
   wire 	 wLDST = (&wOPC[5:4]);   
   wire          wPUT = (wOPC == 6'o33) & wRB[4];
   wire 	 wGET = (wOPC == 6'o33) & !wRB[4];   
   reg [31:2] 	 rPCLNK, xPCLNK;
   reg [1:0] 	 rMXDST_ref, xMXDST;
   reg [4:0] 	 rRW_ref, xRW;   
   reg [1:0] 	 rMXSRC_ref, xMXSRC;
   reg [1:0] 	 rMXTGT_ref, xMXTGT;
   reg [1:0] 	 rMXALT_ref, xMXALT;
   wire 	 wRDWE = |xRW;
   wire 	 wAFWD_M = (xRW == wRA) & (xMXDST == 2'o2) & wRDWE;
   wire 	 wBFWD_M = (xRW == wRB) & (xMXDST == 2'o2) & wRDWE;
   wire 	 wAFWD_R = (xRW == wRA) & (xMXDST == 2'o0) & wRDWE;   
   wire 	 wBFWD_R = (xRW == wRB) & (xMXDST == 2'o0) & wRDWE;
   always @(rBRA or wAFWD_M or wAFWD_R or wBCC or wBFWD_M
	    or wBFWD_R or wBRU or wOPC) 
     if (rBRA) begin
	xMXALT <= 2'h0;
	xMXSRC <= 2'h0;
	xMXTGT <= 2'h0;
     end else begin
	xMXSRC <= (wBRU | wBCC) ? 2'o3 : 
		  (wAFWD_M) ? 2'o2 : 
		  (wAFWD_R) ? 2'o1 : 
		  2'o0; 
	xMXTGT <= (wOPC[3]) ? 2'o3 : 
		  (wBFWD_M) ? 2'o2 : 
		  (wBFWD_R) ? 2'o1 : 
		  2'o0; 
	xMXALT <= (wAFWD_M) ? 2'o2 : 
		  (wAFWD_R) ? 2'o1 : 
		  2'o0; 
     end 
   reg [2:0]     rMXALU_ref, xMXALU;
   always @(rBRA or wBRA or wBSF or wDIV or wLOG or wMOV
	    or wMUL or wSFT)
     if (rBRA) begin
	xMXALU <= 3'h0;
     end else begin
	xMXALU <= (wBRA | wMOV) ? 3'o3 :
		  (wSFT) ? 3'o2 :
		  (wLOG) ? 3'o1 :
		  (wMUL) ? 3'o4 :
		  (wBSF) ? 3'o5 :
		  (wDIV) ? 3'o6 :
		  3'o0;      	
     end 
   wire 	 fSKIP = (rBRA & !rDLY);
   always @(fBCC or fBRU or fGET or fLOD or fRTD or fSKIP
	    or fSTR or rRD)
     if (fSKIP) begin
	xMXDST <= 2'h0;
	xRW <= 5'h0;
     end else begin
	xMXDST <= (fSTR | fRTD | fBCC) ? 2'o3 :
		  (fLOD | fGET) ? 2'o2 :
		  (fBRU) ? 2'o1 :
		  2'o0;
	xRW <= rRD;
     end 
   wire 	 fDACK = !(dwb_stb_o_ref ^ dwb_ack_i);
   reg 		 rDWBSTB, xDWBSTB;
   reg 		 rDWBWRE, xDWBWRE;
   assign 	 dwb_stb_o_ref = rDWBSTB;
   assign 	 dwb_wre_o_ref = rDWBWRE;
   always @(fLOD or fSKIP or fSTR or iwb_ack_i)
     if (fSKIP) begin
	xDWBSTB <= 1'h0;
	xDWBWRE <= 1'h0;
     end else begin
	xDWBSTB <= (fLOD | fSTR) & iwb_ack_i;
	xDWBWRE <= fSTR & iwb_ack_i;	
     end
   always @(posedge gclk)
     if (grst) begin
	rDWBSTB <= 1'h0;
	rDWBWRE <= 1'h0;
     end else if (fDACK) begin
	rDWBSTB <= #1 xDWBSTB;
	rDWBWRE <= #1 xDWBWRE;	
     end
   wire 	 fFACK = !(fsl_stb_o_ref ^ fsl_ack_i);   
   reg 		 rFSLSTB, xFSLSTB;
   reg 		 rFSLWRE, xFSLWRE;
   assign 	 fsl_stb_o_ref = rFSLSTB;
   assign 	 fsl_wre_o_ref = rFSLWRE;   
   always @(fGET or fPUT or fSKIP or iwb_ack_i) 
     if (fSKIP) begin
	xFSLSTB <= 1'h0;
	xFSLWRE <= 1'h0;
     end else begin
	xFSLSTB <= (fPUT | fGET) & iwb_ack_i;
	xFSLWRE <= fPUT & iwb_ack_i;	
     end
   always @(posedge gclk)
     if (grst) begin
	rFSLSTB <= 1'h0;
	rFSLWRE <= 1'h0;
     end else if (fFACK) begin
	rFSLSTB <= #1 xFSLSTB;
	rFSLWRE <= #1 xFSLWRE;	
     end
   always @(posedge gclk)
     if (grst) begin
	rMXALT_ref <= 2'h0;
	rMXALU_ref <= 3'h0;
	rMXDST_ref <= 2'h0;
	rMXSRC_ref <= 2'h0;
	rMXTGT_ref <= 2'h0;
	rRW_ref <= 5'h0;
     end else if (gena) begin 
	rMXDST_ref <= #1 xMXDST;
	rRW_ref <= #1 xRW;
	rMXSRC_ref <= #1 xMXSRC;
	rMXTGT_ref <= #1 xMXTGT;
	rMXALT_ref <= #1 xMXALT;	
	rMXALU_ref <= #1 xMXALU;	
     end
endmodule






module tb;

    // Parameters
    parameter IW = 24;

    // Testbench signals
    reg rDLY;
    reg [15:0] rIMM;
    reg [10:0] rALT;
    reg [5:0] rOPC;
    reg [4:0] rRD, rRA, rRB;
    reg [31:2] rPC;
    reg rBRA;
    reg rMSR_IE;
    reg [31:0] xIREG;
    reg dwb_ack_i, iwb_ack_i, fsl_ack_i;
    reg gclk, grst, gena;

    // Outputs
    wire [1:0] rMXDST_ref, rMXDST_dut;
    wire [1:0] rMXSRC_ref, rMXSRC_dut, rMXTGT_ref, rMXTGT_dut, rMXALT_ref, rMXALT_dut;
    wire [2:0] rMXALU_ref, rMXALU_dut;   
    wire [4:0] rRW_ref, rRW_dut;
    wire dwb_stb_o_ref, dwb_stb_o_dut;
    wire dwb_wre_o_ref, dwb_wre_o_dut;
    wire fsl_stb_o_ref, fsl_stb_o_dut;
    wire fsl_wre_o_ref, fsl_wre_o_dut;

    wire match;

    integer total_tests = 0;
	integer failed_tests = 0;

    assign match = ({rMXDST_ref, rMXSRC_ref, rMXTGT_ref, rMXALT_ref, rMXALU_ref, rRW_ref, dwb_stb_o_ref, dwb_wre_o_ref, fsl_stb_o_ref, fsl_wre_o_ref} === ({rMXDST_ref, rMXSRC_ref, rMXTGT_ref, rMXALT_ref, rMXALU_ref, rRW_ref, dwb_stb_o_ref, dwb_wre_o_ref, fsl_stb_o_ref, fsl_wre_o_ref} ^ {rMXDST_dut, rMXSRC_dut, rMXTGT_dut, rMXALT_dut, rMXALU_dut, rRW_dut, dwb_stb_o_dut, dwb_wre_o_dut, fsl_stb_o_dut, fsl_wre_o_dut} ^ {rMXDST_ref, rMXSRC_ref, rMXTGT_ref, rMXALT_ref, rMXALU_ref, rRW_ref, dwb_stb_o_ref, dwb_wre_o_ref, fsl_stb_o_ref, fsl_wre_o_ref}));

    // Instantiate the aeMB_ctrl module
    aeMB_ctrl_ref ref_model (
        .rMXDST_ref(rMXDST_ref),
        .rMXSRC_ref(rMXSRC_ref),
        .rMXTGT_ref(rMXTGT_ref),
        .rMXALT_ref(rMXALT_ref),
        .rMXALU_ref(rMXALU_ref),   
        .rRW_ref(rRW_ref),
        .dwb_stb_o_ref(dwb_stb_o_ref),
        .dwb_wre_o_ref(dwb_wre_o_ref),
        .fsl_stb_o_ref(fsl_stb_o_ref),
        .fsl_wre_o_ref(fsl_wre_o_ref),
        .rDLY(rDLY),
        .rIMM(rIMM),
        .rALT(rALT),
        .rOPC(rOPC),
        .rRD(rRD),
        .rRA(rRA),
        .rRB(rRB),
        .rPC(rPC),
        .rBRA(rBRA),
        .rMSR_IE(rMSR_IE),
        .xIREG(xIREG),   
        .dwb_ack_i(dwb_ack_i),
        .iwb_ack_i(iwb_ack_i),
        .fsl_ack_i(fsl_ack_i),   
        .gclk(gclk),
        .grst(grst),
        .gena(gena)
    );
    aeMB_ctrl uut (
        .rMXDST(rMXDST_dut),
        .rMXSRC(rMXSRC_dut),
        .rMXTGT(rMXTGT_dut),
        .rMXALT(rMXALT_dut),
        .rMXALU(rMXALU_dut),   
        .rRW(rRW_dut),
        .dwb_stb_o(dwb_stb_o_dut),
        .dwb_wre_o(dwb_wre_o_dut),
        .fsl_stb_o(fsl_stb_o_dut),
        .fsl_wre_o(fsl_wre_o_dut),
        .rDLY(rDLY),
        .rIMM(rIMM),
        .rALT(rALT),
        .rOPC(rOPC),
        .rRD(rRD),
        .rRA(rRA),
        .rRB(rRB),
        .rPC(rPC),
        .rBRA(rBRA),
        .rMSR_IE(rMSR_IE),
        .xIREG(xIREG),   
        .dwb_ack_i(dwb_ack_i),
        .iwb_ack_i(iwb_ack_i),
        .fsl_ack_i(fsl_ack_i),   
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
        rDLY = 0;
        rIMM = 0;
        rALT = 0;
        rOPC = 0;
        rRD = 0;
        rRA = 0;
        rRB = 0;
        rPC = 0;
        rBRA = 0;
        rMSR_IE = 0;
        xIREG = 0;
        dwb_ack_i = 0;
        iwb_ack_i = 0;
        fsl_ack_i = 0;

        // Release reset
        #10;
        grst = 0;

        // Test Case 1: Test with different OPC values
        @(posedge gclk);
        rOPC = 6'o55; // RTD instruction
        rRD = 5'b00001; // Register 1
        rRA = 5'b00010; // Register 2
        rRB = 5'b00011; // Register 3
        xIREG = {rOPC, rRD, rRA, rRB, rALT}; // Set values
        gena = 1; // Enable
        // Wait for a clock cycle
        @(posedge gclk);
        compare();

        // Test Case 2: Test with BCC instruction
        rOPC = 6'o47; // BCC instruction
        xIREG = {rOPC, rRD, rRA, rRB, rALT};
        // Wait for a clock cycle
        @(posedge gclk);
        compare();

        // Test Case 3: Test with STR instruction
        rOPC = 6'o54; // STR instruction
        rBRA = 0; // No branch
        xIREG = {rOPC, rRD, rRA, rRB, rALT};
        // Wait for a clock cycle
        @(posedge gclk);
        compare();

        // Test Case 4: Check DWB signals
        rOPC = 6'o44;
        dwb_ack_i = 1; // Simulate DWB acknowledgment
        @(posedge gclk);
        compare();

        // Test Case 5: Check FSL signals
        fsl_ack_i = 1; // Simulate FSL acknowledgment
        @(posedge gclk);
        compare();

        rRA = 5'b11111;
        rOPC = 6'o46;
        @(posedge gclk);
        compare();
        rOPC = 6'o33;
        rRB = 5'b01111;

        @(posedge gclk);
        compare();

        iwb_ack_i = 1;
        fsl_ack_i = 0;
        rRB = 5'b11111;
        @(posedge gclk);
        @(posedge gclk);
        compare();        


        repeat (690) begin
            gena = $random;
            rDLY = $random;
            rIMM = $random;
            rALT = $random;
            rOPC = $random;
            rRD = $random;
            rRA = $random;
            rRB = $random;
            rPC = $random;
            rBRA = $random;
            rMSR_IE = $random;
            xIREG = $random;
            dwb_ack_i = $random;
            iwb_ack_i = $random;
            fsl_ack_i = $random;
            @(posedge gclk);
            compare();
        end

        // Test Case 6: Check default reset behavior
        grst = 1;
        @(posedge gclk);
        compare();
        @(posedge gclk);
        compare();        

        // Finish simulation
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
//				//$display("testcase is passed!!!");
            	//$display("grst = %h, gena = %h, rDLY = %h, rIMM = %h, rALT = %h, rOPC = %h, rRD = %h, rRA = %h, rRB = %h, rPC = %h, rBRA = %h, rMSR_IE = %h, xIREG = %h, dwb_ack_i = %h, iwb_ack_i = %h, fsl_ack_i = %h, rMXDST_dut = %h, rMXSRC_dut = %h, rMXTGT_dut = %h, rMXALT_dut = %h, rMXALU_dut = %h, rRW_dut = %h, dwb_stb_o_dut = %h, dwb_wre_o_dut = %h, fsl_stb_o_dut = %h, fsl_wre_o_dut = %h, rMXDST_ref = %h, rMXSRC_ref = %h, rMXTGT_ref = %h, rMXALT_ref = %h, rMXALU_ref = %h, rRW_ref = %h, dwb_stb_o_ref = %h, dwb_wre_o_ref = %h, fsl_stb_o_ref = %h, fsl_wre_o_ref = %h", grst, gena, rDLY, rIMM, rALT, rOPC, rRD, rRA, rRB, rPC, rBRA, rMSR_IE, xIREG, dwb_ack_i, iwb_ack_i, fsl_ack_i, rMXDST_dut, rMXSRC_dut, rMXTGT_dut, rMXALT_dut, rMXALU_dut, rRW_dut, dwb_stb_o_dut, dwb_wre_o_dut, fsl_stb_o_dut, fsl_wre_o_dut, rMXDST_ref, rMXSRC_ref, rMXTGT_ref, rMXALT_ref, rMXALU_ref, rRW_ref, dwb_stb_o_ref, dwb_wre_o_ref, fsl_stb_o_ref, fsl_wre_o_ref);      //displaying inputs, outputs and result
			end

		else begin
			//$display("\033[1;31mtestcase is failed!!!\033[0m");
            //$display("grst = %h, gena = %h, rDLY = %h, rIMM = %h, rALT = %h, rOPC = %h, rRD = %h, rRA = %h, rRB = %h, rPC = %h, rBRA = %h, rMSR_IE = %h, xIREG = %h, dwb_ack_i = %h, iwb_ack_i = %h, fsl_ack_i = %h, rMXDST_dut = %h, rMXSRC_dut = %h, rMXTGT_dut = %h, rMXALT_dut = %h, rMXALU_dut = %h, rRW_dut = %h, dwb_stb_o_dut = %h, dwb_wre_o_dut = %h, fsl_stb_o_dut = %h, fsl_wre_o_dut = %h, rMXDST_ref = %h, rMXSRC_ref = %h, rMXTGT_ref = %h, rMXALT_ref = %h, rMXALU_ref = %h, rRW_ref = %h, dwb_stb_o_ref = %h, dwb_wre_o_ref = %h, fsl_stb_o_ref = %h, fsl_wre_o_ref = %h", grst, gena, rDLY, rIMM, rALT, rOPC, rRD, rRA, rRB, rPC, rBRA, rMSR_IE, xIREG, dwb_ack_i, iwb_ack_i, fsl_ack_i, rMXDST_dut, rMXSRC_dut, rMXTGT_dut, rMXALT_dut, rMXALU_dut, rRW_dut, dwb_stb_o_dut, dwb_wre_o_dut, fsl_stb_o_dut, fsl_wre_o_dut, rMXDST_ref, rMXSRC_ref, rMXTGT_ref, rMXALT_ref, rMXALU_ref, rRW_ref, dwb_stb_o_ref, dwb_wre_o_ref, fsl_stb_o_ref, fsl_wre_o_ref);      //displaying inputs, outputs and result
            failed_tests = failed_tests + 1; 
		end
    end
	endtask

    initial begin
        $dumpfile("sim.fsdb");
        $dumpvars(0);
    end

endmodule

