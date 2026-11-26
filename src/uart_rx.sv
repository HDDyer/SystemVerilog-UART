/*
 * Copyright (c) 2026 Harrison Dyer
 * Licensed under the MIT License.
 * See LICENSE for details.
*/

`timescale 1ns / 1ps

module uart_rx #(
    parameter integer BAUD_RATE  = 115200,
    parameter integer CLOCK_FREQ = 27_000_000,
    parameter bit PARITY_EN = 1'b0, // 1 for on
    parameter bit PARITY_ODD    = 1'b0 // 1 for odd, 0 for even
) (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       rx,
    output logic [7:0] data_out,
    output logic       valid,
    output logic       frame_error,
    output logic       parity_error
);

    // a uart message looks something like the following,
    // 1..1 (idle)
    // 0 (START)
    // (?) (data, 8 bits)
    // 1 (END)

    typedef enum logic [2:0] {
        IDLE,      // waiting for start bit
        START_BIT, // confirm start bit at mid-bit
        DATA_BITS, // shift in 8 data bits, LSB first
        PARITY_BIT, // Check parity if EN
        STOP_BIT   // check stop bit is high
    } state_t;

    state_t state;

    logic [2:0] bit_index; // current data bit being received (0..7)
    logic [7:0] rx_shift;  // incoming bits
    logic       phase;     // 0 = first half-bit tick, 1 = mid bit
    logic       tick;      // half-bit tick
    logic       busy;      // high while receiving a frame

    logic rx_meta, rx_sync;
    logic rx_prev;

    logic parity_bit;
    assign parity_bit = PARITY_ODD ? ~(^rx_shift) : ^rx_shift;


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
            rx_prev <= 1'b1;
        end else begin
            rx_meta <= rx;
            rx_sync <= rx_meta;
            rx_prev <= rx_sync;
        end
    end

    assign busy = (state != IDLE);

    // 2x baud generator
    // half-bit tick generator, held in reset while idle
    baud_generator #(
        .BAUD_RATE (BAUD_RATE * 2),
        .CLOCK_FREQ(CLOCK_FREQ)
    ) baud_gen (
        .clk   (clk),
        .rst_n (rst_n),
        .enable(busy),
        .tick  (tick)
    );
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= IDLE;
            bit_index    <= 3'd0;
            rx_shift     <= 8'd0;
            data_out     <= 8'd0;
            phase        <= 1'b0;
            valid        <= 1'b0;
            frame_error  <= 1'b0;
            parity_error <= 1'b0;
        end else begin
            valid        <= 1'b0;
            frame_error  <= 1'b0;
            parity_error <= 1'b0;

            case (state)

                IDLE: begin
                    bit_index <= 3'd0;
                    phase     <= 1'b0;
                    if (rx_prev && !rx_sync) state <= START_BIT;
                end

                // re-check the line at mid start bit
                // if rx is high, it was a glitch -> back to IDLE
                START_BIT: begin
                    if (tick) begin
                        if (!rx_sync) state <= DATA_BITS;
                        else          state <= IDLE;
                    end
                end

                DATA_BITS: begin
                    if (tick) begin
                        phase <= ~phase;
                        if (phase) begin
                            rx_shift[bit_index] <= rx_sync;

                            if (bit_index == 3'd7) begin
                                if (PARITY_EN)
                                    state <= PARITY_BIT;
                                else
                                    state <= STOP_BIT;

                                phase <= 1'b0;
                            end else begin
                                bit_index <= bit_index + 1'b1;
                            end
                        end
                    end
                end

                PARITY_BIT: begin
                    if (tick) begin
                        phase <= ~phase;
                        if (phase) begin
                            if (rx_sync != parity_bit)
                                parity_error <= 1'b1;

                            state <= STOP_BIT;
                            phase <= 1'b0;
                        end
                    end
                end

                STOP_BIT: begin
                    if (tick) begin
                        phase <= ~phase;
                        if (phase) begin
                            state <= IDLE;

                            if (rx_sync) begin
                                if (!PARITY_EN || (parity_bit == parity_bit)) begin
                                    data_out <= rx_shift;
                                    if (!parity_error)
                                        valid <= 1'b1;
                                end
                            end else begin
                                frame_error <= 1'b1;
                            end
                        end
                    end
                end

                default: state <= IDLE;

            endcase
        end
    end
endmodule