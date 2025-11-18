//module name: i2c_master
//An I2C master controller module that provides register access through a Wishbone bus interface, internally containing clock prescaling, command control, status monitoring, and interrupt handling functions, and instantiates a byte controller to implement specific I2C protocol timing control.

// >>> Chunk 1: Module declaration and interface definition
`include "timescale.v"

`include "i2c_master_defines.v"

module i2c_master_top(
	wb_clk_i, wb_rst_i, arst_i, wb_adr_i, wb_dat_i, wb_dat_o,
	wb_we_i, wb_stb_i, wb_cyc_i, wb_ack_o, wb_inta_o,
	scl_pad_i, scl_pad_o, scl_padoen_o, sda_pad_i, sda_pad_o, sda_padoen_o );

	parameter ARST_LVL = 1'b0; // asynchronous reset level
	input        wb_clk_i;     // master clock input
	input        wb_rst_i;     // synchronous active high reset
	input        arst_i;       // asynchronous reset
	input  [2:0] wb_adr_i;     // lower address bits
	input  [7:0] wb_dat_i;     // databus input
	output [7:0] wb_dat_o;     // databus output
	input        wb_we_i;      // write enable input
	input        wb_stb_i;     // stobe/core select signal
	input        wb_cyc_i;     // valid bus cycle input
	output       wb_ack_o;     // bus cycle acknowledge output
	output       wb_inta_o;    // interrupt request signal output

	reg [7:0] wb_dat_o;
	reg wb_ack_o;
	reg wb_inta_o;

	// I2C signals
	// i2c clock line
	input  scl_pad_i;       // SCL-line input
	output scl_pad_o;       // SCL-line output (always 1'b0)
	output scl_padoen_o;    // SCL-line output enable (active low)

	// i2c data line
	input  sda_pad_i;       // SDA-line input
	output sda_pad_o;       // SDA-line output (always 1'b0)
	output sda_padoen_o;    // SDA-line output enable (active low)
//<<<End of the Chunk

// >>> Chunk 2: Internal variable and signal declaration

	// registers
	reg  [15:0] prer; // clock prescale register
	reg  [ 7:0] ctr;  // control register
	reg  [ 7:0] txr;  // transmit register
	wire [ 7:0] rxr;  // receive register
	reg  [ 7:0] cr;   // command register
	wire [ 7:0] sr;   // status register

	// done signal: command completed, clear command register
	wire done;

	// core enable signal
	wire core_en;
	wire ien;

	// status register signals
	wire irxack;
	reg  rxack;       // received aknowledge from slave
	reg  tip;         // transfer in progress
	reg  irq_flag;    // interrupt pending flag
	wire i2c_busy;    // bus busy (start signal detected)
	wire i2c_al;      // i2c bus arbitration lost
	reg  al;          // status register arbitration lost bit

	//
	// module body
	//

	// generate internal reset
	wire rst_i = arst_i ^ ARST_LVL;

	// generate wishbone signals
	wire wb_wacc = wb_we_i & wb_ack_o;
//<<< End of the Chunk

//>>> Chunk 3: Control logic of Wishbone bus interface
	// generate acknowledge output signal
	always @(posedge wb_clk_i)
	  wb_ack_o <= #1 wb_cyc_i & wb_stb_i & ~wb_ack_o; // because timing is always honored

	// assign DAT_O
	always @(posedge wb_clk_i)
	begin
	  case (wb_adr_i) // synopsys parallel_case
	    3'b001: wb_dat_o <= #1 prer[ 7:0];                                        // bug 4: should be "3'b000: wb_dat_o <= #1 prer[ 7:0];" Analysis: Chunk 3 implements the functionality of selecting different register data to output to wb_dat_o based on the address wb_adr_i. The prescaler register prer is a 16-bit register that, by convention, should be split into high and low 8-bit bytes mapped to consecutive addresses. In the case statement, address 3'b001 (binary 001, i.e., address 1) is mapped to prer[7:0] (low byte), while address 3'b000 (binary 000, i.e., address 0) is mapped to prer[15:8] (high byte). This violates the standard byte-ordering convention—typically, low addresses should store low bytes and high addresses should store high bytes. By comparing the mapping patterns of other registers in the case statement and analyzing the register address allocation principles in the overall module design, it can be inferred that this is an obvious address mapping error. The fix is to swap the address labels of these two lines: map 3'b000 to prer[7:0] and 3'b001 to prer[15:8], making the address mapping conform to byte-ordering conventions. The entire bug identification and fixing process is completely based on semantic analysis of the code within chunk 3, without needing to reference other parts of the module.
	    3'b000: wb_dat_o <= #1 prer[15:8];                                        // bug 4: should be "3'b001: wb_dat_o <= #1 prer[15:8];"
	    3'b010: wb_dat_o <= #1 ctr;
	    3'b011: wb_dat_o <= #1 rxr; // write is transmit register (txr)
	    3'b100: wb_dat_o <= #1 sr;  // write is command register (cr)
	    3'b101: wb_dat_o <= #1 txr;
	    3'b110: wb_dat_o <= #1 cr;
	    3'b111: wb_dat_o <= #1 0;   // reserved
	  endcase
	end
//<<<End of the Chunk

// >>> Chunk 4: Main register write control logic
	always @(posedge wb_clk_i or negedge rst_i)
	  if (!rst_i)
	    begin
	        prer <= #1 16'h0000;                         // bug 1: should be "prer <= #1 16'hffff;" Analysis: In the control logic of Chunk 4, the code contains two reset branches—asynchronous reset (!rst_i) and synchronous reset (wb_rst_i)—which should initialize registers to the same safe state. However, the clock prescaler register prer is incorrectly initialized to 16'h0000 in the asynchronous reset branch, while it is correctly initialized to 16'hffff in the synchronous reset branch, and this inconsistency exposes a potential defect. From a functional semantic analysis, prer serves as the core parameter of the clock prescaler, and its value directly determines the I2C clock frequency (typically calculated as SCL_freq = wb_clk / (5 * (prer + 1))). If initialized to 0, it would result in a divisor of 1, causing excessively high clock frequency or even hardware damage, whereas 0xffff as the maximum prescaler value ensures that the I2C bus operates at the lowest safe frequency after power-up until the software writes the desired configuration through the Wishbone bus. The fix logic is straightforward: change the prer initial value in the asynchronous reset branch from 16'h0000 to 16'hffff, making both reset paths consistent while satisfying the hardware safe-start design principle. The entire reasoning process relies entirely on the code symmetry and register functional semantics within Chunk 4, requiring no external information. 
	        ctr  <= #1  8'h0;
	        txr  <= #1  8'h0;
	    end
	  else if (wb_rst_i)
	    begin
	        prer <= #1 16'h0010;                        // bug 2: should be "prer <= #1 16'hffff;" Analysis: First, the asynchronous reset branch (!rst_i) at the beginning of chunk 4 clearly shows that the correct initial value of prer should be 16'hffff; second, chunk 4 completely demonstrates all write control logic for the prer register, including reset initialization and register access through the Wishbone bus; finally, from the overall functional description of the module, it is known that prer is a clock prescaler register, and initializing it to 0 would cause I2C clock frequency calculation errors, while initializing it to 0xffff (maximum value) is a safe default value.
	        ctr  <= #1  8'h0;
	        txr  <= #1  8'h0;
	    end
	  else
	    if (wb_wacc)
	      case (wb_adr_i) // synopsys parallel_case
	         3'b000 : prer [ 7:0] <= #1 wb_dat_o;         //bug 3: should be "3'b000 : prer [ 7:0] <= #1 wb_dat_i;"  Analysis: From the reset logic at the beginning of chunk 4, it is clear that this is an always block for writing to registers. Combined with the wb_wacc (Wishbone write access) condition and the case statement handling branches for different addresses, it can be clearly determined that the bus input data should be written to the internal registers (prer, ctr, txr), rather than writing back the output data.
	         3'b001 : prer [15:8] <= #1 wb_dat_o;          // should be "3'b001 : prer [15:8] <= #1 wb_dat_i;"
	         3'b010 : ctr         <= #1 wb_dat_o;         //should be "3'b010 : ctr         <= #1 wb_dat_i;" 
	         3'b011 : txr         <= #1 wb_dat_o;         //should be "3'b011 : txr         <= #1 wb_dat_i;"
	         default: #1;
	      endcase
// <<< End of the Chunk

//>>> Chunk 5: Command register special case handling and signal decoding
	always @(posedge wb_clk_i or negedge rst_i)
	  if (!rst_i)
	    cr <= #1 8'h0;
	  else if (wb_rst_i)
	    cr <= #1 8'h0;
	  else if (wb_wacc)
	    begin
	        if (core_en & (wb_adr_i == 3'b100) )
	          cr <= #1 wb_dat_i;
	    end
	  else
	    begin
	        if (done | i2c_al)
	          cr[7:4] <= #1 4'h0;           // clear command bits when done
	                                        // or when aribitration lost
	        cr[2:1] <= #1 2'b0;             // reserved bits
	        cr[0]   <= #1 1'b0;             // clear IRQ_ACK bit
	    end


	wire sta  = cr[7];
	wire sto  = cr[6];
	wire rd   = cr[5];
	wire wr   = cr[4];
	wire ack  = cr[3];
	wire iack = cr[0];

	assign core_en = ctr[7];
	assign ien = ctr[6];
// <<< End of the Chunk

// >>> Chunk 6: I2C byte controller instantiation
	i2c_master_byte_ctrl byte_controller (
		.clk      ( wb_clk_i     ),
		.rst      ( wb_rst_i     ),
		.nReset   ( rst_i        ),
		.ena      ( core_en      ),
		.clk_cnt  ( prer         ),
		.start    ( sta          ),
		.stop     ( sto          ),
		.read     ( rd           ),
		.write    ( wr           ),
		.ack_in   ( ack          ),
		.din      ( txr          ),
		.cmd_ack  ( done         ),
		.ack_out  ( irxack       ),
		.dout     ( rxr          ),
		.i2c_busy ( i2c_busy     ),
		.i2c_al   ( i2c_al       ),
		.scl_i    ( scl_pad_i    ),
		.scl_o    ( scl_pad_o    ),
		.scl_oen  ( scl_padoen_o ),
		.sda_i    ( sda_pad_i    ),
		.sda_o    ( sda_pad_o    ),
		.sda_oen  ( sda_padoen_o )
	);
// <<< End of the Chunk


// >>> Chunk 7: Status register and interrupt handling logic
	always @(posedge wb_clk_i or negedge rst_i)
	  if (!rst_i)
	    begin
	        al       <= #1 1'b0;
	        rxack    <= #1 1'b0;
	        tip      <= #1 1'b0;
	        irq_flag <= #1 1'b0;
	    end
	  else if (wb_rst_i)
	    begin
	        al       <= #1 1'b0;
	        rxack    <= #1 1'b0;
	        tip      <= #1 1'b0;
	        irq_flag <= #1 1'b0;
	    end
	  else
	    begin
	        al       <= #1 i2c_al | (al & ~sta);
	        rxack    <= #1 irxack;
	        tip      <= #1 (rd | wr);
	        irq_flag <= #1 (done | i2c_al | irq_flag) & ~iack; 
	    end

	always @(posedge wb_clk_i or negedge rst_i)
	  if (!rst_i)
	    wb_inta_o <= #1 1'b0;
	  else if (wb_rst_i)
	    wb_inta_o <= #1 1'b0;
	  else
	    wb_inta_o <= #1 irq_flag && ien; 

	assign sr[7]   = rxack;
	assign sr[6]   = i2c_busy;
	assign sr[5]   = al;
	assign sr[4:2] = 3'h0; // reserved
	assign sr[1]   = tip;
	assign sr[0]   = irq_flag;

endmodule
// <<< End of of Chunk
