# FPGA Brick Breaker

## Project Overview
This project recreates brick breaker using an FPGA. The FGPA drives a VGA monitor to display the game and takes inputs from a buttons, switches, and an accelerometer chip to control the game. I started this project for the purposes of learning digital design, SystemVerilog, and FPGA.

## Parts & Technologies used
* DE-10- Lite Development Board (MAX-10 FPGA chip)
* ADXL345 Accelerometer Chip (G-Sensor)
* VGA Monitor
  
* Quartus for synthesizing HDL
* Questa for testbenching

## Core File Summary
These are the main modules required to run the brick breaker game. All of the modules were written from scratch, with the exception of one IP Core used to instantiate a PLL (pll_50_to_1.v). 
| Module  | Description |
| ------------- | ------------- |
| pong_logic.sv  | Contains the game's core logic; instantiates all game objects, tracks object positions & collisions, and calculates the VGA pixel color.  |
| vga_sync.sv  | Generates the Vsync and Hsync signals to drive the VGA output.  |
| border.sv  | Draws the boundaries of the playing area.  |
| brick.sv  | Draws the breakable brick objects.  |
| object.sv  | Draws a generic object; used for the paddle & puck objects.  |
| accelerometer_read_y.sv  | Reads tilt measured by the accelerometer chip; also initializes the accelerometer settings.|
| spi_controller_v3.sv  | Controller to communicate with the accelerometer chip via 3-wire SPI.|
| signed_to_unsigned.sv | Converts the signed output of the accelerometer to an unsigned number. |
| pll_50_to_1.v  | PLL IP core used to generate a 1 MHz clock from the native 50 MHz clock.  |
| synchronizer.sv  | Synchronizer used for clock domain crossing from the accelerometer interface (1MHz) to the main game logic (50 MHz).  |
| pong_top_level.sv  | Top-level module used to package everything into an instance of the brick-breaker game |
| vga_top_wrapper.sv  | Wrapper module used to connect pins of the FPGA. |
