 
module ref_bresenham_line(clk_i, rst_i,
pixel0_x_i, pixel0_y_i, pixel1_x_i, pixel1_y_i, 
draw_line_i, read_pixel_i, 
ref_busy_o, ref_x_major_o, ref_major_o, ref_minor_o, ref_valid_o
);
parameter point_width = 16;
parameter subpixel_width = 16;
input clk_i;
input rst_i;
input signed [point_width-1:-subpixel_width] pixel0_x_i;
input signed [point_width-1:-subpixel_width] pixel1_x_i;
input signed [point_width-1:-subpixel_width] pixel0_y_i;
input signed [point_width-1:-subpixel_width] pixel1_y_i;
input draw_line_i;
input read_pixel_i;
output reg ref_busy_o;
output reg ref_valid_o;
output reg signed [point_width-1:0] ref_major_o;
output reg signed [point_width-1:0] ref_minor_o;
reg [point_width-1:-subpixel_width] xdiff; 
reg [point_width-1:-subpixel_width] ydiff; 
output reg ref_x_major_o; 
reg signed [point_width-1:-subpixel_width] left_pixel_x; 
reg signed [point_width-1:-subpixel_width] left_pixel_y; 
reg signed [point_width-1:-subpixel_width] right_pixel_x; 
reg signed [point_width-1:-subpixel_width] right_pixel_y;
reg [point_width-1:-subpixel_width] delta_major; 
reg [point_width-1:-subpixel_width] delta_minor; 
reg minor_slope_positive; 
reg  signed          [point_width-1:0] major_goal;
reg  signed [2*point_width-1:-subpixel_width] eps;
wire signed [2*point_width-1:-subpixel_width] eps_delta_minor;
wire done;
reg [2:0] state;
parameter wait_state = 0, line_prep_state = 1, line_state = 2, raster_state = 3;
assign eps_delta_minor = eps+delta_minor;
always@(posedge clk_i or posedge rst_i)
if(rst_i)
  state <= wait_state;
else
  case (state)
    wait_state:
      if(draw_line_i)
        state <= line_prep_state; 
    line_prep_state:
      state <= line_state;
    line_state:
      state <= raster_state;
    raster_state:
      if(!ref_busy_o)
        state <= wait_state;
  endcase
wire is_inside_screen = (ref_minor_o >= 0) & (ref_major_o >= -1);
reg previously_outside_screen;
always@(posedge clk_i or posedge rst_i)
begin
  if(rst_i)
  begin
    minor_slope_positive <= 1'b0;
    eps                  <= 1'b0;
    ref_major_o              <= 1'b0;
    ref_minor_o              <= 1'b0;
    ref_busy_o               <= 1'b0;
    major_goal           <= 1'b0;
    ref_x_major_o            <= 1'b0;
    delta_minor          <= 1'b0;
    delta_major          <= 1'b0;
    ref_valid_o              <= 1'b0;
    left_pixel_x         <= 1'b0;
    left_pixel_y         <= 1'b0;
    right_pixel_x        <= 1'b0;
    right_pixel_y        <= 1'b0;
    xdiff                <= 1'b0;
    ydiff                <= 1'b0;
    previously_outside_screen <= 1'b0;
  end
  else
  begin
   case (state)
      wait_state:
        if(draw_line_i)
        begin
          previously_outside_screen <= 1'b0;
          ref_busy_o  <= 1'b1;
          ref_valid_o <= 1'b0;
          if(pixel0_x_i > pixel1_x_i)
          begin
            xdiff         <= pixel0_x_i - pixel1_x_i;
            left_pixel_x  <= pixel1_x_i;
            left_pixel_y  <= pixel1_y_i;
            right_pixel_x <= pixel0_x_i;
            right_pixel_y <= pixel0_y_i;
            if(pixel1_y_i > pixel0_y_i)
            begin
              ydiff                <= pixel1_y_i - pixel0_y_i;
              minor_slope_positive <= 1'b0;
            end
            else
            begin
              ydiff                <= pixel0_y_i - pixel1_y_i;
              minor_slope_positive <= 1'b1;
            end
          end
          else
          begin
            xdiff         <= pixel1_x_i - pixel0_x_i;
            left_pixel_x  <= pixel0_x_i;
            left_pixel_y  <= pixel0_y_i;
            right_pixel_x <= pixel1_x_i;
            right_pixel_y <= pixel1_y_i;
            if(pixel0_y_i > pixel1_y_i)
            begin
              ydiff                <= pixel0_y_i - pixel1_y_i;
              minor_slope_positive <= 1'b0; 
            end
            else
            begin
              ydiff                <= pixel1_y_i - pixel0_y_i;
              minor_slope_positive <= 1'b1; 
            end
          end
        end
      line_prep_state:
      begin
        if(xdiff > ydiff)
        begin 
          ref_x_major_o    <= 1'b1;
          delta_major  <= xdiff;
          delta_minor  <= ydiff;
        end
        else
        begin 
          ref_x_major_o    <= 1'b0;    
          delta_major  <= ydiff;
          delta_minor  <= xdiff; 
        end
      end
      line_state:
      begin
          if(ref_x_major_o) 
          begin
            ref_major_o    <= $signed(left_pixel_x[point_width-1:0]);
            ref_minor_o    <= $signed(left_pixel_y[point_width-1:0]);
            major_goal <= $signed(right_pixel_x[point_width-1:0]);
          end
          else 
          begin
            ref_major_o    <= $signed(left_pixel_y[point_width-1:0]);
            ref_minor_o    <= $signed(left_pixel_x[point_width-1:0]);
            major_goal <= $signed(right_pixel_y[point_width-1:0]);
          end
          eps          <= 1'b0;
          ref_busy_o       <= 1'b1;
          ref_valid_o      <= (left_pixel_x >= 0 && left_pixel_y >= 0);
          previously_outside_screen <= ~(left_pixel_x >= 0 && left_pixel_y >= 0);
      end
    raster_state:
    begin
      ref_valid_o <= (previously_outside_screen | read_pixel_i) & is_inside_screen;
      previously_outside_screen <= ~is_inside_screen;
      if((read_pixel_i & is_inside_screen) | previously_outside_screen)
      begin
        if((ref_major_o < major_goal) & minor_slope_positive & ref_x_major_o & ref_busy_o) 
        begin
          ref_major_o   <=  ref_major_o + 1'b1; 
          if((eps_delta_minor*2) >= $signed(delta_major))
          begin
            eps     <=  eps_delta_minor - delta_major;
            ref_minor_o <=  ref_minor_o + 1'b1; 
          end
          else
            eps     <=  eps_delta_minor;
        end
        else if((ref_major_o < major_goal) & minor_slope_positive & !ref_x_major_o & ref_busy_o) 
        begin
          ref_major_o   <=  ref_major_o + 1'b1; 
          if((eps_delta_minor*2) >= $signed(delta_major))
          begin
            eps     <=  eps_delta_minor - delta_major;
            ref_minor_o <=  ref_minor_o + 1'b1; 
          end
          else
            eps     <=  eps_delta_minor;
        end
        else if((ref_major_o > major_goal) & !minor_slope_positive & !ref_x_major_o & ref_busy_o)
        begin
          ref_major_o   <=  ref_major_o - 1'b1; 
          if((eps_delta_minor*2) >= $signed(delta_major))
          begin
            eps     <=  eps_delta_minor - delta_major;
            ref_minor_o <=  ref_minor_o + 1'b1; 
          end
          else
            eps     <=  eps_delta_minor;
        end
        else if((ref_major_o < major_goal) & !minor_slope_positive & ref_x_major_o & ref_busy_o)
        begin
          ref_major_o   <=  ref_major_o + 1'b1; 
          if((eps_delta_minor*2) >= $signed(delta_major))
          begin
            eps     <=  eps_delta_minor - delta_major;
            ref_minor_o <=  ref_minor_o - 1'b1; 
          end
          else
            eps     <=  eps_delta_minor;
        end
        else if(ref_busy_o)
        begin
          ref_busy_o <=  1'b0;
          ref_valid_o <= 1'b0;
        end
      end
    end
    endcase
  end
end
endmodule




 `timescale 1ns / 1ps

module tb;

    // Parameters
    parameter CLK_PERIOD = 10; // Clock period
    parameter point_width = 16;
    parameter subpixel_width = 16;

    // Inputs - 修复：使用正确的位宽
    reg clk_i;
    reg rst_i;
    reg signed [point_width-1:-subpixel_width] pixel0_x_i;  // 32位
    reg signed [point_width-1:-subpixel_width] pixel0_y_i;  // 32位
    reg signed [point_width-1:-subpixel_width] pixel1_x_i;  // 32位
    reg signed [point_width-1:-subpixel_width] pixel1_y_i;  // 32位
    reg draw_line_i;
    reg read_pixel_i;

    // Outputs
    wire ref_busy_o;
    wire ref_x_major_o;
    wire signed [15:0] ref_major_o;
    wire signed [15:0] ref_minor_o;
    wire ref_valid_o;

   // Outputs
    wire busy_o;
    wire x_major_o;
    wire signed [15:0] major_o;
    wire signed [15:0] minor_o;
    wire valid_o;


	wire match;
 	integer total_tests = 0;
	integer failed_tests = 0;

assign match = ({ref_busy_o,ref_x_major_o,ref_major_o,ref_minor_o,ref_valid_o} === ({ref_busy_o,ref_x_major_o,ref_major_o,ref_minor_o,ref_valid_o}  ^ {busy_o,x_major_o,major_o,minor_o,valid_o}  ^ {ref_busy_o,ref_x_major_o,ref_major_o,ref_minor_o,ref_valid_o} ));


    // Instantiate the bresenham_line module
    ref_bresenham_line rf (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .pixel0_x_i(pixel0_x_i),
        .pixel0_y_i(pixel0_y_i),
        .pixel1_x_i(pixel1_x_i),
        .pixel1_y_i(pixel1_y_i),
        .draw_line_i(draw_line_i),
        .read_pixel_i(read_pixel_i),
        .ref_busy_o(ref_busy_o),
        .ref_x_major_o(ref_x_major_o),
        .ref_major_o(ref_major_o),
        .ref_minor_o(ref_minor_o),
        .ref_valid_o(ref_valid_o)
    );

   // Instantiate the bresenham_line module
    bresenham_line dut(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .pixel0_x_i(pixel0_x_i),
        .pixel0_y_i(pixel0_y_i),
        .pixel1_x_i(pixel1_x_i),
        .pixel1_y_i(pixel1_y_i),
        .draw_line_i(draw_line_i),
        .read_pixel_i(read_pixel_i),
        .busy_o(busy_o),
        .x_major_o(x_major_o),
        .major_o(major_o),
        .minor_o(minor_o),
        .valid_o(valid_o)
    );

    // Generate clock signal
    initial begin
        clk_i = 0;
        forever #(CLK_PERIOD / 2) clk_i = ~clk_i;
    end

    // Test Procedure
    initial begin
        // Initialize inputs
        rst_i = 0;
        draw_line_i = 0;
        read_pixel_i = 0;
        pixel0_x_i = 0;
        pixel0_y_i = 0;
        pixel1_x_i = 0;
        pixel1_y_i = 0;

        // Apply reset
        #(CLK_PERIOD);
        rst_i = 1; // De-assert reset
        #(CLK_PERIOD);
        rst_i = 0; // Assert reset
        #(CLK_PERIOD);

        // Test Case 1: Draw a horizontal line
        pixel0_x_i = 10;
        pixel0_y_i = 10;
        pixel1_x_i = 20;
        pixel1_y_i = 10;
        draw_line_i = 1; // Start drawing
        #(CLK_PERIOD);
        draw_line_i = 0; // Stop drawing
        #(CLK_PERIOD * 10); // Wait for processing
        compare();
        // Check outputs
        if (valid_o) begin
            $display("Test Case 1 Passed: Horizontal line drawn.");
        end else begin
            $display("Test Case 1 Failed: Horizontal line not drawn.");
        end

        // Test Case 2: Draw a vertical line
        pixel0_x_i = 15;
        pixel0_y_i = 5;
        pixel1_x_i = 15;
        pixel1_y_i = 15;
        draw_line_i = 1; // Start drawing
        #(CLK_PERIOD);
        draw_line_i = 0; // Stop drawing
        #(CLK_PERIOD * 10); // Wait for processing
        compare();
        // Check outputs
        if (valid_o) begin
            $display("Test Case 2 Passed: Vertical line drawn.");
        end else begin
            $display("Test Case 2 Failed: Vertical line not drawn.");
        end

        // Test Case 3: Draw a diagonal line
        pixel0_x_i = 5;
        pixel0_y_i = 5;
        pixel1_x_i = 10;
        pixel1_y_i = 10;
        draw_line_i = 1; // Start drawing
        #(CLK_PERIOD);
        draw_line_i = 0; // Stop drawing
        #(CLK_PERIOD * 10); // Wait for processing
	compare();

        // Check outputs
        if (valid_o) begin
            $display("Test Case 3 Passed: Diagonal line drawn.");
        end else begin
            $display("Test Case 3 Failed: Diagonal line not drawn.");
        end

   repeat (96) begin
      @(posedge clk_i);
rst_i = $random;
pixel0_x_i = $random;
pixel0_y_i = $random;
pixel1_x_i = $random;
pixel1_y_i = $random;
draw_line_i = $random;
read_pixel_i = $random;
     compare();
    end
     

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
			begin				//$display("\033[1;32mtestcase is passed!!!\033[0m");
				//$display("testcase is passed!!!");
			end

		else begin
			//$display("\033[1;31mtestcase is failed!!!\033[0m");
            failed_tests = failed_tests + 1; 
		end
	
endtask
endmodule
