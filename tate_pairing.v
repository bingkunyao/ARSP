//module name: tate_pairing
//A hardware module that implements the Tate pairing algorithm for bilinear pairing operations in elliptic curve cryptography, primarily containing the core implementation of the Duursma-Lee algorithm and post-processing components.


//>>>Fragment 1: Compiler directives and global parameter definitions

`default_nettype none
 
`define M     97          // M is the degree of the irreducible polynomial
`define WIDTH (2*`M-1)    // width for a GF(3^M) element
`define W2    (4*`M-1)    // width for a GF(3^{2*M}) element
`define W3    (6*`M-1)    // width for a GF(3^{3*M}) element
`define W6    (12*`M-1)   // width for a GF(3^{6*M}) element
`define PX    196'h4000000000000000000000000000000000000000001000002
`define ZERO {(2*`M){1'b0}}
`define TWO {(2*`M-2){1'b0}},2'b10
//<<< End of the Fragment

// >>> Fragment 2: duursma_lee_algo module interface declaration and internal signal definitions
module duursma_lee_algo(clk, reset, xp, yp, xr, yr, done, out);
    input clk, reset;
    input [`WIDTH:0] xp, yp, xr, yr;
    output reg done;
    output reg [`W6:0] out;
 
    reg [`W6:0] t;
    reg [`WIDTH:0] a, b, y;
    reg [1:0] d;
    reg [`M:0] i;
    reg f3m_reset, delay1, delay2;
    wire [`W6:0] g,v7,v8;
    wire [`WIDTH:0] mu /* my name is "mew" */,nmu,ny,
                    x,v2,v3,v4,v5,v6;
    wire [1:0] v9;
    wire f36m_reset, dummy, f3m_done, f36m_done, finish, change;
 
    assign g = {`ZERO,`TWO,`ZERO,nmu,v6,v5};
    assign finish = i[0];
//<<< End of the Fragment

// >>>Fragment 3: F3M field arithmetic operation unit instantiation
    f3m_cubic
        ins1 (xr, x), 
        ins2 (yr, v2); 
    f3m_nine
        ins3 (clk, a, v3), 
        ins4 (clk, b, v4); 
    f3m_add3
        ins5 (v3, x, {{(2*`M-2){1'b0}},d}, mu); 
    f3m_neg
        ins6 (mu, nmu),                                       // bug 4: --> ins6 (nmu, mu), 
        ins7 (y,  ny);  
    f3m_mult
        ins8 (clk, delay2, mu, nmu, v5, f3m_done), 
        ins9 (clk, delay2, v4, ny,  v6, dummy); 
//<<< End of the Fragment

// >>>Fragment 4: F3M field arithmetic operation unit instantiation
    f36m_cubic
        ins10 (clk, t, v7); // v7 == t^3
    f36m_mult
        ins11 (clk, f36m_reset, v7, g, v8, f36m_done); // v8 == v7*g = (t^3)*g
    func6
        ins12 (clk, reset, f36m_done, change),
        ins13 (clk, reset, f3m_done, f36m_reset);
    f3_sub1
        ins14 (d, v9); // v9 == d-1
// <<< End of the Fragment

// >>> Fragment 5: Loop control and main state register update logic
    always @ (posedge clk)
        if (reset)
            i <= {1'b1, {`M{1'b0}}};
        else if (change | i[0])
            i <= i >> 1;                                               // bug 3: -->  i <= i << 1;
 
    always @ (posedge clk)
      begin
        if (reset)
          begin
            a <= xp; b <= yp; t <= 1; 
            y <= v2; d <= 1;
          end
        else if (change)
          begin
            a <= v3; b <= v4; t <= v8;
            y <= ny; d <= v9;
          end
      end
// <<< End of the Fragment

// >>> Fragment 6: Output control and timing management logic
    always @ (posedge clk)
        if (reset) begin 
          done <= 0;                         // bug 1: --> done <= 1
        end                       
        else if (finish) begin 
          done <= 1;                         // bug 1: --> done <= 0
          out <= v8;                         // bug 2: --> out <= v9;
        end
 
    always @ (posedge clk)
        if (reset)
          begin delay1 <= 1; delay2 <= 1; end
        else
          begin delay2 <= delay1; delay1 <= f3m_reset; end
 
    always @ (posedge clk)
        if (reset) f3m_reset <= 1;
        else if (change) f3m_reset <= 1;
        else f3m_reset <= 0;
endmodule
// <<< End of the Fragment

// >>>Fragment 7: tate_pairing top-level module declaration and submodule instantiation
module tate_pairing(clk, reset, x1, y1, x2, y2, done, out);
    input clk, reset;
    input [`WIDTH:0] x1, y1, x2, y2;
    output reg done;
    output reg [`W6:0] out;
 
    reg delay1, rst1;
    wire done1, rst2, done2;
    wire [`W6:0] out1, out2;
    reg [2:0] K;
 
    duursma_lee_algo 
        ins1 (clk, rst1, x1, y1, x2, y2, done1, out1);
    second_part
        ins2 (clk, rst2, out1, out2, done2);
    func6
        ins3 (clk, reset, done1, rst2);
// <<< End of the Fragment

// >>> Fragment 8: Control logic and state machine of tate_pairing module 
    always @ (posedge clk)
        if (reset)
          begin
            rst1 <= 1; delay1 <= 1;
          end
        else
          begin
            rst1 <= delay1; delay1 <= reset;
          end
 
    always @ (posedge clk)
        if (reset) K <= 3'b100;
        else if ((K[2]&rst2)|(K[1]&done2)|K[0])
            K <= K >> 1;
 
    always @ (posedge clk)
        if (reset) done <= 0;
        else if (K[0]) begin done <= 1; out <= out2; end
endmodule
// <<< End of the Fragment

