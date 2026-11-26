`timescale 1ns/1ps

module uart_tx_tb;
    localparam integer BAUD_RATE = 100_000;
    localparam integer CLOCK_FREQ = 1_000_000;
    localparam time CLK_PERIOD = 1us;
    localparam time BIT_PERIOD = 10us;

    logic clk;
    logic rst_n;
    logic [7:0] data_in;
    logic send;

    logic tx;
    logic busy;

    uart_tx #(
        .BAUD_RATE(BAUD_RATE),
        .CLOCK_FREQ(CLOCK_FREQ),
        .PARITY_EN(1),
        .PARITY_ODD(1)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .send(send),
        .tx(tx),
        .busy(busy)
    );

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    initial begin
        rst_n = 1'b0;
        send = 1'b0;
        data_in = 8'h00;

        if ($test$plusargs("trace")) begin
            $dumpfile("build/sim/uart_tx_tb.vcd");
            $dumpvars(0, clk, rst_n, data_in, send, tx, busy);
        end

        repeat (5) @(posedge clk);

        rst_n = 1'b1;

        repeat (2) @(posedge clk);

        if (tx !== 1'b1)
            $fatal(1, "TX should be high after reset");

        if (busy !== 1'b0)
            $fatal(1, "BUSY should be low after reset");

        $display("Reset test passed");

        // Transmission test
        data_in = 8'hA5;
        // 101001011 -> END!
        @(posedge clk);
        send = 1'b1;

        @(posedge clk);
        send = 1'b0;

        // Wait for transmission to complete
        wait (busy == 1'b1);
        wait (busy == 1'b0);

        $display("Transmission test passed");

        $finish;
    end
endmodule
