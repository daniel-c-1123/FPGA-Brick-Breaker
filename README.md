# FPGA Brick Breaker

## Project Overview
This project recreates brick breaker using an FPGA. The FGPA drives a VGA monitor to display the game and takes inputs from buttons, switches, and an accelerometer chip to control the game. The switch inputs can adjust the puck speed, reset the game, and swap between button and tilt controls. With button controls, the paddle can be moved left and right by pressing two buttons. With tilt controls, the paddle can be moved by tilting the board left and right. To measure tilt, the FPGA communicates with an accelerometer chip via 3-wire SPI. I started this project for the purposes of learning digital design, SystemVerilog, and FPGA.

## Demo Video
A short demo video of the game can be viewed [here](https://drive.google.com/file/d/1CqT_u96qDHR4IjhVdggwrSt6mOE15Dk5/view).  
0:00 : I start the game with button controls with and a slow moving puck.  
0:16 : I increase the speed of the puck.  
0:40 : I reset the game, switch to tilt controls, and slow the puck slightly.

## Parts & Technologies used
* DE10-Lite Development Board (MAX-10 FPGA chip)
* ADXL345 Accelerometer Chip (G-Sensor)
* VGA Monitor
  
* Quartus for synthesizing HDL
* Questa-Altera FPGA edition for testbenching

## Core File Summary
These are the main modules required to run the brick breaker game. I wrote all of the modules from scratch, with the exception of one IP Core used to instantiate a PLL (pll_50_to_1.v). 
| Module  | Description |
| ------------- | ------------- |
| pong_logic.sv  | Contains the game's core logic; instantiates all game objects, tracks object positions & collisions, and calculates the VGA pixel color.  |
| vga_sync.sv  | Generates the Vsync and Hsync signals to drive the VGA monitor.  |
| border.sv  | Draws the boundaries of the playing area.  |
| brick.sv  | Draws the breakable brick objects.  |
| object.sv  | Draws a generic object; used for the paddle & puck objects.  |
| accelerometer_read_y.sv  | Reads tilt measured by the accelerometer chip; also initializes the accelerometer settings.|
| spi_controller_v3.sv  | Controller to communicate with the accelerometer chip via 3-wire SPI.|
| signed_to_unsigned.sv | Converts the signed reading of the accelerometer to an unsigned number. |
| pll_50_to_1.v  | PLL IP core used to generate a 1 MHz clock from the on-board 50 MHz clock.  |
| synchronizer.sv  | Synchronizer used for clock domain crossing from the accelerometer interface (1MHz) to the main game logic (50 MHz).  |
| pong_top_level.sv  | Top-level module used to package everything into an instance of the brick-breaker game |
| vga_top_wrapper.sv  | Wrapper module used to connect pins of the FPGA. |


## Misc Design Notes
These files include a couple of testbenches I created to verify VGA signal generation & SPI communication. The design notes feature timing diagrams & FSM diagrams I drew for the SPI & accelerometer controllers, as well as testbench waveforms. 
