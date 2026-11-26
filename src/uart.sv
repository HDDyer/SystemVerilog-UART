
`timescale 1ns / 1ps

// A basic UART test program.
// can be replaced with any other program without affecting functionality
// as the main code is in uart_rx.sv/uart_tx.sv
module uart #(
    parameter integer BAUD_RATE      = 115200,
    parameter integer CLOCK_FREQ     = 27_000_000,
    parameter bit     LED_ACTIVE_LOW = 1'b0,
    parameter bit     PARITY_EN      = 1'b0,
    parameter bit     PARITY_ODD     = 1'b0
) (
    input  logic clk,
    input  logic rx,
    output logic tx,
    output logic led_err,   // on after a frame error, parity error or fifo overflow
    output logic led_alive  // toggles on every received byte
);

    // power on reset, released once the counter is full to ensure solid state
    logic [15:0] por_cnt = 16'd0;
    logic        rst_n;

    always_ff @(posedge clk) begin
        if (!(&por_cnt))
            por_cnt <= por_cnt + 16'd1;
    end

    assign rst_n = &por_cnt;

    logic [7:0] rx_data;
    logic rx_valid, rx_frame_error, rx_parity_error;

    uart_rx #(
        .BAUD_RATE (BAUD_RATE),
        .CLOCK_FREQ(CLOCK_FREQ),
        .PARITY_EN (PARITY_EN),
        .PARITY_ODD(PARITY_ODD)
    ) uart_receiver (
        .clk         (clk),
        .rst_n       (rst_n),
        .rx          (rx),
        .data_out    (rx_data),
        .valid       (rx_valid),
        .frame_error (rx_frame_error),
        .parity_error(rx_parity_error)
    );

    // 16 byte fifo, the extra pointer bit tells full from empty
    logic [7:0] fifo [0:15];
    logic [4:0] wr_ptr, rd_ptr;
    logic       empty, full;

    assign empty = (wr_ptr == rd_ptr);
    assign full  = (wr_ptr[3:0] == rd_ptr[3:0]) &&
                   (wr_ptr[4] != rd_ptr[4]);

    logic send, busy;

    uart_tx #(
        .BAUD_RATE (BAUD_RATE),
        .CLOCK_FREQ(CLOCK_FREQ),
        .PARITY_EN (PARITY_EN),
        .PARITY_ODD(PARITY_ODD)
    ) uart_transmitter (
        .clk    (clk),
        .rst_n  (rst_n),
        .data_in(fifo[rd_ptr[3:0]]),
        .send   (send),
        .tx     (tx),
        .busy   (busy)
    );

    logic err_i, alive_i;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr  <= 5'd0;
            rd_ptr  <= 5'd0;
            send    <= 1'b0;
            err_i   <= 1'b0;
            alive_i <= 1'b0;
        end else begin
            send <= 1'b0; // send is only high for one clock

            // store each received byte, flag an error if the fifo is full
            if (rx_valid) begin
                alive_i <= ~alive_i;

                if (!full || send) begin
                    fifo[wr_ptr[3:0]] <= rx_data;
                    wr_ptr <= wr_ptr + 5'd1;
                end else begin
                    err_i <= 1'b1;
                end
            end

            if (rx_frame_error || rx_parity_error)
                err_i <= 1'b1;

            // send the oldest byte whenever the transmitter is free
            if (send) begin
                rd_ptr <= rd_ptr + 5'd1;
            end else if (!busy && !empty) begin
                send <= 1'b1;
            end
        end
    end

    assign led_err   = LED_ACTIVE_LOW ? ~err_i   : err_i;
    assign led_alive = LED_ACTIVE_LOW ? ~alive_i : alive_i;

endmodule
