LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY seven_segment_driver IS
  GENERIC (
    size : INTEGER := 20
  );
  PORT (
    clock : IN STD_LOGIC;
    reset : IN STD_LOGIC;
    digit0 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    digit1 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    digit2 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    digit3 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    CA : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    AN : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
  );
END ENTITY seven_segment_driver;

ARCHITECTURE Behavioral OF seven_segment_driver IS

  SIGNAL flick_counter : unsigned(size - 1 DOWNTO 0);
  SIGNAL sel           : std_logic_vector(1 downto 0); -- selettore statico
  SIGNAL digit         : STD_LOGIC_VECTOR(3 DOWNTO 0);
  SIGNAL cathodes      : STD_LOGIC_VECTOR(7 DOWNTO 0);

BEGIN

  -- Divide the clock
  divide_clock : PROCESS (clock, reset)
  BEGIN
    IF reset = '1' THEN
      flick_counter <= (OTHERS => '0');
      sel <= (OTHERS => '0');
    ELSIF rising_edge(clock) THEN
      flick_counter <= flick_counter + 1;
      sel <= std_logic_vector(flick_counter(size - 1 DOWNTO size - 2)); -- prendo i 2 bit alti
    END IF;
  END PROCESS;

  -- Select the anode
  WITH sel SELECT
    AN <=
      "1110" WHEN "00",
      "1101" WHEN "01",
      "1011" WHEN "10",
      "0111" WHEN OTHERS;

  -- Select the digit
  WITH sel SELECT
    digit <=
      digit0 WHEN "00",
      digit1 WHEN "01",
      digit2 WHEN "10",
      digit3 WHEN OTHERS;

  -- Decode the digit
  WITH digit SELECT
    cathodes <=
      "11000000" WHEN "0000",
      "11111001" WHEN "0001",
      "10100100" WHEN "0010",
      "10110000" WHEN "0011",
      "10011001" WHEN "0100",
      "10010010" WHEN "0101",
      "10000010" WHEN "0110",
      "11111000" WHEN "0111",
      "10000000" WHEN "1000",
      "10010000" WHEN "1001",
      "10001000" WHEN "1010",
      "10000011" WHEN "1011",
      "11000110" WHEN "1100",
      "10100001" WHEN "1101",
      "10000110" WHEN "1110",
      "10001110" WHEN OTHERS;

  CA <= cathodes;

END Behavioral;