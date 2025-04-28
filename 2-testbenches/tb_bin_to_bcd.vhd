LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY tb_binary_to_bcd IS
END tb_binary_to_bcd;

ARCHITECTURE behavior OF tb_binary_to_bcd IS

  COMPONENT binary_to_bcd
    GENERIC (
      bits   : INTEGER := 4;
      digits : INTEGER := 2
    );
    PORT (
      clk     : IN  STD_LOGIC;
      reset   : IN  STD_LOGIC; -- cambiato reset_n -> reset
      ena     : IN  STD_LOGIC;
      binary  : IN  STD_LOGIC_VECTOR(bits - 1 DOWNTO 0);
      bcd     : OUT STD_LOGIC_VECTOR(digits * 4 - 1 DOWNTO 0);
      busy    : OUT STD_LOGIC
    );
  END COMPONENT;

  -- Clock
  SIGNAL clk        : STD_LOGIC := '0';
  SIGNAL reset      : STD_LOGIC := '0'; -- cambiato reset_n -> reset

  -- Lvl
  SIGNAL level_ena      : STD_LOGIC := '0';
  SIGNAL level_binary   : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
  SIGNAL level_bcd      : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL level_busy     : STD_LOGIC;

  -- Score
  SIGNAL score_ena      : STD_LOGIC := '0';
  SIGNAL score_binary   : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
  SIGNAL score_bcd      : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL score_busy     : STD_LOGIC;

  CONSTANT clk_period : TIME := 10 ns;

BEGIN

  -- Clock process
  clk_process : PROCESS
  BEGIN
    WHILE NOW < 3000 ns LOOP
      clk <= '0';
      WAIT FOR clk_period / 2;
      clk <= '1';
      WAIT FOR clk_period / 2;
    END LOOP;
    WAIT;
  END PROCESS;

  -- Instantiation 1: lvl
  level_converter : binary_to_bcd
    GENERIC MAP (
      bits   => 4,
      digits => 2
    )
    PORT MAP (
      clk     => clk,
      reset   => reset,
      ena     => level_ena,
      binary  => level_binary,
      bcd     => level_bcd,
      busy    => level_busy
    );

  -- Instantiation 2: score
  score_converter : binary_to_bcd
    GENERIC MAP (
      bits   => 4,
      digits => 2
    )
    PORT MAP (
      clk     => clk,
      reset   => reset,
      ena     => score_ena,
      binary  => score_binary,
      bcd     => score_bcd,
      busy    => score_busy
    );

  -- Stimulus
  stim_proc: PROCESS
  BEGIN
    -- Reset
    reset <= '1';
    WAIT FOR 100 ns;
    reset <= '0';
    WAIT FOR 50 ns;

    -- livello = 1, punteggio = 9
    level_binary  <= "0001";  
    score_binary  <= "1001";  

    -- Attiva entrambi
    level_ena <= '1';
    score_ena <= '1';
    WAIT FOR clk_period;
    level_ena <= '0';
    score_ena <= '0';

    -- Aspetta che abbiano finito
    WAIT UNTIL level_busy = '0' AND score_busy = '0';
    WAIT FOR 100 ns;

    WAIT;
  END PROCESS;

END behavior;