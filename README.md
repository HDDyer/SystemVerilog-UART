# UART (8N1, 8E1, 8O1)

A SystemVerilog UART transmitter and receiver core designed for the Tang Primer 20K FPGA. It is clock and baud-rate agnostic and should be able to operate on FPGAs assuming the pinout is correct. The main file, `uart.sv` contains a simple echo program to test the core.

## Design

- **Configurable UART framing (8N1, 8E1, 8O1)**
- **Fractional baud generator** 
- **Mid-bit RX sampling**

## Parameters

This core requires two parameters. Ensure that the `BAUD_RATE` matches the settings of your serial monitor. Default is no parity.

| Parameter | Default | Notes |
|---|---|---|
| `BAUD_RATE` | `115_200` | Line bit rate |
| `CLOCK_FREQ` | `27_000_000` | System clock (default on TANG PRIMER 20K) |
|`PARITY_EN`	|0|	|Enables parity when set to 1|
|`PARITY_ODD`	|0|	|Selects odd parity when set to 1|

## Interface

uart_tx.sv (UART transmitter)

Port | Dir | Description |
|---|---|---|
| `data_in[7:0]` | in | byte to send |
| `send` | in | begins a transmission|
| `tx` | out | serial/uart out pin |
| `busy` | out | high while the data is being transmitted |

uart_rx.sv (UART Reciever)

|Port | Dir | Description |
|---|---|---|
|`rx` | in | serial input, idles high |
|`data_out[7:0]` | out | last good byte, held until the next one |
|`valid` | out | Pulse when `data_out` has a new byte |
|`frame_error` | out | 1-clock pulse when the stop bit was low |
|`parity_error` | out | 1-clock pulse when parity bit is incorrect |

Both modules also take `clk` and an active-low `rst_n`.

## Simulation

```
make tx     # run the TX testbench
make rx     # run the RX testbench
make clean  # remove build/
```

You must run simulations outside of GOWIN as it does not support/track the files properly. This design passes the tests.

## Hardware

Built for a Gowin GW2A-18 (`GW2A-LV18PG256C8/I7`) chip found on the Tang Primer 20K Dock (if you are using another board like a TANG NANO, the pins will likely be different). Pinouts for this board and others can be found [here](https://dl.sipeed.com/TANG/).

| Port | Pin |
|---|---|
| `clk` | H11 |
| `tx` | M11 |
| `rx` | T13 (pull-up) |
| `led_err` | L14 |
| `led_alive` | L16 |

The design should operate normally using the USB-C UART port on the board. To test this, download a serial monitor like [Tera Term](https://teratermproject.github.io/index-en.html). If it is working properly, `led_alive` blinks once per byte. If there is a frame error or overflow, `led_err` will be enabled.

## Resource Usage

| Module (including baud generator) | LUTs | Registers |
|---|---|---|
| `uart_tx` | 121 | 43 |
| `uart_rx` | 108 | 56 |

Resource usage will depend on enabled settings. Adding the parity bits slighly increases the size however each module is still `<1%` utilization on the FPGA board.

## How to use this project

This project can be used directly inside of the Gowin EDA, assuming you have the correct board. The module [uart.sv](./src/uart.sv) contains a simple echo test program to ensure that the module works correctly on your machine.

To use the UART transmitter or receiver on their own, you can download the design files directly at [uart_rx](./src/uart_rx.sv) and [uart_tx](./src/uart_tx.sv). For these modules to work on their own, you must also download the baud generator found at [baud_generator](./src/baud_generator.sv).

## Troubleshooting

If the serial output displays `�` or other unexpected characters, check the following:

- Check the baud rate between the FPGA and serial monitor.
- Check parity configuration matches.
- Verify system clock speed.
- Check the RX/TX pin assignments on the board's schematic [here](https://dl.sipeed.com/TANG/).

The default configuration is 115200 baud with 8N1 framing.

## License

Licensed under MIT, view license [here](./LICENSE)