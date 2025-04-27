LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY binary_to_bcd_digit IS
  PORT (
    clk     : IN    STD_LOGIC;
    reset_n : IN    STD_LOGIC;
    ena     : IN    STD_LOGIC;
    binary  : IN    STD_LOGIC;                          -- bit corrente in ingresso
    c_out   : BUFFER STD_LOGIC := '0';                  -- carry per cifra successiva
    bcd     : BUFFER STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0')  -- cifra BCD
  );
END binary_to_bcd_digit;

ARCHITECTURE behavior OF binary_to_bcd_digit IS
BEGIN

  PROCESS (clk, reset_n)
  BEGIN
  bcd <= bcd;
    IF reset_n = '0' THEN
      bcd   <= (OTHERS => '0');
      c_out <= '0';
    ELSIF rising_edge(clk) THEN
      IF ena = '1' THEN
        -- Se cifra >= 5, aggiungi 3, il warning si verificava perchè bcd viene valutato troppo presto, prima che il reset abbia avuto effetto completo, quindi UUUU protections
        IF bcd /= "UUUU" THEN
          IF unsigned(bcd) >= 5 THEN
            bcd <= std_logic_vector(unsigned(bcd) + 3);
          END IF;
        END IF;

        -- Shift sinistra: entra il bit binario, esce MSB come carry
        c_out <= bcd(3);
        bcd   <= bcd(2 DOWNTO 0) & binary;
      END IF;
    END IF;
  END PROCESS;

END behavior;
