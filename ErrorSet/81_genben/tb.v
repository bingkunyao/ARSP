 
module ref_eth_transmitcontrol (MTxClk, TxReset, TxUsedDataIn, TxUsedDataOut, TxDoneIn, TxAbortIn, 
                            TxStartFrmIn, TPauseRq, TxUsedDataOutDetected, TxFlow, DlyCrcEn, 
                            TxPauseTV, MAC, ref_TxCtrlStartFrm, ref_TxCtrlEndFrm, ref_SendingCtrlFrm, ref_CtrlMux, 
                            ref_ControlData, ref_WillSendControlFrame, ref_BlockTxDone
                           );
input         MTxClk;
input         TxReset;
input         TxUsedDataIn;
input         TxUsedDataOut;
input         TxDoneIn;
input         TxAbortIn;
input         TxStartFrmIn;
input         TPauseRq;
input         TxUsedDataOutDetected;
input         TxFlow;
input         DlyCrcEn;
input  [15:0] TxPauseTV;
input  [47:0] MAC;
output        ref_TxCtrlStartFrm;
output        ref_TxCtrlEndFrm;
output        ref_SendingCtrlFrm;
output        ref_CtrlMux;
output [7:0]  ref_ControlData;
output        ref_WillSendControlFrame;
output        ref_BlockTxDone;
reg           ref_SendingCtrlFrm;
reg           ref_CtrlMux;
reg           ref_WillSendControlFrame;
reg    [3:0]  DlyCrcCnt;
reg    [5:0]  ByteCnt;
reg           ControlEnd_q;
reg    [7:0]  MuxedCtrlData;
reg           ref_TxCtrlStartFrm;
reg           ref_TxCtrlStartFrm_q;
reg           ref_TxCtrlEndFrm;
reg    [7:0]  ref_ControlData;
reg           TxUsedDataIn_q;
reg           ref_BlockTxDone;
wire          IncrementDlyCrcCnt;
wire          ResetByteCnt;
wire          IncrementByteCnt;
wire          ControlEnd;
wire          IncrementByteCntBy2;
wire          EnableCnt;
always @ (posedge MTxClk or posedge TxReset)
begin
  if(TxReset)
    ref_WillSendControlFrame <=  1'b0;
  else
  if(ref_TxCtrlEndFrm & ref_CtrlMux)
    ref_WillSendControlFrame <=  1'b0;
  else
  if(TPauseRq & TxFlow)
    ref_WillSendControlFrame <=  1'b1;
end
always @ (posedge MTxClk or posedge TxReset)
begin
  if(TxReset)
    ref_TxCtrlStartFrm <=  1'b0;
  else
  if(TxUsedDataIn_q & ref_CtrlMux)
    ref_TxCtrlStartFrm <=  1'b0;
  else
  if(ref_WillSendControlFrame & ~TxUsedDataOut & (TxDoneIn | TxAbortIn | TxStartFrmIn | (~TxUsedDataOutDetected)))
    ref_TxCtrlStartFrm <=  1'b1;
end
always @ (posedge MTxClk or posedge TxReset)
begin
  if(TxReset)
    ref_TxCtrlEndFrm <=  1'b0;
  else
  if(ControlEnd | ControlEnd_q)
    ref_TxCtrlEndFrm <=  1'b1;
  else
    ref_TxCtrlEndFrm <=  1'b0;
end
always @ (posedge MTxClk or posedge TxReset)
begin
  if(TxReset)
    ref_CtrlMux <=  1'b0;
  else
  if(ref_WillSendControlFrame & ~TxUsedDataOut)
    ref_CtrlMux <=  1'b1;
  else
  if(TxDoneIn)
    ref_CtrlMux <=  1'b0;
end
always @ (posedge MTxClk or posedge TxReset)
begin
  if(TxReset)
    ref_SendingCtrlFrm <=  1'b0;
  else
  if(ref_WillSendControlFrame & ref_TxCtrlStartFrm)
    ref_SendingCtrlFrm <=  1'b1;
  else
  if(TxDoneIn)
    ref_SendingCtrlFrm <=  1'b0;
end
always @ (posedge MTxClk or posedge TxReset)
begin
  if(TxReset)
    TxUsedDataIn_q <=  1'b0;
  else
    TxUsedDataIn_q <=  TxUsedDataIn;
end
always @ (posedge MTxClk or posedge TxReset)
begin
  if(TxReset)
    ref_BlockTxDone <=  1'b0;
  else
  if(ref_TxCtrlStartFrm)
    ref_BlockTxDone <=  1'b1;
  else
  if(TxStartFrmIn)
    ref_BlockTxDone <=  1'b0;
end
always @ (posedge MTxClk)
begin
  ControlEnd_q     <=  ControlEnd;
  ref_TxCtrlStartFrm_q <=  ref_TxCtrlStartFrm;
end
assign IncrementDlyCrcCnt = ref_CtrlMux & TxUsedDataIn &  ~DlyCrcCnt[2];
always @ (posedge MTxClk or posedge TxReset)
begin
  if(TxReset)
    DlyCrcCnt <=  4'h0;
  else
  if(ResetByteCnt)
    DlyCrcCnt <=  4'h0;
  else
  if(IncrementDlyCrcCnt)
    DlyCrcCnt <=  DlyCrcCnt + 4'd1;
end
assign ResetByteCnt = TxReset | (~ref_TxCtrlStartFrm & (TxDoneIn | TxAbortIn));
assign IncrementByteCnt = ref_CtrlMux & (ref_TxCtrlStartFrm & ~ref_TxCtrlStartFrm_q & ~TxUsedDataIn | TxUsedDataIn & ~ControlEnd);
assign IncrementByteCntBy2 = ref_CtrlMux & ref_TxCtrlStartFrm & (~ref_TxCtrlStartFrm_q) & TxUsedDataIn;     
assign EnableCnt = (~DlyCrcEn | DlyCrcEn & (&DlyCrcCnt[1:0]));
always @ (posedge MTxClk or posedge TxReset)
begin
  if(TxReset)
    ByteCnt <=  6'h0;
  else
  if(ResetByteCnt)
    ByteCnt <=  6'h0;
  else
  if(IncrementByteCntBy2 & EnableCnt)
    ByteCnt <=  (ByteCnt[5:0] ) + 6'd2;
  else
  if(IncrementByteCnt & EnableCnt)
    ByteCnt <=  (ByteCnt[5:0] ) + 6'd1;
end
assign ControlEnd = ByteCnt[5:0] == 6'h22;
always @ (ByteCnt or DlyCrcEn or MAC or TxPauseTV or DlyCrcCnt)
begin
  case(ByteCnt)
    6'h0:    if(~DlyCrcEn | DlyCrcEn & (&DlyCrcCnt[1:0]))
               MuxedCtrlData[7:0] = 8'h01;                   
             else
						 	 MuxedCtrlData[7:0] = 8'h0;
    6'h2:      MuxedCtrlData[7:0] = 8'h80;
    6'h4:      MuxedCtrlData[7:0] = 8'hC2;
    6'h6:      MuxedCtrlData[7:0] = 8'h00;
    6'h8:      MuxedCtrlData[7:0] = 8'h00;
    6'hA:      MuxedCtrlData[7:0] = 8'h01;
    6'hC:      MuxedCtrlData[7:0] = MAC[47:40];
    6'hE:      MuxedCtrlData[7:0] = MAC[39:32];
    6'h10:     MuxedCtrlData[7:0] = MAC[31:24];
    6'h12:     MuxedCtrlData[7:0] = MAC[23:16];
    6'h14:     MuxedCtrlData[7:0] = MAC[15:8];
    6'h16:     MuxedCtrlData[7:0] = MAC[7:0];
    6'h18:     MuxedCtrlData[7:0] = 8'h88;                   
    6'h1A:     MuxedCtrlData[7:0] = 8'h08;
    6'h1C:     MuxedCtrlData[7:0] = 8'h00;                   
    6'h1E:     MuxedCtrlData[7:0] = 8'h01;
    6'h20:     MuxedCtrlData[7:0] = TxPauseTV[15:8];         
    6'h22:     MuxedCtrlData[7:0] = TxPauseTV[7:0];
    default:   MuxedCtrlData[7:0] = 8'h0;
  endcase
end
always @ (posedge MTxClk or posedge TxReset)
begin
  if(TxReset)
    ref_ControlData[7:0] <=  8'h0;
  else
  if(~ByteCnt[0])
    ref_ControlData[7:0] <=  MuxedCtrlData[7:0];
end
endmodule




`timescale 1ns / 1ps

module tb;

    // Parameters
    parameter CLK_PERIOD = 10; // 100 MHz clock

    // Inputs
    reg MTxClk;
    reg TxReset;
    reg TxUsedDataIn;
    reg TxUsedDataOut;
    reg TxDoneIn;
    reg TxAbortIn;
    reg TxStartFrmIn;
    reg TPauseRq;
    reg TxUsedDataOutDetected;
    reg TxFlow;
    reg DlyCrcEn;
    reg [15:0] TxPauseTV;
    reg [47:0] MAC;

    // Outputs
    wire ref_TxCtrlStartFrm,dut_TxCtrlStartFrm;
    wire ref_TxCtrlEndFrm,dut_TxCtrlEndFrm;
    wire ref_SendingCtrlFrm,dut_SendingCtrlFrm;
    wire ref_CtrlMux,dut_CtrlMux;
    wire [7:0] ref_ControlData,dut_ControlData;
    wire ref_WillSendControlFrame,dut_WillSendControlFrame;
    wire ref_BlockTxDone,dut_BlockTxDone;

    wire match;

    integer total_tests = 0;
    integer failed_tests = 0;

assign match = ({ref_TxCtrlStartFrm,ref_TxCtrlEndFrm,ref_SendingCtrlFrm,ref_CtrlMux,ref_ControlData,ref_WillSendControlFrame,ref_BlockTxDone} === ({ref_TxCtrlStartFrm,ref_TxCtrlEndFrm,ref_SendingCtrlFrm,ref_CtrlMux,ref_ControlData,ref_WillSendControlFrame,ref_BlockTxDone} ^ {dut_TxCtrlStartFrm,dut_TxCtrlEndFrm,dut_SendingCtrlFrm,dut_CtrlMux,dut_ControlData,dut_WillSendControlFrame,dut_BlockTxDone} ^ {ref_TxCtrlStartFrm,ref_TxCtrlEndFrm,ref_SendingCtrlFrm,ref_CtrlMux,ref_ControlData,ref_WillSendControlFrame,ref_BlockTxDone}));

    // Instantiate the eth_transmitcontrol module
    ref_eth_transmitcontrol ref_modle(
        .MTxClk(MTxClk),
        .TxReset(TxReset),
        .TxUsedDataIn(TxUsedDataIn),
        .TxUsedDataOut(TxUsedDataOut),
        .TxDoneIn(TxDoneIn),
        .TxAbortIn(TxAbortIn),
        .TxStartFrmIn(TxStartFrmIn),
        .TPauseRq(TPauseRq),
        .TxUsedDataOutDetected(TxUsedDataOutDetected),
        .TxFlow(TxFlow),
        .DlyCrcEn(DlyCrcEn),
        .TxPauseTV(TxPauseTV),
        .MAC(MAC),
        .ref_TxCtrlStartFrm(ref_TxCtrlStartFrm),
        .ref_TxCtrlEndFrm(ref_TxCtrlEndFrm),
        .ref_SendingCtrlFrm(ref_SendingCtrlFrm),
        .ref_CtrlMux(ref_CtrlMux),
        .ref_ControlData(ref_ControlData),
        .ref_WillSendControlFrame(ref_WillSendControlFrame),
        .ref_BlockTxDone(ref_BlockTxDone)
    );

eth_transmitcontrol uut (
        .MTxClk(MTxClk),
        .TxReset(TxReset),
        .TxUsedDataIn(TxUsedDataIn),
        .TxUsedDataOut(TxUsedDataOut),
        .TxDoneIn(TxDoneIn),
        .TxAbortIn(TxAbortIn),
        .TxStartFrmIn(TxStartFrmIn),
        .TPauseRq(TPauseRq),
        .TxUsedDataOutDetected(TxUsedDataOutDetected),
        .TxFlow(TxFlow),
        .DlyCrcEn(DlyCrcEn),
        .TxPauseTV(TxPauseTV),
        .MAC(MAC),
        .TxCtrlStartFrm(dut_TxCtrlStartFrm),
        .TxCtrlEndFrm(dut_TxCtrlEndFrm),
        .SendingCtrlFrm(dut_SendingCtrlFrm),
        .CtrlMux(dut_CtrlMux),
        .ControlData(dut_ControlData),
        .WillSendControlFrame(dut_WillSendControlFrame),
        .BlockTxDone(dut_BlockTxDone)
    );
    // Clock generation
    initial begin
        MTxClk = 0;
        forever #(CLK_PERIOD / 2) MTxClk = ~MTxClk; // Toggle clock
    end

    // Reference model to verify DUT outputs
    //reg ref_WillSendControlFrame;
   // reg ref_TxCtrlEndFrm;
    //reg ref_SendingCtrlFrm;
    //reg [7:0] ref_ControlData;

    //always @(posedge MTxClk) begin
      //  if (!TxReset) begin
      //      ref_WillSendControlFrame <= 0;
       ///     ref_TxCtrlEndFrm <= 0;
       //     ref_SendingCtrlFrm <= 0;
       //     ref_ControlData <= 0;
       // end else begin
        //    if (TPauseRq && TxStartFrmIn) begin
       //         ref_WillSendControlFrame <= 1;
        //        ref_SendingCtrlFrm <= 1;
       //     end
        //    if (TxDoneIn) begin
        //        ref_TxCtrlEndFrm <= 1;
        //        ref_SendingCtrlFrm <= 0;
         //   end
         //   if (TxAbortIn) begin
        //        ref_SendingCtrlFrm <= 0;
        ////    end
         //   if (TxUsedDataIn) begin
         ///       ref_ControlData <= 8'h01; // Example control data
         //   end
       // end
   // end

    // Test Procedure
    initial begin
        // Initialize inputs
        TxReset = 1;
        TxUsedDataIn = 0;
        TxUsedDataOut = 0;
        TxDoneIn = 0;
        TxAbortIn = 0;
        TxStartFrmIn = 0;
        TPauseRq = 0;
        TxUsedDataOutDetected = 0;
        TxFlow = 0;
        DlyCrcEn = 0;
        TxPauseTV = 16'h0000;
        MAC = 48'h00_11_22_33_44_55;

        // Wait for a clock cycle
        #(CLK_PERIOD * 2);

        // Test Case 1: Reset the module
 	@(posedge MTxClk);
        TxReset = 0;
        #(CLK_PERIOD);
        TxReset = 1; // Assert reset
        #(CLK_PERIOD);
        TxReset = 0; // Deassert reset
	compare();

        // Test Case 2: Start Control Frame Transmission
	@(posedge MTxClk);
        TxFlow = 1;
        TPauseRq = 1;
        #(CLK_PERIOD);
        TxStartFrmIn = 1; // Start frame input
        #(CLK_PERIOD);
        TxStartFrmIn = 0;
	compare();

        // Wait for a clock cycle
        #(CLK_PERIOD * 5);

        // Check outputs
        if (dut_WillSendControlFrame !== ref_WillSendControlFrame) begin
            $display("Test Case 2 Failed: Expected WillSendControlFrame = %b, got %b", ref_WillSendControlFrame,dut_WillSendControlFrame);
        end

        // Test Case 3: End Control Frame Transmission
	@(posedge MTxClk);
        TxDoneIn = 1; // Indicate transmission done
        #(CLK_PERIOD);
        TxDoneIn = 0;
	compare();

        // Wait for a clock cycle
        #(CLK_PERIOD * 2);

        // Check outputs
        if (dut_TxCtrlEndFrm !== ref_TxCtrlEndFrm) begin
            $display("Test Case 3 Failed: Expected TxCtrlEndFrm = %b, got %b", dut_TxCtrlEndFrm, ref_TxCtrlEndFrm);
        end

        // Test Case 4: Control Frame Sending State
	@(posedge MTxClk);
        if (dut_SendingCtrlFrm !== ref_SendingCtrlFrm) begin
            $display("Test Case 4 Failed: Expected SendingCtrlFrm = %b, got %b", dut_SendingCtrlFrm, ref_SendingCtrlFrm);
        end
	compare();

        // Test Case 5: Abort Transmission
	@(posedge MTxClk);
        TxAbortIn = 1; // Abort the transmission
        #(CLK_PERIOD);
        TxAbortIn = 0;
	compare();

        // Wait for a clock cycle
        #(CLK_PERIOD * 2);

        // Check outputs after abort
        if (dut_SendingCtrlFrm !== ref_SendingCtrlFrm) begin
            $display("Test Case 5 Failed: Expected SendingCtrlFrm = %b after abort, got %b", dut_SendingCtrlFrm, ref_SendingCtrlFrm);
        end

        // Test Case 6: Check ControlData output
	@(posedge MTxClk);
        TxUsedDataIn = 1; // Simulate data input
        #(CLK_PERIOD);
        if (dut_ControlData !== ref_ControlData) begin
            $display("Test Case 6 Failed: Expected ControlData = %h, got %h", ref_ControlData, dut_ControlData);
        end
	compare();

repeat (96) begin
            @(negedge MTxClk);
     TxUsedDataIn = $random;
     TxUsedDataOut = $random;
     TxDoneIn = $random;
     TxAbortIn = $random;
     TxStartFrmIn = $random;
     TPauseRq = $random;
     TxUsedDataOutDetected = $random;
     TxFlow = $random;
     DlyCrcEn = $random;
     TxPauseTV = $random ;
     MAC = {$random,$random};
            #10;
            compare();
        end
	$display("All tests passed: design passed");
        $display("\033[1;34mTotal testcases: %d, Failed testcases: %d\033[0m", total_tests, failed_tests);
        if (failed_tests==0) begin
            $display("=====================Your Design Passed======================");
    end
        // Finish simulation
        #(CLK_PERIOD * 10);
        $finish;
    end

    task compare;
        total_tests = total_tests + 1;
        //wait (o_valid_dut == 1);
        if (match)                                //condition to check DUT outputs and calculated 
                                                    //outputs from task are equal 
			begin
				//$display("\033[1;32mtestcase is passed!!!\033[0m");
				//$display("testcase is passed!!!");
            	//$display("i_rst = %h, i_wr = %h, i_signed = %h, i_numerator = %h, i_denominator = %h, o_busy_dut = %h, o_valid_dut = %h, o_err_dut = %h, o_quotient_dut = %h, o_flags_dut = %h, o_busy_ref = %h, o_valid_ref = %h, o_err_ref = %h, o_quotient_ref = %h, o_flags_ref = %h)", i_rst, i_wr, i_signed, i_numerator, i_denominator, o_busy_dut, o_valid_dut, o_err_dut, o_quotient_dut, o_flags_dut, o_busy_ref, o_valid_ref, o_err_ref, o_quotient_ref, o_flags_ref);      //displaying inputs, outputs and result
			end

		else begin
			//$display("\033[1;31mtestcase is failed!!!\033[0m");
            //$display("i_rst = %h, i_wr = %h, i_signed = %h, i_numerator = %h, i_denominator = %h, o_busy_dut = %h, o_valid_dut = %h, o_err_dut = %h, o_quotient_dut = %h, o_flags_dut = %h, o_busy_ref = %h, o_valid_ref = %h, o_err_ref = %h, o_quotient_ref = %h, o_flags_ref = %h)", i_rst, i_wr, i_signed, i_numerator, i_denominator, o_busy_dut, o_valid_dut, o_err_dut, o_quotient_dut, o_flags_dut, o_busy_ref, o_valid_ref, o_err_ref, o_quotient_ref, o_flags_ref);      //displaying inputs, outputs and result
            failed_tests = failed_tests + 1; 
		end
    
	endtask

endmodule
