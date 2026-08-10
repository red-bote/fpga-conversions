---------------------------------------------------------------------------------
-- DE10_lite Top level for Sky skipper by Dar (darfpga@aol.fr) (26/12/2019)
-- http://darfpga.blogspot.fr
---------------------------------------------------------------------------------
--
-- release rev 01 : few change but hardware description
--  (27/01/2020)
--
-- release rev -- : rev 00 release
--  (18/01/2020)
--
-- release rev -- : beta release
--  (12/01/2020)
--
---------------------------------------------------------------------------------
-- Educational use only
-- Do not redistribute synthetized file with roms
-- Do not redistribute roms whatever the form
-- Use at your own risk
---------------------------------------------------------------------------------
-- Use sky_skipper_de10_lite.sdc to compile (Timequest constraints)
-- /!\
-- Don't forget to set device configuration mode with memory initialization 
--  (Assignments/Device/Pin options/Configuration mode)
---------------------------------------------------------------------------------
--
-- Main features :
--  PS2 keyboard input @gpio pins 35/34 (beware voltage translation/protection) 
--  Audio pwm output   @gpio pins 1/3 (beware voltage translation/protection) 
--
--  Video         : VGA 31kHz/60Hz progressive and TV 15kHz interlaced
--  Cocktail mode : NO
--  Sound         : OK
-- 
-- For hardware schematic see my other project : NES
--
-- Uses 1 pll 40MHz from 50MHz to make 20MHz and 8Mhz 
--
-- Board key :
--   0 : reset game
--
-- Keyboard players inputs :
--
--   F1 : Add coin1
--   F2 : Add coin2
--   F3 : Start 1 player
--   F4 : Start 2 players

--   F7 : Service mode
--   F8 : 15kHz interlaced / 31 kHz progressive

--   SPACE  : fire1 (speed up plane)
--   F      : fire2 (bomb)

--   RIGHT arrow : move right
--   LEFT  arrow : move left
--   UP    arrow : up stairs
--   DOWN  arrow : down stairs
--
-- Other details : see sky skipper.vhd
-- For USB inputs and SGT5000 audio output see my other project: xevious_de10_lite
---------------------------------------------------------------------------------

+----------------------------------------------------------------------------------+
; Fitter Summary                                                                   ;
+------------------------------------+---------------------------------------------+
; Fitter Status                      ; Successful - Tue Jan 21 20:02:20 2020       ;
; Quartus Prime Version              ; 18.1.0 Build 625 09/12/2018 SJ Lite Edition ;
; Revision Name                      ; sky_skipper_de10_lite                       ;
; Top-level Entity Name              ; sky_skipper_de10_lite                       ;
; Family                             ; MAX 10                                      ;
; Device                             ; 10M50DAF484C6GES                            ;
; Timing Models                      ; Preliminary                                 ;
; Total logic elements               ; 3,458 / 49,760 ( 7 % )                      ;
;     Total combinational functions  ; 3,343 / 49,760 ( 7 % )                      ;
;     Dedicated logic registers      ; 890 / 49,760 ( 2 % )                        ;
; Total registers                    ; 890                                         ;
; Total pins                         ; 121 / 360 ( 34 % )                          ;
; Total virtual pins                 ; 0                                           ;
; Total memory bits                  ; 465,408 / 1,677,312 ( 28 % )                ;
; Embedded Multiplier 9-bit elements ; 0 / 288 ( 0 % )                             ;
; Total PLLs                         ; 1 / 4 ( 25 % )                              ;
; UFM blocks                         ; 0 / 1 ( 0 % )                               ;
; ADC blocks                         ; 0 / 2 ( 0 % )                               ;
+------------------------------------+---------------------------------------------+

---------------------------------------------------------------------------------
-- Sky skipper by Dar (darfpga@aol.fr) (12/01/2020)
-- http://darfpga.blogspot.fr
---------------------------------------------------------------------------------
--
-- release rev 01 : few change but hardware description
--  (27/01/2020)
--
-- release rev 00 : rev 00 release
--  (18/01/2020)
--
-- release rev -- : beta release
--  (12/01/2020)
--
---------------------------------------------------------------------------------
-- gen_ram.vhd & io_ps2_keyboard
-------------------------------- 
-- Copyright 2005-2008 by Peter Wendrich (pwsoft@syntiac.com)
-- http://www.syntiac.com/fpga64.html
---------------------------------------------------------------------------------
-- T80/T80se - Version : 304
-----------------------------
-- Z80 compatible microprocessor core
-- Copyright (c) 2001-2002 Daniel Wallner (jesus@opencores.org)
---------------------------------------------------------------------------------
-- YM2149 (AY-3-8910)
-- Copyright (c) MikeJ - Jan 2005
---------------------------------------------------------------------------------
-- Educational use only
-- Do not redistribute synthetized file with roms
-- Do not redistribute roms whatever the form
-- Use at your own risk
---------------------------------------------------------------------------------

--  Features :
--   Video        : VGA 31kHz/60Hz progressive and TV 15kHz interlaced
--   Coctail mode : NO
--   Sound        : OK

--  Use with MAME roms from skyskipr.zip
--
--  Use make_sky_skipper_proms.bat to build vhd file from binaries
--  (CRC list included)

--  Sky skipper Hardware caracteristics : TODO
--
---------------------------------------------------------------------------------
--  Sky skipper Hardware caracteristics:
--  
--  Sky skipper uses a hardware PCB close to Popeye PCB schematics TPP2. Indeed no 
--  schematic is available for Sky skipper. Difference between Popeye and Sky 
--  skipper comes from MAME source code.
--
--  Please read my Popeye.vhd hardware description which is almost the same as Sky
--  skipper. Below main differences are highlighted when needed.
--
--		Video  quartz	is 20.16MHz.
--
--	   Display is 512x448 pixels (video 640 pixels x 256 interlaced lines @ 10.08MHz).
--
--    Original interlaced timings :
--      640/10.08e6  = 63.49us per line  (15.750kHz).
--      63.49*256 = 16.254ms per frame (61.52Hz).
--
--    VHDL 60Hz Adapted interlaced timings (263 lines instead of 256):
--      640/10.08e6  = 63.49us per line  (15.750kHz).
--      63.49*263 = 16.70ms per frame (59.89Hz).
-- 
--    VHDL 60Hz Adapted progressive timings (526 lines instead of 512):
--      640/20.16e6  = 31.75us per line  (31.50kHz).
--      31.75*526 = 16.70ms per frame (59.89Hz).
--   
--    Char tile map and color are the same as Popeye.
--
--    Sprites are the same as Popeye except for color palette:
--      Only 1 global color bit is used and drives 2 address bits of color 
--      palette. last bit of color palette is stucked to '0'.
--
--    Program rom is 4x8Kx8bits addressed as 32Kx8bits (only 28K used):
--      addresses are bits swapped and xored w.r.t cpu addresses.
--      data      are bits swapped w.r.t cpu data.
--      Swap order and xor differs from Popeye ones.
--      
--    Working ram is split in two non consecutives parts:
--      2Kx8bits (low part) + 1Kx8bits (high part)
--      High part is addressed by cpu and by sprite data dma.
--
--    The most important difference is in the background management. Popeye
--    doesn't use H scroll and only little V scroll. In the opposite Sky skipper
--    make a large use of H/V scrolling.
--
--    It's not know if Sky skipper uses or not low/high nibble mecanism. Anyway
--    the total amount of bitmap ram is the same as Popeye one and is accessed
--    by CPU as 2 bank of 4Kx4bits. The bank selection is made by using bit 7 
--    of the data to be written. Data bits 0 to 3 only are written to ram and
--    are used as the individual bitmap bloc color.
--
--    Sky skipper background bitmap is 128(H)x64(V) blocs of 4x4 dots (bg dot is 
--    2 pixels x 2 lines).
--
--                                | #Y bloc position | #X bloc position  |
--                                |      63 to 0     |     127 to 0      |
--      bg ram address by cpu:    |      A(11-6)     |    D(7)-A(5-0)    |
--      bg ram address by video:  | V: 64*4*2 lines  | H: 128*4*2 pixels |
--
--
--      One bloc has a single color and is 8 pixels x 8 lines.
--      Total playground is 1024 pixels x 512 lines.
--
--    Sky skipper required one additionnal bit to allow H scroll to go from 0 to
--    511 (0-1022 pixels since H scroll has a 2 pixels resolution). In original
--    hardware this bit comes from sprite data buffer. In VHDL code it is latched
--    directly from cpu write to working ram (@8C02) 
--
---------------------------------------------------------------------------------
