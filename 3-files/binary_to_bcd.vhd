LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY binary_to_bcd IS
  GENERIC(
    bits   : INTEGER := 10;
    digits : INTEGER := 3);
  PORT(
    clk     : IN    STD_LOGIC;
    reset   : IN    STD_LOGIC; 
    ena     : IN    STD_LOGIC;
    binary  : IN    STD_LOGIC_VECTOR(bits-1 DOWNTO 0);
    busy    : OUT   STD_LOGIC;
    bcd     : OUT   STD_LOGIC_VECTOR(digits*4-1 DOWNTO 0));
END binary_to_bcd;

ARCHITECTURE logic OF binary_to_bcd IS
  TYPE machine IS (idle, convert);
  SIGNAL state            : machine;
  SIGNAL binary_reg       : STD_LOGIC_VECTOR(bits-1 DOWNTO 0);
  SIGNAL bcd_reg          : STD_LOGIC_VECTOR(digits*4-1 DOWNTO 0);
  SIGNAL converter_ena    : STD_LOGIC;
  SIGNAL converter_inputs : STD_LOGIC_VECTOR(digits DOWNTO 0);

  COMPONENT binary_to_bcd_digit IS
    PORT(
      clk     : IN      STD_LOGIC;
      reset   : IN      STD_LOGIC; -- cambiato reset_n -> reset
      ena     : IN      STD_LOGIC;
      binary  : IN      STD_LOGIC;
      c_out   : BUFFER  STD_LOGIC;
      bcd     : BUFFER  STD_LOGIC_VECTOR(3 DOWNTO 0));
  END COMPONENT;

BEGIN

  PROCESS(reset, clk)
    VARIABLE bit_count : INTEGER RANGE 0 TO bits+1 := 0;
  BEGIN
    IF (reset = '1') THEN
      bit_count := 0;
      busy <= '1';
      converter_ena <= '0';
      bcd <= (OTHERS => '0');
      state <= idle;
    ELSIF (clk'EVENT AND clk = '1') THEN
      CASE state IS
        WHEN idle =>
          IF (ena = '1') THEN
            busy <= '1';
            converter_ena <= '1';
            binary_reg <= binary;
            bit_count := 0;
            state <= convert;
          ELSE
            busy <= '0';
            converter_ena <= '0';
            state <= idle;
          END IF;

        WHEN convert =>
          IF (bit_count < bits+1) THEN
            bit_count := bit_count + 1;
            converter_inputs(0) <= binary_reg(bits-1);
            binary_reg <= binary_reg(bits-2 DOWNTO 0) & '0';
            state <= convert;
          ELSE
            busy <= '0';
            converter_ena <= '0';
            bcd <= bcd_reg;
            state <= idle;
          END IF;
      END CASE;
    END IF;
  END PROCESS;

  bcd_digits: FOR i IN 1 TO digits GENERATE
    digit_0: binary_to_bcd_digit
      PORT MAP (clk, reset, converter_ena, converter_inputs(i-1), converter_inputs(i), bcd_reg(i*4-1 DOWNTO i*4-4));
  END GENERATE;

END logic;
