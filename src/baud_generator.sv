/*
 * Copyright (c) 2026 Harrison Dyer
 * Licensed under the MIT License.
 * See LICENSE for details.
 */
`timescale 1ns / 1ps

module baud_generator #(
    parameter integer BAUD_RATE  = 115_200,
    parameter integer CLOCK_FREQ = 27_000_000,  // base freq for SiPEED TANG PRIMER 20k
    parameter integer ACC_WIDTH  = 32
) (
    input  logic clk,
    input  logic rst_n,
    input  logic enable,
    output logic tick
);

    logic [ACC_WIDTH-1:0] accumulator;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accumulator <= '0;
            tick <= 1'b0;
        end else if (!enable) begin
            accumulator <= '0;
            tick <= 1'b0;
        end else begin
            // (all calculations assume default values)
            if (accumulator >= CLOCK_FREQ - BAUD_RATE) begin  // acc >= 26_884_800
                // accumulator = accumulator + 115_200 - 27_000_000,
                // this is not set to zero as accumulator may be greater than 0!!
                accumulator <= accumulator + BAUD_RATE - CLOCK_FREQ;
                tick <= 1'b1;
            end else begin
                accumulator <= accumulator + BAUD_RATE;  // accumulator = accumulator + 115_200
                tick <= 1'b0;
            end
        end
    end
endmodule
