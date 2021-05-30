library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.dw.all;

ENTITY SYNC IS
PORT(
CLK: IN STD_LOGIC;
HSYNC: buffer STD_LOGIC;
VSYNC: buffer STD_LOGIC;
R: OUT STD_LOGIC_VECTOR(3 downto 0);
G: OUT STD_LOGIC_VECTOR(3 downto 0);
B: OUT STD_LOGIC_VECTOR(3 downto 0);
SW: IN STD_LOGIC_VECTOR(9 DOWNTO 0);
SEL: IN STD_LOGIC_VECTOR(1 downto 0)
);
END SYNC;


ARCHITECTURE MAIN OF SYNC IS
component bitMapScreen is
	 PORT(
			hp, vp : integer;
			bitaddr	:	in std_logic_vector(16 downto 0); -- text screen ram
			bitdata	:	in std_logic_vector(7 downto 0);
			nWr	:	in std_logic;
			pClk	:	in	std_logic;
			nblnk	:	in std_logic;
			
			pix	:	out std_logic_vector(7 downto 0)
			
			);
end component bitMapScreen;
-----640x480 @ 60 Hz pixel clock 25 MHz
constant		h_pulse 	:	INTEGER := 96;    	--horiztonal sync pulse width in pixels
constant		h_bp	 	:	INTEGER := 48;		--horizontal back porch width in pixels
constant		h_pixels	:	INTEGER := 640;		--horiztonal display width in pixels
constant		h_fp	 	:	INTEGER := 16;			--horiztonal front porch width in pixels
constant		v_pulse 	:	INTEGER := 2;			--vertical sync pulse width in rows
constant		v_bp	 	:	INTEGER := 33;			--vertical back porch width in rows
constant		v_pixels	:	INTEGER := 480;		--vertical display width in rows
constant		v_fp	 	:	INTEGER := 10;			--vertical front porch width in rows

signal ohsync:	std_logic;
signal ovsync:	std_logic;
signal oohsync:	std_logic;
signal oovsync:	std_logic;
SIGNAL SQ_X1: INTEGER RANGE 0 TO 639:=200;
SIGNAL SQ_Y1: INTEGER RANGE 0 TO 479:=200;
SIGNAL SQ_X2: INTEGER RANGE 0 TO 639:=300;
SIGNAL SQ_Y2: INTEGER RANGE 0 TO 479:=300;
SIGNAL BL_X1: INTEGER RANGE 0 TO 639:=400;
SIGNAL BL_Y1: INTEGER RANGE 0 TO 479:=400;
signal nBlanking: std_logic := '1';
signal txtRGB:	std_logic;
signal bmRGB:	std_logic_vector(7 downto 0);
signal scrAddress: std_logic_vector(16 downto 0); 
signal scrData :	std_logic_vector(7 downto 0);
signal nWr : std_logic;
signal RD1: std_logic_vector(3 downto 0);
signal GD1: std_logic_vector(3 downto 0);
signal BD1: std_logic_vector(3 downto 0);
signal RD2: std_logic_vector(3 downto 0);
signal GD2: std_logic_vector(3 downto 0);
signal BD2: std_logic_vector(3 downto 0);
signal RT: std_logic_vector(3 downto 0);
signal GT: std_logic_vector(3 downto 0);
signal BT: std_logic_vector(3 downto 0);
signal RBL: std_logic_vector(3 downto 0);
signal GBL: std_logic_vector(3 downto 0);
signal BBL: std_logic_vector(3 downto 0);
SIGNAL DRAW1,DRAW2, drawBL:STD_LOGIC:='0';
SIGNAL HPOS: INTEGER RANGE 0 TO 799:=0;
SIGNAL VPOS: INTEGER RANGE 0 TO 524:=0;
signal sixtyHz: integer range 0 to 6 := 0;
signal count100ms: integer range 0 to 9999 := 0;
signal scale: integer range 0 to 32 := 8;
signal scaleBL: integer range 0 to 32;
signal bl_delta: integer range -1 to 1 := 1;
signal collision: integer range 0 to 1 := 0;
--signal asteroid1 : std_logic_vector(99 downto 0) := 
--									  ('0','0','0','0','1','1','0','0','0','0',
--										'0','0','0','1','1','1','1','0','0','0',
--										'0','0','0','1','1','1','1','1','1','0',
--										'0','0','1','1','1','1','1','1','1','0',
--										'1','1','1','1','0','0','1','1','1','1',
--										'1','1','1','0','0','0','0','1','1','1',
--										'1','1','1','1','0','0','1','1','1','1',
--										'0','0','1','1','1','1','1','1','1','0',
--										'0','0','1','1','1','1','1','0','0','0',
--										'0','0','0','1','1','1','0','0','0','0');
--signal asteroid2 : std_logic_vector(99 downto 0) := 
--									  ('0','0','0','0','1','1','0','0','0','0',
--										'0','0','0','1','0','0','1','0','0','0',
--										'0','0','0','1','0','0','0','1','1','0',
--										'0','0','1','0','0','0','0','0','1','0',
--										'0','1','0','0','0','0','0','0','0','1',
--										'1','0','0','0','0','0','0','0','0','1',
--										'1','1','0','0','0','0','0','0','0','1',
--										'0','0','1','0','0','0','0','1','1','0',
--										'0','0','1','0','0','0','1','0','0','0',
--										'0','0','0','1','1','1','0','0','0','0');
--signal ablock : std_logic_vector(99 downto 0) := 
--									  ('1','1','1','1','1','1','1','1','1','1',
--										'1','1','1','1','1','1','1','1','1','1',
--										'1','1','1','1','1','1','1','1','1','1',
--										'1','1','1','1','1','1','1','1','1','1',
--										'1','1','1','1','1','1','1','1','1','1',
--										'1','1','1','1','1','1','1','1','1','1',
--										'1','1','1','1','1','1','1','1','1','1',
--										'1','1','1','1','1','1','1','1','1','1',
--										'1','1','1','1','1','1','1','1','1','1',
--										'1','1','1','1','1','1','1','1','1','1');
BEGIN
--SP(HPOS,VPOS,SQ_X1,SQ_Y1,asteroid1,scale,DRAW1);
--SP(HPOS,VPOS,SQ_X2,SQ_Y2,asteroid2,scale,DRAW2);
--SP(HPOS,VPOS,BL_X1,BL_Y1,ablock,scaleBL,DRAWBL);
scr: bitMapScreen
		port map (hpos, vpos, scrAddress, scrData, nWr, Clk, nBlanking, bmRGB);
 PROCESS(CLK)
 BEGIN
	IF(CLK'EVENT AND CLK='0')THEN
--      IF(DRAW1='1')THEN
--			IF(SEL(0)='1')THEN
--				RD1<=(others=>'1');
--				GD1<=(others=>'0');
--				BD1<=(others=>'0');
--			ELSE
--				RD1<=(others=>'0');
--				GD1<=(others=>'0');
--				BD1<=(others=>'1');
--			END IF;
--		else
--			RD1<=(others=>'0');
--	      GD1<=(others=>'0');
--	      BD1<=(others=>'0');
--      END IF;
--		IF(DRAW2='1')THEN
--			IF(SEL(1)='1')THEN
--				RD2<=(others=>'0');
--				GD2<=(others=>'1');
--				BD2<=(others=>'0');
--			ELSE
--				RD2<=(others=>'0');
--				GD2<=(others=>'1');
--				BD2<=(others=>'1');
--		  END IF;
--		else
--			RD2<=(others=>'0');
--	      GD2<=(others=>'0');
--	      BD2<=(others=>'0');
--      END IF;
--		IF(DRAWBL='1')THEN
--				RBL<=(others=>'1');
--				GBL<=(others=>'0');
--				BBL<=(others=>'1');
--		ELSE
--				RBL<=(others=>'0');
--				GBL<=(others=>'0');
--				BBL<=(others=>'0');
--      END IF;
		if (bmRGB = "000000000") then
			RT<=(others=>'0');
			GT<=(others=>'0');
			BT<=(others=>'0');
		ELSE
			RT(3 downto 1)<=bmrgb(7 downto 5);
			GT(3 downto 1)<=bmrgb(4 downto 2);
			BT(3 downto 2)<=bmrgb(1 downto 0);
			RT(0) <= '0';
			GT(0) <= '0';
			BT(1 downto 0) <= "00";
		END IF;

		IF(HPOS<h_pixels + h_fp + h_pulse + h_bp)THEN
		HPOS<=HPOS+1;
		ELSE
		HPOS<=0;
			IF(VPOS<v_pixels + v_fp + v_pulse + v_bp)THEN
				VPOS<=VPOS+1;
			ELSE
				VPOS<=0; 
--			      IF(SEL(0)='1')THEN
--					    IF(SW(0)='1')THEN
--						  SQ_X1<=(SQ_X1+5) MOD 640;
--						 END IF;
--                   IF(SW(1)='1')THEN
--						  SQ_X1<=(SQ_X1-5) MOD 640;
--						 END IF;
--						  IF(SW(2)='1')THEN
--						  SQ_Y1<=SQ_Y1-5;
--						 END IF;
--						 IF(SW(3)='1')THEN
--						  SQ_Y1<=SQ_Y1+5;
--						 END IF;  
--					END IF;
--			      IF(SEL(1)='1')THEN
--					    IF(SW(0)='1')THEN
--						  SQ_X2<=(SQ_X2+5) MOD 640;
--						 END IF;
--                   IF(SW(1)='1')THEN
--						  SQ_X2<=(SQ_X2-5) MOD 640;
--						 END IF;
--						 IF(SW(2)='1')THEN
--						  SQ_Y2<=SQ_Y2-5;
--						 END IF;
--						 IF(SW(3)='1')THEN
--						  SQ_Y2<=SQ_Y2+5;
--						 END IF; 
--					END IF;  
		    END IF;
		END IF;
		IF((HPOS>h_pixels) OR (VPOS>v_pixels))THEN -- blanking
			R<=(others=>'0');
			G<=(others=>'0');
			B<=(others=>'0');
			nblanking <= '0';
		else
--			R<= RD1 or RD2 or RBL or RT;
--			G<= GD1 or GD2 or GBL or GT;
--			B<= BD1 or BD2 or BBL or BT;
			R <= RT;
			G <= GT;
			B <= BT;
			nBlanking <= '1';
--			if (RBL = "1111" and GD2 = "1111") then 
--				collision <= 1;
--				scaleBL <= 1;
--			end if;
--			if (RBL = "1111" and GD2 = "0000") then
--				collision <= 0;
--				scaleBL <= 2;
--			end if;
		END IF;
		IF(HPOS> (h_pixels + h_fp) AND HPOS<(h_pixels + h_fp + h_pulse))THEN----HSYNC
			ooHSYNC<='0';
			hsync <= oohsync;
		eLSE
			ooHSYNC<='1';
			hsync <= oohsync;
		END IF;
		IF (vpos > (v_pixels + v_fp) AND VPOS<(v_pixels + v_fp + v_pulse))THEN----------vsync
			oovSYNC<='0';
			vsync <= oovsync;

		ELSE
			ooVSYNC<='1';
			vsync <= oovsync;

		END IF;
	END IF;
 END PROCESS;
-- process (vsync)
-- begin -- move or scale stuff
--	if (vsync'event and vsync = '0') then
--		bl_x1 <= bl_x1 + bl_delta;
--		if bl_x1 = h_pixels + 5 - scalebl*10 then
--			bl_delta <= -1;
--		end if; 
--		if bl_x1 = 5*scalebl then
--			bl_delta <= 1;
--		end if;
--		sixtyHz <= sixtyHz + 1;
--		if (sixtyHz > 5) then
--			count100ms <= count100ms + 1;
--			sixtyHz <= 0;
--			scale <= scale + 1;
--			
--		end if;
--	end if;
--
-- 
-- end process;
 END MAIN;