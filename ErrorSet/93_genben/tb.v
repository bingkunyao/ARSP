 module ref_f_permutation(clk, reset, in, in_ready, ref_ack, ref_out, ref_out_ready);
    input               clk, reset;
    input      [575:0]  in;
    input               in_ready;
    output              ref_ack;
    output reg [1599:0] ref_out;
    output reg          ref_out_ready;

    reg        [10:0]   i; /* select round constant */
    wire       [1599:0] round_in, round_out;
    wire       [63:0]   rc1, rc2;
    wire                update;
    wire                accept;
    reg                 calc; /* == 1: calculating rounds */

    assign accept = in_ready & (~ calc); // in_ready & (i == 0)
    
    always @ (posedge clk)
      if (reset) i <= 0;
      else       i <= {i[9:0], accept};
    
    always @ (posedge clk)
      if (reset) calc <= 0;
      else       calc <= (calc & (~ i[10])) | accept;
    
    assign update = calc | accept;

    assign ref_ack = accept;

    always @ (posedge clk)
      if (reset)
        ref_out_ready <= 0;
      else if (accept)
        ref_out_ready <= 0;
      else if (i[10]) // only change at the last round
        ref_out_ready <= 1;

    assign round_in = accept ? {in ^ ref_out[1599:1599-575], ref_out[1599-576:0]} : ref_out;

    ref_rconst2in1
      rconst_ ({i, accept}, rc1, rc2);

    ref_round2in1
      round_ (round_in, rc1, rc2, round_out);

    always @ (posedge clk)
      if (reset)
        ref_out <= 0;
      else if (update)
        ref_out <= round_out;
endmodule


module ref_rconst2in1(i, rc1, rc2);
    input  [11:0] i;
    output [63:0] rc1, rc2;
    reg    [63:0] rc1, rc2;
    
    always @ (i)
      begin
        rc1 = 0;
        rc1[0] = i[0] | i[2] | i[3] | i[5] | i[6] | i[7] | i[10] | i[11];
        rc1[1] = i[1] | i[2] | i[4] | i[6] | i[8] | i[9];
        rc1[3] = i[1] | i[2] | i[4] | i[5] | i[6] | i[7] | i[9];
        rc1[7] = i[1] | i[2] | i[3] | i[4] | i[6] | i[7] | i[10];
        rc1[15] = i[1] | i[2] | i[3] | i[5] | i[6] | i[7] | i[8] | i[9] | i[10];
        rc1[31] = i[3] | i[5] | i[6] | i[10] | i[11];
        rc1[63] = i[1] | i[3] | i[7] | i[8] | i[10];
      end
    
    always @ (i)
      begin
        rc2 = 0;
        rc2[0] = i[2] | i[3] | i[6] | i[7];
        rc2[1] = i[0] | i[5] | i[6] | i[7] | i[9];
        rc2[3] = i[3] | i[4] | i[5] | i[6] | i[9] | i[11];
        rc2[7] = i[0] | i[4] | i[6] | i[8] | i[10];
        rc2[15] = i[0] | i[1] | i[3] | i[7] | i[10] | i[11];
        rc2[31] = i[1] | i[2] | i[5] | i[9] | i[11];
        rc2[63] = i[1] | i[3] | i[6] | i[7] | i[8] | i[9] | i[10] | i[11];
      end
endmodule

`define low_pos(x,y)        `high_pos(x,y) - 63
`define high_pos(x,y)       1599 - 64*(5*y+x)
`define add_1(x)            (x == 4 ? 0 : x + 1)
`define add_2(x)            (x == 3 ? 0 : x == 4 ? 1 : x + 2)
`define sub_1(x)            (x == 0 ? 4 : x - 1)
`define rot_up(in, n)       {in[63-n:0], in[63:63-n+1]}
`define rot_up_1(in)        {in[62:0], in[63]}

module ref_round2in1(in, round_const_1, round_const_2, ref_out);
    input  [1599:0] in;
    input  [63:0]   round_const_1, round_const_2;
    output [1599:0] ref_out;

    /* "a ~ g" for round 1 */
    wire   [63:0]   a[4:0][4:0];
    wire   [63:0]   b[4:0];
    wire   [63:0]   c[4:0][4:0], d[4:0][4:0], e[4:0][4:0], f[4:0][4:0], g[4:0][4:0];

    /* "aa ~ gg" for round 2 */
    wire   [63:0]   bb[4:0];
    wire   [63:0]   cc[4:0][4:0], dd[4:0][4:0], ee[4:0][4:0], ff[4:0][4:0], gg[4:0][4:0];

    genvar x, y;

    /* assign "a[x][y][z] == in[w(5y+x)+z]" */
    generate
      for(y=0; y<5; y=y+1)
        begin : L0
          for(x=0; x<5; x=x+1)
            begin : L1
              assign a[x][y] = in[`high_pos(x,y) : `low_pos(x,y)];
            end
        end
    endgenerate

    /* calc "b[x] == a[x][0] ^ a[x][1] ^ ... ^ a[x][4]" */
    generate
      for(x=0; x<5; x=x+1)
        begin : L2
          assign b[x] = a[x][0] ^ a[x][1] ^ a[x][2] ^ a[x][3] ^ a[x][4];
        end
    endgenerate

    /* calc "c == theta(a)" */
    generate
      for(y=0; y<5; y=y+1)
        begin : L3
          for(x=0; x<5; x=x+1)
            begin : L4
              assign c[x][y] = a[x][y] ^ b[`sub_1(x)] ^ `rot_up_1(b[`add_1(x)]);
            end
        end
    endgenerate

    /* calc "d == rho(c)" */
    assign d[0][0] = c[0][0];
    assign d[1][0] = `rot_up_1(c[1][0]);
    assign d[2][0] = `rot_up(c[2][0], 62);
    assign d[3][0] = `rot_up(c[3][0], 28);
    assign d[4][0] = `rot_up(c[4][0], 27);
    assign d[0][1] = `rot_up(c[0][1], 36);
    assign d[1][1] = `rot_up(c[1][1], 44);
    assign d[2][1] = `rot_up(c[2][1], 6);
    assign d[3][1] = `rot_up(c[3][1], 55);
    assign d[4][1] = `rot_up(c[4][1], 20);
    assign d[0][2] = `rot_up(c[0][2], 3);
    assign d[1][2] = `rot_up(c[1][2], 10);
    assign d[2][2] = `rot_up(c[2][2], 43);
    assign d[3][2] = `rot_up(c[3][2], 25);
    assign d[4][2] = `rot_up(c[4][2], 39);
    assign d[0][3] = `rot_up(c[0][3], 41);
    assign d[1][3] = `rot_up(c[1][3], 45);
    assign d[2][3] = `rot_up(c[2][3], 15);
    assign d[3][3] = `rot_up(c[3][3], 21);
    assign d[4][3] = `rot_up(c[4][3], 8);
    assign d[0][4] = `rot_up(c[0][4], 18);
    assign d[1][4] = `rot_up(c[1][4], 2);
    assign d[2][4] = `rot_up(c[2][4], 61);
    assign d[3][4] = `rot_up(c[3][4], 56);
    assign d[4][4] = `rot_up(c[4][4], 14);

    /* calc "e == pi(d)" */
    assign e[0][0] = d[0][0];
    assign e[0][2] = d[1][0];
    assign e[0][4] = d[2][0];
    assign e[0][1] = d[3][0];
    assign e[0][3] = d[4][0];
    assign e[1][3] = d[0][1];
    assign e[1][0] = d[1][1];
    assign e[1][2] = d[2][1];
    assign e[1][4] = d[3][1];
    assign e[1][1] = d[4][1];
    assign e[2][1] = d[0][2];
    assign e[2][3] = d[1][2];
    assign e[2][0] = d[2][2];
    assign e[2][2] = d[3][2];
    assign e[2][4] = d[4][2];
    assign e[3][4] = d[0][3];
    assign e[3][1] = d[1][3];
    assign e[3][3] = d[2][3];
    assign e[3][0] = d[3][3];
    assign e[3][2] = d[4][3];
    assign e[4][2] = d[0][4];
    assign e[4][4] = d[1][4];
    assign e[4][1] = d[2][4];
    assign e[4][3] = d[3][4];
    assign e[4][0] = d[4][4];

    /* calc "f = chi(e)" */
    generate
      for(y=0; y<5; y=y+1)
        begin : L5
          for(x=0; x<5; x=x+1)
            begin : L6
              assign f[x][y] = e[x][y] ^ ((~ e[`add_1(x)][y]) & e[`add_2(x)][y]);
            end
        end
    endgenerate

    /* calc "g = iota(f)" */
    generate
      for(x=0; x<64; x=x+1)
        begin : L60
          if(x==0 || x==1 || x==3 || x==7 || x==15 || x==31 || x==63)
            assign g[0][0][x] = f[0][0][x] ^ round_const_1[x];
          else
            assign g[0][0][x] = f[0][0][x];
        end
    endgenerate
    
    generate
      for(y=0; y<5; y=y+1)
        begin : L7
          for(x=0; x<5; x=x+1)
            begin : L8
              if(x!=0 || y!=0)
                assign g[x][y] = f[x][y];
            end
        end
    endgenerate

    /* round 2 */

    /* calc "bb[x] == g[x][0] ^ g[x][1] ^ ... ^ g[x][4]" */
    generate
      for(x=0; x<5; x=x+1)
        begin : L12
          assign bb[x] = g[x][0] ^ g[x][1] ^ g[x][2] ^ g[x][3] ^ g[x][4];
        end
    endgenerate

    /* calc "cc == theta(g)" */
    generate
      for(y=0; y<5; y=y+1)
        begin : L13
          for(x=0; x<5; x=x+1)
            begin : L14
              assign cc[x][y] = g[x][y] ^ bb[`sub_1(x)] ^ `rot_up_1(bb[`add_1(x)]);
            end
        end
    endgenerate

    /* calc "dd == rho(cc)" */
    assign dd[0][0] = cc[0][0];
    assign dd[1][0] = `rot_up_1(cc[1][0]);
    assign dd[2][0] = `rot_up(cc[2][0], 62);
    assign dd[3][0] = `rot_up(cc[3][0], 28);
    assign dd[4][0] = `rot_up(cc[4][0], 27);
    assign dd[0][1] = `rot_up(cc[0][1], 36);
    assign dd[1][1] = `rot_up(cc[1][1], 44);
    assign dd[2][1] = `rot_up(cc[2][1], 6);
    assign dd[3][1] = `rot_up(cc[3][1], 55);
    assign dd[4][1] = `rot_up(cc[4][1], 20);
    assign dd[0][2] = `rot_up(cc[0][2], 3);
    assign dd[1][2] = `rot_up(cc[1][2], 10);
    assign dd[2][2] = `rot_up(cc[2][2], 43);
    assign dd[3][2] = `rot_up(cc[3][2], 25);
    assign dd[4][2] = `rot_up(cc[4][2], 39);
    assign dd[0][3] = `rot_up(cc[0][3], 41);
    assign dd[1][3] = `rot_up(cc[1][3], 45);
    assign dd[2][3] = `rot_up(cc[2][3], 15);
    assign dd[3][3] = `rot_up(cc[3][3], 21);
    assign dd[4][3] = `rot_up(cc[4][3], 8);
    assign dd[0][4] = `rot_up(cc[0][4], 18);
    assign dd[1][4] = `rot_up(cc[1][4], 2);
    assign dd[2][4] = `rot_up(cc[2][4], 61);
    assign dd[3][4] = `rot_up(cc[3][4], 56);
    assign dd[4][4] = `rot_up(cc[4][4], 14);

    /* calc "ee == pi(dd)" */
    assign ee[0][0] = dd[0][0];
    assign ee[0][2] = dd[1][0];
    assign ee[0][4] = dd[2][0];
    assign ee[0][1] = dd[3][0];
    assign ee[0][3] = dd[4][0];
    assign ee[1][3] = dd[0][1];
    assign ee[1][0] = dd[1][1];
    assign ee[1][2] = dd[2][1];
    assign ee[1][4] = dd[3][1];
    assign ee[1][1] = dd[4][1];
    assign ee[2][1] = dd[0][2];
    assign ee[2][3] = dd[1][2];
    assign ee[2][0] = dd[2][2];
    assign ee[2][2] = dd[3][2];
    assign ee[2][4] = dd[4][2];
    assign ee[3][4] = dd[0][3];
    assign ee[3][1] = dd[1][3];
    assign ee[3][3] = dd[2][3];
    assign ee[3][0] = dd[3][3];
    assign ee[3][2] = dd[4][3];
    assign ee[4][2] = dd[0][4];
    assign ee[4][4] = dd[1][4];
    assign ee[4][1] = dd[2][4];
    assign ee[4][3] = dd[3][4];
    assign ee[4][0] = dd[4][4];

    /* calc "ff = chi(ee)" */
    generate
      for(y=0; y<5; y=y+1)
        begin : L15
          for(x=0; x<5; x=x+1)
            begin : L16
              assign ff[x][y] = ee[x][y] ^ ((~ ee[`add_1(x)][y]) & ee[`add_2(x)][y]);
            end
        end
    endgenerate

    /* calc "gg = iota(ff)" */
    generate
      for(x=0; x<64; x=x+1)
        begin : L160
          if(x==0 || x==1 || x==3 || x==7 || x==15 || x==31 || x==63)
            assign gg[0][0][x] = ff[0][0][x] ^ round_const_2[x];
          else
            assign gg[0][0][x] = ff[0][0][x];
        end
    endgenerate
    
    generate
      for(y=0; y<5; y=y+1)
        begin : L17
          for(x=0; x<5; x=x+1)
            begin : L18
              if(x!=0 || y!=0)
                assign gg[x][y] = ff[x][y];
            end
        end
    endgenerate

    /* assign "ref_out[w(5y+x)+z] == ref_out_var[x][y][z]" */
    generate
      for(y=0; y<5; y=y+1)
        begin : L99
          for(x=0; x<5; x=x+1)
            begin : L100
              assign ref_out[`high_pos(x,y) : `low_pos(x,y)] = gg[x][y];
            end
        end
    endgenerate
endmodule

`undef low_pos
`undef high_pos
`undef add_1
`undef add_2
`undef sub_1
`undef rot_up
`undef rot_up_1



 `timescale 1ns / 1ps
`define P 20

module tb;

    // Inputs
    reg clk;
    reg reset;
    reg [575:0] in;
    reg in_ready;

    // Outputs
    wire ref_ack;
    wire [1599:0] ref_out;
    wire ref_out_ready;

    wire dut_ack;
    wire [1599:0] dut_out;
    wire dut_out_ready;

	wire match;
 	integer total_tests = 0;
	integer failed_tests = 0;

assign match = ({ref_ack,ref_out,ref_out_ready} === ({ref_ack,ref_out,ref_out_ready}  ^ {dut_ack,dut_out,dut_out_ready}  ^ {ref_ack,ref_out,ref_out_ready} ));

    integer i;

    // Instantiate the Unit Under Test (UUT)
   ref_f_permutation  r(
        .clk(clk),
        .reset(reset),
        .in(in),
        .in_ready(in_ready),
        .ref_ack(ref_ack),
        .ref_out(ref_out),
        .ref_out_ready(ref_out_ready)
    );

    // Instantiate the Unit Under Test (UUT)
    f_permutation  dut(
        .clk(clk),
        .reset(reset),
        .in(in),
        .in_ready(in_ready),
        .ack(dut_ack),
        .out(dut_out),
        .out_ready(dut_out_ready)
    );

    initial begin
        // Initialize Inputs
        clk = 0;
        reset = 1;
        in = 0;
        in_ready = 0;

        // Wait 100 ns for global reset to finish
        #100;

        // Add stimulus here
        @ (negedge clk);
        if (dut_out !== 0) ; /* should be 0 */
        if (dut_ack !== 0) ; /* should be 0 */
        if (dut_out_ready !== 0) ; /* should be 0 */

        #(`P);
        reset = 0;
        in = 0;
        in_ready = 1;
        #(`P);
        if (dut_out_ready !== 0); /* should be 0 */
        in_ready = 0;

        /* check 1~22-th cycles */
        for(i=0; i<22; i=i+1)
          begin
            if (dut_out === 0) ; /* should not be 0 */
            if (dut_ack !== 0) ; /* should be 0 */
            if (dut_out_ready !== 0) ; /* should be 0 */
            #(`P);
          end
compare();
        /* check the 23-th cycle */
        if (dut_out === 0); /* should not be 0 */
        if (dut_ack !== 0) ; /* should be 0 */
        if (dut_out_ready !== 0) ; /* should be 0 */
        #(`P);
compare();
        /* check the 24-th cycle */
        #(`P); /* wait out */
        if (dut_out_ready !== 1); /* should be 1 */
        if(dut_out !== 1600'hf1258f7940e1dde784d5ccf933c0478ad598261ea65aa9eebd1547306f80494d8b284e056253d057ff97a42d7f8e6fd490fee5a0a44647c48c5bda0cd6192e76ad30a6f71b19059c30935ab7d08ffc64eb5aa93f2317d635a9a6e6260d71210381a57c16dbcf555f43b831cd0347c82601f22f1a11a5569f05e5635a21d9ae6164befef28cc970f2613670957bc46611b87c5a554fd00ecb8c3ee88a1ccf32c8940c7922ae3a26141841f924a2c509e416f53526e70465c275f644e97f30a13beaf1ff7b5ceca249) 
compare();
        #(3*`P); /* wait more cycles */
        if (dut_out_ready !== 1); /* should be 1 */
        /* "out" should not change */
        if(dut_out !== 1600'hf1258f7940e1dde784d5ccf933c0478ad598261ea65aa9eebd1547306f80494d8b284e056253d057ff97a42d7f8e6fd490fee5a0a44647c48c5bda0cd6192e76ad30a6f71b19059c30935ab7d08ffc64eb5aa93f2317d635a9a6e6260d71210381a57c16dbcf555f43b831cd0347c82601f22f1a11a5569f05e5635a21d9ae6164befef28cc970f2613670957bc46611b87c5a554fd00ecb8c3ee88a1ccf32c8940c7922ae3a26141841f924a2c509e416f53526e70465c275f644e97f30a13beaf1ff7b5ceca249) 
compare();
        in_ready = 1; /* feed in one more block */
        in = 0;
        #(`P);
        if (dut_out_ready !== 0) ; /* should be 0 */
        in_ready = 0;
        
        while (dut_out_ready !== 1)
            #(`P);
        if(dut_out !== 1600'h2d5c954df96ecb3c6a332cd07057b56d093d8d1270d76b6c8a20d9b25569d0944f9c4f99e5e7f156f957b9a2da65fb3885773dae1275af0dfaf4f247c3d810f71f1b9ee6f79a8759e4fecc0fee98b42568ce61b6b9ce68a1deea66c4ba8f974f33c43d836eafb1f5e00654042719dbd97cf8a9f009831265fd5449a6bf17474397ddad33d8994b4048ead5fc5d0be774e3b8c8ee55b7b03c91a0226e649e42e9900e3129e7badd7b202a9ec5faa3cce85b3402464e1c3db6609f4e62a44c105920d06cd26a8fbf5c) 
        compare();
        /* no wait, feed in one more block */
        in_ready = 1;
        #(`P);
        if (dut_out_ready !== 0); /* should be 0 */
        in_ready = 0;

        while (dut_out_ready !== 1)
            #(`P);
        if(dut_out !== 1600'h55eabb80767d364686c354c8d01cbace9452d254b0979b3dde59422be2c66f16c660e4f2d4d8212e78414f691b639bb3cbb20f9f1b22e381cf16da5fac2da63f83c0b76552d95f7c44efc84eaf017e1548d380ff3e532c9592436ec5c5e02f05bde57ca1ee8de7e9240970468a1fd1b012a978439cbb7686d26b59fcceff8b4dd2aa0f472110fff87bd44abf53f72551e15ad2b722d00bb7c56095932c792c459e02d1766ad3a79c312f2da72ada4ec368b9f274a8d7d6b92b7239f7e51eea1eb6947f6894d77aeb) 
compare();

   repeat (96) begin
      @(posedge clk);
	reset = $random;
	in = $random;
	in_ready = $random;
     
      compare();
    end
     compare();

$display("All tests passed: design passed");
        $display("\033[1;34mTotal testcases: %d, Failed testcases: %d\033[0m", total_tests, failed_tests);
        // Finish simulation

    if (failed_tests==0) begin
            $display("=====================Your Design Passed======================");
    end
        $finish;
    end

    always #(`P/2) clk = ~ clk;


task compare;
        total_tests = total_tests + 1;
        if (match)                                //condition to check DUT outputs and calculated 
                                                    //outputs from task are equal 
			begin			//	$display("\033[1;32mtestcase is passed!!!\033[0m");
				//$display("testcase is passed!!!");
			end

		else begin
			//$display("\033[1;31mtestcase is failed!!!\033[0m");
            failed_tests = failed_tests + 1; 
		end
	
endtask

endmodule

`undef P

