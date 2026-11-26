/*
 * Copyright (c) 2026 Harrison Dyer
 * Licensed under the MIT License.
 * See LICENSE for details.
*/

`timescale 1ns / 1ps

// if there is a error, check the baud rate in tera term (or other) serial monitor.
module uart_tx #(
    parameter integer BAUD_RATE  = 115200,
    parameter integer CLOCK_FREQ = 27_000_000,
    parameter bit PARITY_EN = 1'b0, // 1 for on
    parameter bit PARITY_ODD    = 1'b0 // 1 for odd, 0 for even
) (
    input logic clk,
    input logic rst_n,
    input logic [7:0] data_in,
    input logic send,
    output logic tx,
    output logic busy
);
    logic parity_bit;
    assign parity_bit = PARITY_ODD ? ~(^tx_data) : ^tx_data;

    // uart message:
    // 0 -> START
    // (?) -> DATA
    // (?) -> PARITY
    // (1 (HELD)) -> END
    typedef enum logic [2:0] {
        IDLE,
        START_BIT,
        DATA_BITS,
        PARITY_BIT,
        STOP_BIT
    } state_t;

    state_t state;

    logic [3:0] bit_index;
    logic [7:0] tx_data;
    logic tick;

    baud_generator #(
        .BAUD_RATE (BAUD_RATE),
        .CLOCK_FREQ(CLOCK_FREQ)
    ) baud_gen (
        .clk(clk),
        .rst_n(rst_n),
        .enable(busy),
        .tick(tick)
    );

    assign busy = (state != IDLE);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            bit_index <= 4'd0;
            tx_data   <= 8'd0;
            tx        <= 1'b1;
        end else begin
            case (state)
                IDLE: begin
                    tx <= 1'b1;
                    if (send) begin
                        tx_data   <= data_in;
                        bit_index <= 4'd0;
                        tx        <= 1'b0;
                        state     <= START_BIT;
                    end
                end

                START_BIT: if (tick) begin
                    tx        <= tx_data[0]; // first 0 start bit
                    bit_index <= 4'd1;
                    state     <= DATA_BITS;
                end

                DATA_BITS: if (tick) begin
                    if (bit_index == 4'd8) begin
                        if (PARITY_EN) begin
                            tx    <= parity_bit;
                            state <= PARITY_BIT;
                        end else begin
                            tx    <= 1'b1;
                            state <= STOP_BIT;
                        end
                    end else begin
                        // append data and bump bit index until it reaches 8 bits and jumps to stop_bit state
                        tx        <= tx_data[bit_index];
                        bit_index <= bit_index + 4'd1;
                    end
                end

                PARITY_BIT: if (tick) begin
                    tx    <= 1'b1;
                    state <= STOP_BIT;
                end

                STOP_BIT: if (tick) state <= IDLE;

                default: begin
                    // on idle, tx stays high
                    state <= IDLE;
                    tx    <= 1'b1;
                end
            endcase
        end
    end
endmodule
