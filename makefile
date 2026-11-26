SHELL = cmd.exe

SRC = $(wildcard src/*.v src/*.sv)

.PHONY: tx rx clean

tx rx: %: sim/uart_%_tb.sv $(SRC)
	if not exist build\sim mkdir build\sim
	iverilog -g2012 -s uart_$@_tb -o build/sim/$@.vvp sim/uart_$@_tb.sv $(SRC)
	-vvp build/sim/$@.vvp +trace
	gtkwave build/sim/uart_$@_tb.vcd

clean:
	if exist build rmdir /s /q build