 
module ref_alt_exc_dpram (portadatain,
                ref_portadataout,
                portaaddr,
                portawe,
                portaena,
                portaclk,
                portbdatain,
                ref_portbdataout,
                portbaddr,
                portbwe,
                portbena,
                portbclk
                );
    parameter   operation_mode = "SINGLE_PORT" ;
    parameter   addrwidth      = 14            ;
    parameter   width          = 32            ;
    parameter   depth          = 16384         ;
    parameter   ramblock       = 65535         ;
    parameter   output_mode    = "UNREG"       ;
    parameter   lpm_file       = "NONE"        ;
    parameter lpm_type = "alt_exc_dpram";
    parameter   lpm_hint       = "UNUSED";
    reg [width-1:0]        dpram_content[depth-1:0];
    input                   portawe           ,
                            portbwe           ,
                            portaena          ,
                            portbena          ,
                            portaclk          ,
                            portbclk          ;
    input  [width-1:0]     portadatain       ;
    input  [width-1:0]     portbdatain       ;
    input  [addrwidth-1:0]   portaaddr         ;
    input  [addrwidth-1:0]   portbaddr         ;
    output [width-1:0]      ref_portadataout      ,
                            ref_portbdataout      ;
    reg                    portaclk_in_last  ;
    reg                    portbclk_in_last  ;
    wire                   portaclk_in       ;
    wire                   portbclk_in       ;
    wire                   portawe_in        ;
    wire                   portbwe_in        ;
    wire                   portaena_in       ;
    wire                   portbena_in       ;
    wire   [width-1:0]     portadatain_in    ;
    wire   [width-1:0]     portbdatain_in    ;
    wire   [width-1:0]     portadatain_tmp   ;
    wire   [width-1:0]     portbdatain_tmp   ;
    wire   [addrwidth-1:0]   portaaddr_in      ;
    wire   [addrwidth-1:0]   portbaddr_in      ;
    reg    [width-1:0]     portadataout_tmp  ;
    reg    [width-1:0]     portbdataout_tmp  ;
    reg    [width-1:0]     portadataout_reg  ;
    reg    [width-1:0]     portbdataout_reg  ;
    reg    [width-1:0]     portadataout_reg_out  ;
    reg    [width-1:0]     portbdataout_reg_out  ;
    wire   [width-1:0]     portadataout_tmp2 ;
    wire   [width-1:0]     portbdataout_tmp2 ;
    reg                    portawe_latched   ;
    reg                    portbwe_latched   ;
    reg    [addrwidth-1:0]   portaaddr_latched ;
    reg    [addrwidth-1:0]   portbaddr_latched ;
    assign portadatain_in = portadatain;
    assign portaaddr_in   = portaaddr;
    assign portaena_in    = portaena;
    assign portaclk_in    = portaclk;
    assign portawe_in     = portawe;
    assign portbdatain_in = portbdatain;
    assign portbaddr_in   = portbaddr;
    assign portbena_in    = portbena;
    assign portbclk_in    = portbclk;
    assign portbwe_in     = portbwe;
    initial
    begin
        if (lpm_file != "NONE" && lpm_file != "none") $readmemh(lpm_file, dpram_content);
        portaclk_in_last = 0;
        portbclk_in_last = 0;
    end
    always @(portaclk_in)
    begin
        if (portaclk_in != 0 && portaclk_in_last == 0)  
        begin
            portawe_latched   = portawe_in   ;
            portaaddr_latched = portaaddr_in ;
            if (portawe_latched == 'b0)
            begin
                if (portaaddr_latched == portbaddr_latched && portbwe_latched != 'b0)
                begin
                    portadataout_reg = portadataout_tmp;
                    portadataout_tmp = 'bx;
                end
                else
                begin
                    portadataout_reg = portadataout_tmp;
                    portadataout_tmp = dpram_content[portaaddr_latched];
                end
            end
            else
            begin
                if (portaaddr_latched == portbaddr_latched && portawe_latched != 'b0 && portbwe_latched != 'b0)
                begin
                    portadataout_reg                 = portadataout_tmp ;
                    dpram_content[portaaddr_latched] = 'bx              ;
                    portadataout_tmp                 = 'bx              ;
                end
                else
                begin
                    portadataout_reg                 = portadataout_tmp;
                    dpram_content[portaaddr_latched] = portadatain_tmp ;
                    portadataout_tmp                 = 'bx             ;
                end
            end 
        end 
        portaclk_in_last = portaclk_in;
    end 
    always @(portbclk_in)
    begin
        if (portbclk_in != 0 && portbclk_in_last == 0 && (operation_mode == "DUAL_PORT" || operation_mode == "dual_port"))  
        begin
            portbwe_latched   = portbwe_in   ;
            portbaddr_latched = portbaddr_in ;
            if (portbwe_latched == 'b0)
            begin
                if (portbaddr_latched == portaaddr_latched && portawe_latched != 'b0)
                begin
                    portbdataout_reg = portbdataout_tmp;
                    portbdataout_tmp = 'bx;
                end
                else
                begin
                    portbdataout_reg = portbdataout_tmp;
                    portbdataout_tmp = dpram_content[portbaddr_latched];
                end
            end
            else
            begin
                if (portbaddr_latched == portaaddr_latched && portbwe_latched != 'b0 && portawe_latched != 'b0)
                begin
                    portbdataout_reg                 = portbdataout_tmp ;
                    dpram_content[portbaddr_latched] = 'bx              ;
                    portbdataout_tmp                 = 'bx              ;
                end
                else
                begin
                    portbdataout_reg                 = portbdataout_tmp;
                    dpram_content[portbaddr_latched] = portbdatain_tmp ;
                    portbdataout_tmp                 = 'bx             ;
                end
            end 
        end 
        portbclk_in_last = portbclk_in;
    end 
    always @(portaena_in or portadataout_reg)
    begin
        if (output_mode == "REG" || output_mode == "reg")
            if ( portaena_in == 1'b1 )
                portadataout_reg_out = portadataout_reg ;
    end
    always @(portbena_in or portbdataout_reg)
    begin
        if (output_mode == "REG" || output_mode == "reg")
            if ( portbena_in == 1'b1 )
                portbdataout_reg_out = portbdataout_reg ;
    end
    assign portadataout_tmp2 = (output_mode == "REG" || output_mode == "reg") ? portadataout_reg_out[width-1:0] : portadataout_tmp[width-1:0];
    assign portbdataout_tmp2 = (output_mode == "REG" || output_mode == "reg") ? portbdataout_reg_out[width-1:0] : portbdataout_tmp[width-1:0];
    assign portadatain_tmp[width-1:0] = portadatain;
    assign portbdatain_tmp[width-1:0] = portbdatain;
    assign ref_portadataout = portadataout_tmp2;
    assign ref_portbdataout = portbdataout_tmp2;
endmodule




 `timescale 1ns / 1ps

module tb;

    // Parameters
    parameter CLK_PERIOD = 10; // Clock period
    parameter   operation_mode = "DUAL_PORT" ;
    parameter   output_mode    = "REG"       ;

    // Inputs
    reg clk_a;
    reg clk_b;
    reg we_a;
    reg we_b;
    reg ena_a;
    reg ena_b;
    reg signed [31:0] data_in_a;
    reg signed [31:0] data_in_b;
    reg [13:0] addr_a;
    reg [13:0] addr_b;

    // Outputs
    wire [31:0] data_out_a, ref_data_out_a;
    wire [31:0] data_out_b, ref_data_out_b;

wire       match;
integer    total_tests = 0;
integer    failed_tests = 0;
integer i = 0;
assign match = ({ref_data_out_a, ref_data_out_b} === ({ref_data_out_a, ref_data_out_b} ^ {data_out_a, data_out_b} ^ {ref_data_out_a, ref_data_out_b}));

    // Instantiate the alt_exc_dpram module
    alt_exc_dpram #(
            .operation_mode(operation_mode),
            .output_mode(output_mode)
         )uut (
        .portadatain(data_in_a),
        .portadataout(data_out_a),
        .portaaddr(addr_a),
        .portawe(we_a),
        .portaena(ena_a),
        .portaclk(clk_a),
        .portbdatain(data_in_b),
        .portbdataout(data_out_b),
        .portbaddr(addr_b),
        .portbwe(we_b),
        .portbena(ena_b),
        .portbclk(clk_b)
    );

    ref_alt_exc_dpram #(
            .operation_mode(operation_mode),
            .output_mode(output_mode)
         )ref_model (
        .portadatain(data_in_a),
        .ref_portadataout(ref_data_out_a),
        .portaaddr(addr_a),
        .portawe(we_a),
        .portaena(ena_a),
        .portaclk(clk_a),
        .portbdatain(data_in_b),
        .ref_portbdataout(ref_data_out_b),
        .portbaddr(addr_b),
        .portbwe(we_b),
        .portbena(ena_b),
        .portbclk(clk_b)
    );

    // Generate clock signals
    initial begin
        clk_a = 0;
        clk_b = 0;
        forever #(CLK_PERIOD / 2) begin
            clk_a = ~clk_a;
            clk_b = ~clk_b;
        end
    end

    // Test Procedure
    initial begin
        // Initialize inputs
        we_a = 0;
        we_b = 0;
        ena_a = 0;
        ena_b = 0;
        data_in_a = 0;
        data_in_b = 0;
        addr_a = 0;
        addr_b = 0;
           
          #10;
        we_a = 1;
        we_b = 1;
        ena_a = 1;
        ena_b = 1;
         
          #10;
        we_a = 0;
        we_b = 0;
        ena_a = 0;
        ena_b = 0;

           #10;

        // Test Case 1: Write to port A and read from port A
        addr_a = 14'h3FFF;
        data_in_a = 32'hDEADBEEF;
        we_a = 1;
        ena_a = 1;
         #50;
        we_a = 0; // Stop writing
         #50;
        
        // Check data out from port A
            compare();

        // Test Case 2: Write to port B and read from port A
        addr_b = 14'h3FFF;
        data_in_b = 32'hBEEFCAFE;
        we_b = 1;
        ena_b = 1;
          #50;
        we_b = 0; // Stop writing
         #50;
        
        // Check data out from port A (should be unchanged)
           compare();


        // Test Case 3: Read from port B
        addr_b = 14'h0002;
        ena_b = 1;
         #50;
        
        // Check data out from port B
            compare();


        // Test Case 4: Simultaneous read and write
        addr_a = 14'h0002;
        data_in_a = 32'hFACEB00C;
        we_a = 1;
        ena_a = 1;
         #50;
        
        // Check data out from both ports
            compare();
  
          //Test Case 5: Write the same address
            we_a = 1;
            ena_a = 1;
            data_in_a = $random;
            addr_a = 100;
            we_b = 1;
            ena_b = 1;
            data_in_b = $random;
            addr_b = 100;
               #100;
            compare();

       //Test Case 6: Read the same address
            we_a = 0;
            ena_a = 1;
            data_in_a = $random;
            addr_a = 100;
            we_b = 0;
            ena_b = 1;
            data_in_b = $random;
            addr_b = 100;
               #100;
            compare();

 for (i=0; i<97; i=i+1) begin
            we_a = 1;
            ena_a = 1;
            data_in_a = $random;
            addr_a = i;
            we_b = 1;
            ena_b = 1;
            data_in_b = $random;
            addr_b = i+100;
               #10;
            compare();
 end

 for (i=0; i<97; i=i+1) begin
            we_a = 0;
            ena_a = 1;
            data_in_a = $random;
            addr_a = i;
            we_b = 0;
            ena_b = 1;
            data_in_b = $random;
            addr_b = i+100;
               #10;
            compare();
 end



        // Finish simulation
        #(CLK_PERIOD * 10);
    $display("\033[1;34mAll tests completed.\033[0m");
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
	   end
	   else begin
	   //$display("\033[1;31mtestcase is failed!!!\033[0m");
         failed_tests = failed_tests + 1; 
         end
end
endtask

    initial begin
        $dumpfile("sim.fsdb");
        $dumpvars();
    end


endmodule
