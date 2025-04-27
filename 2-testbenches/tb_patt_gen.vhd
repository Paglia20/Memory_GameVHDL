LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;


ENTITY tb_pattern_generator IS
END tb_pattern_generator;

ARCHITECTURE behavior OF tb_pattern_generator IS
  -- Parametri del DUT
  CONSTANT LED_COUNT : integer := 16;
  CONSTANT CNT_WIDTH : integer := 4;

  -- Component declaration
  COMPONENT pattern_generator
    GENERIC (
      LED_COUNT : integer := LED_COUNT;
      CNT_WIDTH : integer := CNT_WIDTH
    );
    PORT (
      clk        : IN  std_logic;
      reset      : IN  std_logic;
      enable     : IN  std_logic;
      ones_count : IN  std_logic_vector(CNT_WIDTH-1 DOWNTO 0);
      pattern    : OUT std_logic_vector(LED_COUNT-1 DOWNTO 0);
      done       : OUT std_logic
    );
  END COMPONENT;

  -- Segnali di testbench
  SIGNAL clk_tb        : std_logic := '0';
  SIGNAL reset_tb      : std_logic := '1';
  SIGNAL enable_tb     : std_logic := '0';
  SIGNAL ones_count_tb : std_logic_vector(CNT_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL pattern_tb    : std_logic_vector(LED_COUNT-1 DOWNTO 0);
  SIGNAL done_tb       : std_logic;

  CONSTANT clk_period : time := 10 ns;

BEGIN
  -- Clock generator
  clk_process : PROCESS
  BEGIN
    LOOP
      clk_tb <= '0';
      WAIT FOR clk_period/2;
      clk_tb <= '1';
      WAIT FOR clk_period/2;
    END LOOP;
  END PROCESS;

  -- Instantiate DUT
  dut: pattern_generator
    GENERIC MAP (
      LED_COUNT => LED_COUNT,
      CNT_WIDTH => CNT_WIDTH
    )
    PORT MAP (
      clk        => clk_tb,
      reset      => reset_tb,
      enable     => enable_tb,
      ones_count => ones_count_tb,
      pattern    => pattern_tb,
      done       => done_tb
    );

  -- Stimulus process
  stim: PROCESS
  BEGIN
    -- Global reset
    reset_tb <= '1';
    WAIT FOR 50 ns;
    reset_tb <= '0';
    WAIT FOR 50 ns;

    -- Loop over values 6..8 for ones_count
    FOR i IN 6 TO 8 LOOP
      -- setta numero di 1
      ones_count_tb <= std_logic_vector(to_unsigned(i, CNT_WIDTH));
      -- generate new pattern
      enable_tb <= '1';
      WAIT FOR clk_period;
      enable_tb <= '0';

      -- aspetta la fine (done_tb = '1')
      WAIT UNTIL done_tb = '1';
      WAIT FOR 200 ns; -- lascia un po’ di tempo per osservare
    END LOOP;

    -- Fine simulazione
    report "Simulazione terminata.";
    assert false report "Stop simulazione." severity failure;

  END PROCESS;

END architecture behavior;