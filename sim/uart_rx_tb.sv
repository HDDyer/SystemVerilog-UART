`timescale 1ns/1ps

module uart_rx_tb;
    localparam integer BAUD_RATE = 100_000;
    localparam integer CLOCK_FREQ = 1_000_000;
    localparam time CLK_PERIOD = 1us;
    localparam time BIT_PERIOD = 10us;

    logic clk;
    logic rst_n;
    logic rx;

    logic [7:0] data_out;
    logic valid;
    logic frame_error;

    uart_rx #(
        .BAUD_RATE(BAUD_RATE),
        .CLOCK_FREQ(CLOCK_FREQ)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .data_out(data_out),
        .valid(valid),
        .frame_error(frame_error)
    );

    // Clock generation
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    initial begin
        rst_n = 1'b0;
        rx = 1'b1;

        if ($test$plusargs("trace")) begin
            $dumpfile("build/sim/uart_rx_tb.vcd");
            $dumpvars(0, clk, rst_n, rx, data_out, valid, frame_error);
        end

        // Reset
        repeat (5) @(posedge clk);
        rst_n = 1'b1;

        repeat (2) @(posedge clk);

        $display("Reset complete");

        // Output should be 0xA5 after all bits have been passed
        rx = 1'b0;
        #(BIT_PERIOD);

        rx = 1'b1; #(BIT_PERIOD);
        rx = 1'b0; #(BIT_PERIOD);
        rx = 1'b1; #(BIT_PERIOD);
        rx = 1'b0; #(BIT_PERIOD);
        rx = 1'b0; #(BIT_PERIOD);
        rx = 1'b1; #(BIT_PERIOD);
        rx = 1'b0; #(BIT_PERIOD);
        rx = 1'b1; #(BIT_PERIOD);

        rx = 1'b1;
        #(BIT_PERIOD);

        $display("Reception test complete");

        $finish;
    end
endmodule
