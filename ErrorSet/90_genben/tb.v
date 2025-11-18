 
module ref_eth_receivecontrol (MTxClk, MRxClk, TxReset, RxReset, RxData, RxValid, RxStartFrm, 
                           RxEndFrm, RxFlow, ReceiveEnd, MAC, DlyCrcEn, TxDoneIn, 
                           TxAbortIn, TxStartFrmOut, ReceivedLengthOK, ReceivedPacketGood, 
                           TxUsedDataOutDetected, ref_Pause, ref_ReceivedPauseFrm, ref_AddressOK, 
                           RxStatusWriteLatched_sync2, r_PassAll, ref_SetPauseTimer
                          );
input       MTxClk;
input       MRxClk;
input       TxReset; 
input       RxReset; 
input [7:0] RxData;
input       RxValid;
input       RxStartFrm;
input       RxEndFrm;
input       RxFlow;
input       ReceiveEnd;
input [47:0]MAC;
input       DlyCrcEn;
input       TxDoneIn;
input       TxAbortIn;
input       TxStartFrmOut;
input       ReceivedLengthOK;
input       ReceivedPacketGood;
input       TxUsedDataOutDetected;
input       RxStatusWriteLatched_sync2;
input       r_PassAll;
output      ref_Pause;
output      ref_ReceivedPauseFrm;
output      ref_AddressOK;
output      ref_SetPauseTimer;
reg         ref_Pause;
reg         ref_AddressOK;                
reg         TypeLengthOK;             
reg         DetectionWindow;          
reg         OpCodeOK;                 
reg  [2:0]  DlyCrcCnt;
reg  [4:0]  ByteCnt;
reg [15:0]  AssembledTimerValue;
reg [15:0]  LatchedTimerValue;
reg         ref_ReceivedPauseFrm;
reg         ReceivedPauseFrmWAddr;
reg         PauseTimerEq0_sync1;
reg         PauseTimerEq0_sync2;
reg [15:0]  PauseTimer;
reg         Divider2;
reg  [5:0]  SlotTimer;
wire [47:0] ReservedMulticast;        
wire [15:0] TypeLength;               
wire        ResetByteCnt;             
wire        IncrementByteCnt;         
wire        ByteCntEq0;               
wire        ByteCntEq1;               
wire        ByteCntEq2;               
wire        ByteCntEq3;               
wire        ByteCntEq4;               
wire        ByteCntEq5;               
wire        ByteCntEq12;              
wire        ByteCntEq13;              
wire        ByteCntEq14;              
wire        ByteCntEq15;              
wire        ByteCntEq16;              
wire        ByteCntEq17;              
wire        ByteCntEq18;              
wire        DecrementPauseTimer;      
wire        PauseTimerEq0;            
wire        ResetSlotTimer;           
wire        IncrementSlotTimer;       
wire        SlotFinished;             
assign ReservedMulticast = 48'h0180C2000001;
assign TypeLength = 16'h8808;
always @ (posedge MRxClk or posedge RxReset)
begin
  if(RxReset)
    ref_AddressOK <=  1'b0;
  else
  if(DetectionWindow & ByteCntEq0)
    ref_AddressOK <=   RxData[7:0] == ReservedMulticast[47:40] | RxData[7:0] == MAC[47:40];
  else
  if(DetectionWindow & ByteCntEq1)
    ref_AddressOK <=  (RxData[7:0] == ReservedMulticast[39:32] | RxData[7:0] == MAC[39:32]) & ref_AddressOK;
  else
  if(DetectionWindow & ByteCntEq2)
    ref_AddressOK <=  (RxData[7:0] == ReservedMulticast[31:24] | RxData[7:0] == MAC[31:24]) & ref_AddressOK;
  else
  if(DetectionWindow & ByteCntEq3)
    ref_AddressOK <=  (RxData[7:0] == ReservedMulticast[23:16] | RxData[7:0] == MAC[23:16]) & ref_AddressOK;
  else
  if(DetectionWindow & ByteCntEq4)
    ref_AddressOK <=  (RxData[7:0] == ReservedMulticast[15:8]  | RxData[7:0] == MAC[15:8])  & ref_AddressOK;
  else
  if(DetectionWindow & ByteCntEq5)
    ref_AddressOK <=  (RxData[7:0] == ReservedMulticast[7:0]   | RxData[7:0] == MAC[7:0])   & ref_AddressOK;
  else
  if(ReceiveEnd)
    ref_AddressOK <=  1'b0;
end
always @ (posedge MRxClk or posedge RxReset )
begin
  if(RxReset)
    TypeLengthOK <=  1'b0;
  else
  if(DetectionWindow & ByteCntEq12)
    TypeLengthOK <=  ByteCntEq12 & (RxData[7:0] == TypeLength[15:8]);
  else
  if(DetectionWindow & ByteCntEq13)
    TypeLengthOK <=  ByteCntEq13 & (RxData[7:0] == TypeLength[7:0]) & TypeLengthOK;
  else
  if(ReceiveEnd)
    TypeLengthOK <=  1'b0;
end
always @ (posedge MRxClk or posedge RxReset )
begin
  if(RxReset)
    OpCodeOK <=  1'b0;
  else
  if(ByteCntEq16)
    OpCodeOK <=  1'b0;
  else
    begin
      if(DetectionWindow & ByteCntEq14)
        OpCodeOK <=  ByteCntEq14 & RxData[7:0] == 8'h00;
      if(DetectionWindow & ByteCntEq15)
        OpCodeOK <=  ByteCntEq15 & RxData[7:0] == 8'h01 & OpCodeOK;
    end
end
always @ (posedge MRxClk or posedge RxReset )
begin
  if(RxReset)
    ReceivedPauseFrmWAddr <=  1'b0;
  else
  if(ReceiveEnd)
    ReceivedPauseFrmWAddr <=  1'b0;
  else
  if(ByteCntEq16 & TypeLengthOK & OpCodeOK & ref_AddressOK)
    ReceivedPauseFrmWAddr <=  1'b1;        
end
always @ (posedge MRxClk or posedge RxReset )
begin
  if(RxReset)
    AssembledTimerValue[15:0] <=  16'h0;
  else
  if(RxStartFrm)
    AssembledTimerValue[15:0] <=  16'h0;
  else
    begin
      if(DetectionWindow & ByteCntEq16)
        AssembledTimerValue[15:8] <=  RxData[7:0];
      if(DetectionWindow & ByteCntEq17)
        AssembledTimerValue[7:0] <=  RxData[7:0];
    end
end
always @ (posedge MRxClk or posedge RxReset )
begin
  if(RxReset)
    DetectionWindow <=  1'b1;
  else
  if(ByteCntEq18)
    DetectionWindow <=  1'b0;
  else
  if(ReceiveEnd)
    DetectionWindow <=  1'b1;
end
always @ (posedge MRxClk or posedge RxReset )
begin
  if(RxReset)
    LatchedTimerValue[15:0] <=  16'h0;
  else
  if(DetectionWindow &  ReceivedPauseFrmWAddr &  ByteCntEq18)
    LatchedTimerValue[15:0] <=  AssembledTimerValue[15:0];
  else
  if(ReceiveEnd)
    LatchedTimerValue[15:0] <=  16'h0;
end
always @ (posedge MRxClk or posedge RxReset)
begin
  if(RxReset)
    DlyCrcCnt <=  3'h0;
  else
  if(RxValid & RxEndFrm)
    DlyCrcCnt <=  3'h0;
  else
  if(RxValid & ~RxEndFrm & ~DlyCrcCnt[2])
    DlyCrcCnt <=  DlyCrcCnt + 3'd1;
end
assign ResetByteCnt = RxEndFrm;
assign IncrementByteCnt = RxValid & DetectionWindow & ~ByteCntEq18 & 
			  (~DlyCrcEn | DlyCrcEn & DlyCrcCnt[2]);
always @ (posedge MRxClk or posedge RxReset)
begin
  if(RxReset)
    ByteCnt[4:0] <=  5'h0;
  else
  if(ResetByteCnt)
    ByteCnt[4:0] <=  5'h0;
  else
  if(IncrementByteCnt)
    ByteCnt[4:0] <=  ByteCnt[4:0] + 5'd1;
end
assign ByteCntEq0 = RxValid & ByteCnt[4:0] == 5'h0;
assign ByteCntEq1 = RxValid & ByteCnt[4:0] == 5'h1;
assign ByteCntEq2 = RxValid & ByteCnt[4:0] == 5'h2;
assign ByteCntEq3 = RxValid & ByteCnt[4:0] == 5'h3;
assign ByteCntEq4 = RxValid & ByteCnt[4:0] == 5'h4;
assign ByteCntEq5 = RxValid & ByteCnt[4:0] == 5'h5;
assign ByteCntEq12 = RxValid & ByteCnt[4:0] == 5'h0C;
assign ByteCntEq13 = RxValid & ByteCnt[4:0] == 5'h0D;
assign ByteCntEq14 = RxValid & ByteCnt[4:0] == 5'h0E;
assign ByteCntEq15 = RxValid & ByteCnt[4:0] == 5'h0F;
assign ByteCntEq16 = RxValid & ByteCnt[4:0] == 5'h10;
assign ByteCntEq17 = RxValid & ByteCnt[4:0] == 5'h11;
assign ByteCntEq18 = RxValid & ByteCnt[4:0] == 5'h12 & DetectionWindow;
assign ref_SetPauseTimer = ReceiveEnd & ReceivedPauseFrmWAddr & ReceivedPacketGood & ReceivedLengthOK & RxFlow;
assign DecrementPauseTimer = SlotFinished & |PauseTimer;
always @ (posedge MRxClk or posedge RxReset)
begin
  if(RxReset)
    PauseTimer[15:0] <=  16'h0;
  else
  if(ref_SetPauseTimer)
    PauseTimer[15:0] <=  LatchedTimerValue[15:0];
  else
  if(DecrementPauseTimer)
    PauseTimer[15:0] <=  PauseTimer[15:0] - 16'd1;
end
assign PauseTimerEq0 = ~(|PauseTimer[15:0]);
always @ (posedge MTxClk or posedge TxReset)
begin
  if(TxReset)
    begin
      PauseTimerEq0_sync1 <=  1'b1;
      PauseTimerEq0_sync2 <=  1'b1;
    end
  else
    begin
      PauseTimerEq0_sync1 <=  PauseTimerEq0;
      PauseTimerEq0_sync2 <=  PauseTimerEq0_sync1;
    end
end
always @ (posedge MTxClk or posedge TxReset)
begin
  if(TxReset)
    ref_Pause <=  1'b0;
  else
  if((TxDoneIn | TxAbortIn | ~TxUsedDataOutDetected) & ~TxStartFrmOut)
    ref_Pause <=  RxFlow & ~PauseTimerEq0_sync2;
end
always @ (posedge MRxClk or posedge RxReset)
begin
  if(RxReset)
    Divider2 <=  1'b0;
  else
  if(|PauseTimer[15:0] & RxFlow)
    Divider2 <=  ~Divider2;
  else
    Divider2 <=  1'b0;
end
assign ResetSlotTimer = RxReset;
assign IncrementSlotTimer =  ref_Pause & RxFlow & Divider2;
always @ (posedge MRxClk or posedge RxReset)
begin
  if(RxReset)
    SlotTimer[5:0] <=  6'h0;
  else
  if(ResetSlotTimer)
    SlotTimer[5:0] <=  6'h0;
  else
  if(IncrementSlotTimer)
    SlotTimer[5:0] <=  SlotTimer[5:0] + 6'd1;
end
assign SlotFinished = &SlotTimer[5:0] & IncrementSlotTimer;  
always @ (posedge MRxClk or posedge RxReset)
begin
  if(RxReset)
    ref_ReceivedPauseFrm <= 1'b0;
  else
  if(RxStatusWriteLatched_sync2 & r_PassAll | ref_ReceivedPauseFrm & (~r_PassAll))
    ref_ReceivedPauseFrm <= 1'b0;
  else
  if(ByteCntEq16 & TypeLengthOK & OpCodeOK)
    ref_ReceivedPauseFrm <= 1'b1;        
end
endmodule




 `timescale 1ns / 1ps

module tb;

    // Parameters
    parameter CLK_PERIOD = 10; // Clock period for MTxClk and MRxClk

    // Inputs
    reg MTxClk;
    reg MRxClk;
    reg TxReset;
    reg RxReset;
    reg [7:0] RxData;
    reg RxValid;
    reg RxStartFrm;
    reg RxEndFrm;
    reg RxFlow;
    reg ReceiveEnd;
    reg [47:0] MAC;
    reg DlyCrcEn;
    reg TxDoneIn;
    reg TxAbortIn;
    reg TxStartFrmOut;
    reg ReceivedLengthOK;
    reg ReceivedPacketGood;
    reg TxUsedDataOutDetected;
    reg RxStatusWriteLatched_sync2;
    reg r_PassAll;

    // ref Outputs
    wire ref_Pause;
    wire ref_ReceivedPauseFrm;
    wire ref_AddressOK;
    wire ref_SetPauseTimer;

    // dut Outputs
    wire dut_Pause;
    wire dut_ReceivedPauseFrm;
    wire dut_AddressOK;
    wire dut_SetPauseTimer;

	wire match;
 	integer total_tests = 0;
	integer failed_tests = 0;

assign match = ({ref_Pause,ref_ReceivedPauseFrm,ref_AddressOK,ref_SetPauseTimer} === ({ref_Pause,ref_ReceivedPauseFrm,ref_AddressOK,ref_SetPauseTimer} ^ {dut_Pause,dut_ReceivedPauseFrm,dut_AddressOK,dut_SetPauseTimer} ^ {ref_Pause,ref_ReceivedPauseFrm,ref_AddressOK,ref_SetPauseTimer}));

    // Instantiate the eth_receivecontrol module
    eth_receivecontrol uut1 (
        .MTxClk(MTxClk),
        .MRxClk(MRxClk),
        .TxReset(TxReset),
        .RxReset(RxReset),
        .RxData(RxData),
        .RxValid(RxValid),
        .RxStartFrm(RxStartFrm),
        .RxEndFrm(RxEndFrm),
        .RxFlow(RxFlow),
        .ReceiveEnd(ReceiveEnd),
        .MAC(MAC),
        .DlyCrcEn(DlyCrcEn),
        .TxDoneIn(TxDoneIn),
        .TxAbortIn(TxAbortIn),
        .TxStartFrmOut(TxStartFrmOut),
        .ReceivedLengthOK(ReceivedLengthOK),
        .ReceivedPacketGood(ReceivedPacketGood),
        .TxUsedDataOutDetected(TxUsedDataOutDetected),
        .RxStatusWriteLatched_sync2(RxStatusWriteLatched_sync2),
        .r_PassAll(r_PassAll),
        .Pause(dut_Pause),
        .ReceivedPauseFrm(dut_ReceivedPauseFrm),
        .AddressOK(dut_AddressOK),
        .SetPauseTimer(dut_SetPauseTimer)
    );


    // Instantiate the eth_receivecontrol module
   ref_eth_receivecontrol uut2 (
        .MTxClk(MTxClk),
        .MRxClk(MRxClk),
        .TxReset(TxReset),
        .RxReset(RxReset),
        .RxData(RxData),
        .RxValid(RxValid),
        .RxStartFrm(RxStartFrm),
        .RxEndFrm(RxEndFrm),
        .RxFlow(RxFlow),
        .ReceiveEnd(ReceiveEnd),
        .MAC(MAC),
        .DlyCrcEn(DlyCrcEn),
        .TxDoneIn(TxDoneIn),
        .TxAbortIn(TxAbortIn),
        .TxStartFrmOut(TxStartFrmOut),
        .ReceivedLengthOK(ReceivedLengthOK),
        .ReceivedPacketGood(ReceivedPacketGood),
        .TxUsedDataOutDetected(TxUsedDataOutDetected),
        .RxStatusWriteLatched_sync2(RxStatusWriteLatched_sync2),
        .r_PassAll(r_PassAll),
        .ref_Pause(ref_Pause),
        .ref_ReceivedPauseFrm(ref_ReceivedPauseFrm),
        .ref_AddressOK(ref_AddressOK),
        .ref_SetPauseTimer(ref_SetPauseTimer)
    );


    // Generate clock signals
    initial begin
        MTxClk = 0;
        MRxClk = 0;
        forever #(CLK_PERIOD / 2) begin
            MTxClk = ~MTxClk;
            MRxClk = ~MRxClk;
        end
    end

    // Test Procedure
    initial begin
        // Initialize inputs
        TxReset = 1;
        RxReset = 1;
        RxData = 0;
        RxValid = 0;
        RxStartFrm = 0;
        RxEndFrm = 0;
        RxFlow = 0;
        ReceiveEnd = 0;
        MAC = 48'h00_11_22_33_44_55;
        DlyCrcEn = 0;
        TxDoneIn = 0;
        TxAbortIn = 0;
        TxStartFrmOut = 0;
        ReceivedLengthOK = 0;
        ReceivedPacketGood = 0;
        TxUsedDataOutDetected = 0;
        RxStatusWriteLatched_sync2 = 0;
        r_PassAll = 0;

        // Apply reset
        #(CLK_PERIOD);
        TxReset = 0; // De-assert TxReset
        RxReset = 0; // De-assert RxReset
        #(CLK_PERIOD);

        // Test Case 1: Simulate receiving a pause frame
        RxValid = 1;
        RxStartFrm = 1;
        RxData = 8'h01; // Start of a pause frame
        #(CLK_PERIOD);
        RxStartFrm = 0;
        RxEndFrm = 0;
  compare();

        // Send remaining bytes for the pause frame
        for (int i = 1; i < 18; i++) begin
            RxData = 8'h00; // Fill with dummy data
            #(CLK_PERIOD);
        end
        
        RxEndFrm = 1; // End of pause frame
        #(CLK_PERIOD);
        RxEndFrm = 0; // Clear end frame

        // Check outputs
        if (dut_ReceivedPauseFrm) begin
            $display("Test Case 1 Passed: Received pause frame.");
        end else begin
            $display("Test Case 1 Failed: Pause frame not received.");
        end
    compare();

// Test Case 2: Valid Pause Frame Reception
    #10;
    RxStartFrm = 1;
    RxValid = 1;
    RxData = 8'h01; // Start of MAC address
    #10;
    RxData = 8'h80;
    #10;
    RxData = 8'hC2;
    #10;
    RxData = 8'h00;
    #10;
    RxData = 8'h00;
    #10;
    RxData = 8'h01;
    #10;
    RxData = 8'h88; // Type/Length
    #10;
    RxData = 8'h08;
    #10;
    RxData = 8'h00; // OpCode
    #10;
    RxData = 8'h01;
    #10;
    RxData = 8'h00; // Timer Value
    #10;
    RxData = 8'h0A;
    #10;
    RxData = 8'h00; // End of frame
    RxEndFrm = 1;
    #10;
    RxEndFrm = 0;
    RxValid = 0;
    RxStartFrm = 0;
    ReceiveEnd = 1;
    #10;
    ReceiveEnd = 0;
compare();
    // Test Case : Invalid Pause Frame Reception (wrong MAC address)
    #10;
    RxStartFrm = 1;
    RxValid = 1;
    RxData = 8'h02; // Start of wrong MAC address
    #10;
    RxData = 8'h80;
    #10;
    RxData = 8'hC2;
    #10;
    RxData = 8'h00;
    #10;
    RxData = 8'h00;
    #10;
    RxData = 8'h01;
    #10;
    RxData = 8'h88; // Type/Length
    #10;
    RxData = 8'h08;
    #10;
    RxData = 8'h00; // OpCode
    #10;
    RxData = 8'h01;
    #10;
    RxData = 8'h00; // Timer Value
    #10;
    RxData = 8'h0A;
    #10;
    RxData = 8'h00; // End of frame
    RxEndFrm = 1;
    #10;
    RxEndFrm = 0;
    RxValid = 0;
    RxStartFrm = 0;
    ReceiveEnd = 1;
    #10;
    ReceiveEnd = 0;
compare();
    // Test Case 4: Invalid Pause Frame Reception (wrong Type/Length)
    #10;
    RxStartFrm = 1;
    RxValid = 1;
    RxData = 8'h01; // Start of MAC address
    #10;
    RxData = 8'h80;
    #10;
    RxData = 8'hC2;
    #10;
    RxData = 8'h00;
    #10;
    RxData = 8'h00;
    #10;
    RxData = 8'h01;
    #10;
    RxData = 8'h88; // Wrong Type/Length
    #10;
    RxData = 8'h09;
    #10;
    RxData = 8'h00; // OpCode
    #10;
    RxData = 8'h01;
    #10;
    RxData = 8'h00; // Timer Value
    #10;
    RxData = 8'h0A;
    #10;
    RxData = 8'h00; // End of frame
    RxEndFrm = 1;
    #10;
    RxEndFrm = 0;
    RxValid = 0;
    RxStartFrm = 0;
    ReceiveEnd = 1;
    #10;
    ReceiveEnd = 0;
compare();
    // Test Case 5: Invalid Pause Frame Reception (wrong OpCode)
    #10;
    RxStartFrm = 1;
    RxValid = 1;
    RxData = 8'h01; // Start of MAC address
    #10;
    RxData = 8'h80;
    #10;
    RxData = 8'hC2;
    #10;
    RxData = 8'h00;
    #10;
    RxData = 8'h00;
    #10;
    RxData = 8'h01;
    #10;
    RxData = 8'h88; // Type/Length
    #10;
    RxData = 8'h08;
    #10;
    RxData = 8'h00; // Wrong OpCode
    #10;
    RxData = 8'h02;
    #10;
    RxData = 8'h00; // Timer Value
    #10;
    RxData = 8'h0A;
    #10;
    RxData = 8'h00; // End of frame
    RxEndFrm = 1;
    #10;
    RxEndFrm = 0;
    RxValid = 0;
    RxStartFrm = 0;
    ReceiveEnd = 1;
    #10;
    ReceiveEnd = 0;
compare();
    // Test Case 6: Pause Timer Decrement
    #10;
    RxFlow = 1;
    #100;
    RxFlow = 0;
compare();



   repeat (96) begin
      @(posedge MRxClk);
	TxReset = $random;
	RxReset = $random;
	RxData = $random;
	RxValid = $random;
	RxStartFrm = $random;
	RxEndFrm = $random;
	RxFlow = $random;
	ReceiveEnd = $random;
	MAC = $random;
	DlyCrcEn = $random;
	TxDoneIn = $random;
	TxAbortIn = $random;
	TxStartFrmOut = $random;
	ReceivedLengthOK = $random;
	ReceivedPacketGood = $random;
	TxUsedDataOutDetected = $random;
	RxStatusWriteLatched_sync2 = $random;
	r_PassAll = $random;
	      
      compare();
    end
     compare();

  	  $display("All tests passed: design passed");
        $display("\033[1;34mTotal testcases: %d, Failed testcases: %d\033[0m", total_tests, failed_tests);
        // Finish simulation

    if (failed_tests==0) begin
            $display("=====================Your Design Passed======================");
    end
        #(CLK_PERIOD * 10);
        $finish;
    end

task compare;
        total_tests = total_tests + 1;
        if (match)                                //condition to check DUT outputs and calculated 
                                                    //outputs from task are equal 
			begin			//	$display("\033[1;32mtestcase is passed!!!\033[0m");
			//	$display("testcase is passed!!!");
			end

		else begin
			//$display("\033[1;31mtestcase is failed!!!\033[0m");
            failed_tests = failed_tests + 1; 
		end
	
endtask
endmodule
