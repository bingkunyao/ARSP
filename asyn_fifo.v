//module name: asyn_fifo 
//An asynchronous FIFO, FIFO bit width and depth can be configured(parameter DEPTH = 16, parameter WIDTH = 8). The asynchronous FIFO structure is divided into several parts. The first part is dual-port RAM, which is used for data storage. Instantiate dual-port RAM as a submodule, The RAM ports are input wclk, input wenc, input [$clog2(DEPTH)-1:0] waddr, input [WIDTH-1:0] wdata, input rclk, input renc, input [$clog2(DEPTH)-1:0] raddr, output reg [WIDTH-1:0] rdata. The second part is the data write controller. The third part is the data read controller. The fourth part is the read pointer synchronizer. The read pointer is collected using the two-stage trigger of the write clock and output to the data write controller. The fifth part is the write pointer synchronizer, which uses the two-stage trigger of the read clock to collect the write pointer and output it to the data read controller.

//>>>Fragment 1: RAM module definition
module dual_port_RAM #(parameter DEPTH = 16,  parameter WIDTH = 8)
(
	 input wclk	,
	 input wenc	,
	 input [$clog2(DEPTH)-1:0] waddr  ,
	 input [WIDTH-1:0] wdata ,
	 input rclk	,
	 input renc	,
	 input [$clog2(DEPTH)-1:0] raddr ,
	 output reg [WIDTH-1:0] rdata 		
);

reg [WIDTH-1:0] RAM_MEM [0:DEPTH-1];

always @(posedge wclk) begin
	if(wenc)
		RAM_MEM[waddr] <= wdata;                 // bug 4: --> RAM_MEM[waddr] = wdata;
end 

always @(posedge rclk) begin
	if(renc)
		rdata <= RAM_MEM[raddr];                 // bug 4: --> rdata = RAM_MEM[raddr];
end 

endmodule  
//<<< End of the Fragment

//>>> Fragment 2: Asynchronous FIFO module declaration and parameter definitions
module verified_asyn_fifo#(
	parameter	WIDTH = 8,
	parameter 	DEPTH = 16
)(
	input 					wclk	, 
	input 					rclk	,   
	input 					wrstn	,
	input					rrstn	,
	input 					winc	,
	input 			 		rinc	,
	input 		[WIDTH-1:0]	wdata	,

	output wire				wfull	,
	output wire				rempty	,
	output wire [WIDTH-1:0]	rdata
);

parameter ADDR_WIDTH = $clog2(DEPTH);         // bug 2: --> parameter ADDR_WIDTH = $clog2(DEPTH);

reg 	[ADDR_WIDTH:0]	waddr_bin;
reg 	[ADDR_WIDTH:0]	raddr_bin;
//<<< End of the Fragment

// Fragment 3: Binary counters for write/read address 
always @(posedge wclk or negedge wrstn) begin // bug 1: --> always @(posedge wclk or posedge wrstn) begin
	if(~wrstn) begin
		waddr_bin <= 'd0;
	end 
	else if(!wfull && winc)begin
		waddr_bin <= waddr_bin + 1'd1;                                   // bug 5: --> waddr_bin <= 'd1;
	end
end
always @(posedge rclk or negedge rrstn) begin. // bug 1: --> always @(posedge rclk or posedge rrstn) begin
	if(~rrstn) begin
		raddr_bin <= 'd0;
	end 
	else if(!rempty && rinc)begin
		raddr_bin <= raddr_bin + 1'd1;
	end
end
// <<< End of the Fragment

// Fragment 4: Gray code conversion and pointer registers
wire 	[ADDR_WIDTH:0]	waddr_gray;
wire 	[ADDR_WIDTH:0]	raddr_gray;
reg 	[ADDR_WIDTH:0]	wptr;
reg 	[ADDR_WIDTH:0]	rptr;
assign waddr_gray = waddr_bin ^ (waddr_bin>>1);
assign raddr_gray = raddr_bin ^ (raddr_bin>>1);
always @(posedge wclk or negedge wrstn) begin 
	if(~wrstn) begin                            // bug 3: --> if(wrstn) begin
		wptr <= 'd0;
	end 
	else begin
		wptr <= waddr_gray;
	end
end
always @(posedge rclk or negedge rrstn) begin 
	if(~rrstn) begin                            // bug 3: --> if(rrstn) begin
		rptr <= 'd0;
	end 
	else begin
		rptr <= raddr_gray;
	end
end
// End of the Fragment

// Fragment 5: Cross-clock domain synchronizer
reg		[ADDR_WIDTH:0]	wptr_buff;
reg		[ADDR_WIDTH:0]	wptr_syn;
reg		[ADDR_WIDTH:0]	rptr_buff;
reg		[ADDR_WIDTH:0]	rptr_syn;
always @(posedge wclk or negedge wrstn) begin 
	if(~wrstn) begin
		rptr_buff <= 'd0;
		rptr_syn <= 'd0;
	end 
	else begin
		rptr_buff <= rptr;
		rptr_syn <= rptr_buff;
	end
end
always @(posedge rclk or negedge rrstn) begin 
	if(~rrstn) begin
		wptr_buff <= 'd0;
		wptr_syn <= 'd0;
	end 
	else begin
		wptr_buff <= wptr;
		wptr_syn <= wptr_buff;
	end
end
// End of the Fragment

// Fragment 6: Full and empty flag generation and RAM interface logic
assign wfull = (wptr == {~rptr_syn[ADDR_WIDTH:ADDR_WIDTH-1],rptr_syn[ADDR_WIDTH-2:0]});  // bug 6: --> assign wfull = (wptr = {~rptr_syn[ADDR_WIDTH:ADDR_WIDTH-1],rptr_syn[ADDR_WIDTH-2:0]});
assign rempty = (rptr == wptr_syn);

wire 	wen	;
wire	ren	;
wire 	wren;//high write
wire [ADDR_WIDTH-1:0]	waddr;
wire [ADDR_WIDTH-1:0]	raddr;
assign wen = winc & !wfull;
assign ren = rinc & !rempty;
assign waddr = waddr_bin[ADDR_WIDTH-1:0];
assign raddr = raddr_bin[ADDR_WIDTH-1:0];
// End of the Fragment

// Fragment 7: RAM instantiation
dual_port_RAM #(.DEPTH(DEPTH),
				.WIDTH(WIDTH)
)dual_port_RAM(
	.wclk (wclk),  
	.wenc (wen),  
	.waddr(waddr[ADDR_WIDTH-1:0]),  
	.wdata(wdata),       	//data_write
	.rclk (rclk), 
	.renc (ren), 
	.raddr(raddr[ADDR_WIDTH-1:0]),   
	.rdata(rdata)  		
);

endmodule
// <<< End of the Fragment
