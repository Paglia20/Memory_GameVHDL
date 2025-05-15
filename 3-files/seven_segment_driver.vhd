LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY seven_segment_driver IS
  GENERIC (
    size : INTEGER := 20  -- Adjust as needed to control refresh rate
  );
  PORT (
    clock  : IN STD_LOGIC;
    reset  : IN STD_LOGIC;
    digit0 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    digit1 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    digit2 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    digit3 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    digit4 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    digit5 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    digit6 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    digit7 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    CA     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    AN     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END ENTITY seven_segment_driver;

ARCHITECTURE Behavioral OF seven_segment_driver IS

  SIGNAL flick_counter : unsigned(size - 1 DOWNTO 0);
  SIGNAL sel           : std_logic_vector(2 DOWNTO 0); -- 3-bit selector for 8 digits
  SIGNAL digit         : STD_LOGIC_VECTOR(3 DOWNTO 0);
  SIGNAL cathodes      : STD_LOGIC_VECTOR(7 DOWNTO 0);

BEGIN

  -- Divide the clock and select digit
  divide_clock : PROCESS (clock, reset)
  BEGIN
    IF reset = '1' THEN
      flick_counter <= (OTHERS => '0');
      sel <= (OTHERS => '0');
    ELSIF rising_edge(clock) THEN
      flick_counter <= flick_counter + 1;
      sel <= std_logic_vector(flick_counter(size - 1 DOWNTO size - 3)); -- top 3 bits for 8 digits
    END IF;
  END PROCESS;

  -- Select the anode (active low)
  WITH sel SELECT
    AN <=
      "11111110" WHEN "000",
      "11111101" WHEN "001",
      "11111011" WHEN "010",
      "11110111" WHEN "011",
      "11101111" WHEN "100",
      "11011111" WHEN "101",
      "10111111" WHEN "110",
      "01111111" WHEN OTHERS;

  -- Select the digit input
  WITH sel SELECT
    digit <=
      digit0 WHEN "000",
      digit1 WHEN "001",
      digit2 WHEN "010",
      digit3 WHEN "011",
      digit4 WHEN "100",
      digit5 WHEN "101",
      digit6 WHEN "110",
      digit7 WHEN OTHERS;

  -- Decode the digit to 7-segment (CA is active low)
  WITH digit SELECT
    cathodes <=
      "11000000" WHEN "0000",  -- 0
      "11111001" WHEN "0001",  -- 1
      "10100100" WHEN "0010",  -- 2
      "10110000" WHEN "0011",  -- 3
      "10011001" WHEN "0100",  -- 4
      "10010010" WHEN "0101",  -- 5
      "10000010" WHEN "0110",  -- 6
      "11111000" WHEN "0111",  -- 7
      "10000000" WHEN "1000",  -- 8
      "10010000" WHEN "1001",  -- 9
      "10001000" WHEN "1010",  -- A
      "10000011" WHEN "1011",  -- b
      "11000110" WHEN "1100",  -- C
      "10100001" WHEN "1101",  -- d
      "10000110" WHEN "1110",  -- E
      "10001110" WHEN OTHERS;  -- F

  CA <= cathodes;

END ARCHITECTURE;