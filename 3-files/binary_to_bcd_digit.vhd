LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY binary_to_bcd_digit IS
  PORT (
    clk     : IN    STD_LOGIC;
    reset   : IN    STD_LOGIC; -- cambiato reset_n -> reset
    ena     : IN    STD_LOGIC;
    binary  : IN    STD_LOGIC;
    c_out   : BUFFER STD_LOGIC := '0';
    bcd     : BUFFER STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0')
  );
END binary_to_bcd_digit;

ARCHITECTURE behavior OF binary_to_bcd_digit IS
BEGIN

  PROCESS (clk, reset)
  BEGIN
    IF reset = '1' THEN
      bcd   <= (OTHERS => '0');
      c_out <= '0';
    ELSIF rising_edge(clk) THEN
      IF ena = '1' THEN
        IF bcd /= "UUUU" THEN
          IF unsigned(bcd) >= 5 THEN
            bcd <= std_logic_vector(unsigned(bcd) + 3);
          END IF;
        END IF;
        c_out <= bcd(3);
        bcd   <= bcd(2 DOWNTO 0) & binary;
      END IF;
    END IF;
  END PROCESS;

END behavior;