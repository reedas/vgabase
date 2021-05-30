library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


ENTITY VGA IS
PORT(
MAX10_CLK1_50: IN STD_LOGIC;
VGA_HS,VGA_VS:OUT STD_LOGIC;
KEY: STD_LOGIC_VECTOR(1 DOWNTO 0);
SW: STD_LOGIC_VECTOR(9 DOWNTO 0);
LEDR: std_logic_vector(9 downto 0);
VGA_R: OUT STD_LOGIC_VECTOR(3 downto 0);
VGA_G: OUT STD_LOGIC_VECTOR(3 downto 0);
VGA_B: OUT STD_LOGIC_VECTOR(3 downto 0)
);
END VGA;


ARCHITECTURE MAIN OF VGA IS
SIGNAL VGACLK,RESET:STD_LOGIC;
signal SEL:std_logic_vector(1 downto 0);
---------------
component pll
	PORT
	(
		inclk0		: IN STD_LOGIC  := '0';
		c0		: OUT STD_LOGIC 
	);
end component pll;
--------------
 COMPONENT SYNC IS
 PORT(
	CLK: IN STD_LOGIC;
	HSYNC: OUT STD_LOGIC;
	VSYNC: OUT STD_LOGIC;
	R: OUT STD_LOGIC_VECTOR(3 downto 0);
	G: OUT STD_LOGIC_VECTOR(3 downto 0);
	B: OUT STD_LOGIC_VECTOR(3 downto 0);
	SW: IN STD_LOGIC_VECTOR(9 DOWNTO 0);
   SEL: IN STD_LOGIC_VECTOR(1 downto 0)
	);
END COMPONENT SYNC;

 BEGIN
 SEL(0) <= not KEY(0);
 SEL(1) <= not KEY(1);
 C: pll PORT MAP (MAX10_CLK1_50, VGACLK);
 C1: SYNC PORT MAP(VGACLK, VGA_HS, VGA_VS, VGA_R, VGA_G, VGA_B, SW, SEL );
 
 END MAIN;
 