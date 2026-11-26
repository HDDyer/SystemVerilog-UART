`timescale 1ns/1ps

module baud_generator_tb;
    localparam integer BAUD_RATE = 100_000;
    localparam integer CLOCK_FREQ = 1_000_000;
    localparam time CLK_PERIOD = 1us;

    logic clk;
    logic rst_n;
    logic enable;
    logic tick;

    baud_generator #(
        .BAUD_RATE(BAUD_RATE),
        .CLOCK_FREQ(CLOCK_FREQ)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .tick(tick)
    );

    // Clock generation
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    initial begin
        rst_n = 1'b0;
        enable = 1'b0;

        if ($test$plusargs("trace")) begin
            $dumpfile("build/sim/waves.vcd");
            $dumpvars(0, clk, rst_n, enable, tick);
        end

        // Reset
        repeat (5) @(posedge clk);
        rst_n = 1'b1;

        // Enable baud generator
        repeat (2) @(posedge clk);
        enable = 1'b1;

        repeat (50) @(posedge clk);

        enable = 1'b0;

        $display("Baud generator test complete");
        $finish;
    end
endmodule