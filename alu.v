//module name:alu
//An ALU for a 32-bit MIPS-ISA CPU. The “a” and “b” are the two operands of the ALU, the “aluc” is the opcode, and the “r” gives out the result. “zero” means if the result is zero, “carry” means if there is a carry bit, “negative” means if the result is negative, “overflow” means if the computation is overflow, the “flag” is the result of “slt” and “sltu” instructions. 

//>>> Fragment 1: Input and output port declarations
module alu(                  // bug 6: -->module alu(a,b,aluc,r,zero,carry,negative,overflow,flag);
    input [31:0] a,          // --> input [31:0] a;
    input [31:0] b,          // --> input [31:0] b;
    input [5:0] aluc,        // --> input [5:0] aluc;
    output [31:0] r,         // --> output [31:0] r;
    output zero,             // --> output zero;
    output carry,            // --> output negative;
    output negative,         // --> output overflow;
    output overflow,         // --> output flag;
    output flag
    );
//<<< End of the Fragment

//>>>Fragment 2: ALU operation code parameter definitions (arithmetic operations)
    parameter ADD = 6'b100000;
    parameter ADDU = 6'b100001;
    parameter SUB = 6'b100010;
    parameter SUBU = 6'b100011;
    parameter AND = 6'b100100;
    parameter OR = 6'b100101;
    parameter XOR = 6'b100110;
    parameter NOR = 6'b100111;
    parameter SLT = 6'b101010;
    parameter SLTU = 6'b101011;
//<<< End of the Fragment

//>>>Fragment 3: ALU Operation Code Parameter Definitions (Shift and Other Operations)
    parameter SLL = 6'b000000;
    parameter SRL = 6'b000010;
    parameter SRA = 6'b000011;
    parameter SLLV = 6'b000100;
    parameter SRLV = 6'b000110;
    parameter SRAV = 6'b000111;
    parameter JR = 6'b001000;
    parameter LUI = 6'b001111;
//<<< End of the Fragment

//>>> Fragment 4: Basic signal assignments and output connections
    wire signed [31:0] a_signed;        // bug 5: -->reg signed [31:0] a_signed;
    wire signed [31:0] b_signed;        // bug 5: --> reg signed [31:0] b_signed;
    reg [32:0] res;          // bug 2: --> reg [31:0] res;

    assign a_signed = a;
    assign b_signed = b;
    assign r = res[31:0];
    
    assign flag = (aluc == SLT || aluc == SLTU) ? ((aluc == SLT) ? (a_signed < b_signed) : (a < b)) : 1'bz; 
    assign zero = (res == 32'b0) ? 1'b1 : 1'b0;
// <<< End of the Fragment

// >>>Fragment 5: ALU main operation logic (arithmetic operation)
    always @ (a or b or aluc).  //bug 1: --> always @ (a or b)
    begin
        case(aluc)
            ADD: begin
                res <= a_signed + b_signed;    // bug 3: --> res <= a + b;
            end
            ADDU: begin
                res <= a + b;                  // bug 3: --> res <= a_signed + b_signed;
            end
            SUB: begin 
                res <= a_signed - b_signed;   // bug 4: --> res <= a - b;
            end
            SUBU: begin 
                res <= a - b;                 // bug 4: --> res <= a_signed - b_signed;
            end
            AND: begin
                res <= a & b; 
            end
            OR: begin
                res <= a | b;
            end
            XOR: begin
                res <= a ^ b;
            end
            NOR: begin
                res <= ~(a | b);
            end
// <<< End of the Fragment

// Fragment 6: ALU main operation logic (shift, comparison, and other operations)
            SLT: begin
                res <= a_signed < b_signed ? 1 : 0;
            end
            SLTU: begin
                res <= a < b ? 1 : 0;
            end
            SLL: begin
                res <= b << a;
            end
            SRL: begin
                res <= b >> a;
            end
            SRA: begin
                res <= b_signed >>> a_signed;
            end
            SLLV: begin
                res <= b << a[4:0];
            end
            SRLV: begin
                res <= b >> a[4:0];
            end
            SRAV: begin
                res <= b_signed >>> a_signed[4:0];
            end
            LUI: begin
                res <= {a[15:0], 16'h0000};
            end
            default:
            begin
                res <= 32'bz;
            end
        endcase
    end
endmodule
// >>> End of the Fragment
