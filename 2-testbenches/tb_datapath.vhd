library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_datapath is
end tb_datapath;

architecture behavior of tb_datapath is

  component datapath
    port (
      clk          : in  std_logic;
      reset        : in  std_logic;
      start_compare: in  std_logic;
      level        : in  std_logic_vector(1 downto 0);
      pattern_in   : in  std_logic_vector(15 downto 0);
      switches     : in  std_logic_vector(15 downto 0);
      score        : out std_logic_vector(3 downto 0);
      score_valid  : out std_logic;
      level_up     : out std_logic;
      repeat_level : out std_logic
    );
  end component;

  signal clk_tb          : std_logic := '0';
  signal reset_tb        : std_logic := '1';
  signal start_compare_tb: std_logic := '0';
  signal level_tb        : std_logic_vector(1 downto 0) := (others => '0');
  signal pattern_in_tb   : std_logic_vector(15 downto 0) := (others => '0');
  signal switches_tb     : std_logic_vector(15 downto 0) := (others => '0');
  signal score_tb        : std_logic_vector(3 downto 0);
  signal score_valid_tb  : std_logic;
  signal level_up_tb     : std_logic;
  signal repeat_level_tb     : std_logic;

  constant clk_period : time := 10 ns;

begin

  clk_process : process
  begin
    while now < 1000 ns loop
      clk_tb <= '0'; wait for clk_period / 2;
      clk_tb <= '1'; wait for clk_period / 2;
    end loop;
    wait;
  end process;

  uut: datapath
    port map (
      clk           => clk_tb,
      reset         => reset_tb,
      start_compare => start_compare_tb,
      level         => level_tb,
      pattern_in    => pattern_in_tb,
      switches      => switches_tb,
      score         => score_tb,
      score_valid   => score_valid_tb,
      level_up      => level_up_tb,
      repeat_level => repeat_level_tb

    );

  stim_proc: process
  begin
    reset_tb <= '1';
    wait for 50 ns;
    reset_tb <= '0';
    wait for 20 ns;

    ----------------------------------------------------
    -- Test livello 1: 3 giusti, 1 mancante
    ----------------------------------------------------
    level_tb <= "00";  -- livello 1
    pattern_in_tb <= x"00F0";
    switches_tb   <= x"00E0";  -- uno mancante
    start_compare_tb <= '1'; wait for clk_period; start_compare_tb <= '0';
    wait until score_valid_tb = '1'; wait for clk_period;

    ----------------------------------------------------
    -- Test livello 2: 4 giusti, 1 sbagliato
    ----------------------------------------------------
    level_tb <= "01";  -- livello 2
    pattern_in_tb <= x"F000";
    switches_tb   <= x"F001";
    start_compare_tb <= '1'; wait for clk_period; start_compare_tb <= '0';
    wait until score_valid_tb = '1'; wait for clk_period;

    ----------------------------------------------------
    -- Test livello 3: 4 mancati → penalizzati
    ----------------------------------------------------
    level_tb <= "10";  -- livello 3
    pattern_in_tb <= x"0F01";
    switches_tb   <= x"0E00";
    start_compare_tb <= '1'; wait for clk_period; start_compare_tb <= '0';
    wait until score_valid_tb = '1'; wait for clk_period;

    ----------------------------------------------------
    -- Test livello 3: score oltre 16
    ----------------------------------------------------
    level_tb <= "10";
    pattern_in_tb <= x"FFFF";
    switches_tb   <= x"FFFF";
    start_compare_tb <= '1'; wait for clk_period; start_compare_tb <= '0';
    wait until score_valid_tb = '1'; wait for clk_period;

    report "Test completato.";
    assert false report "Fine simulazione." severity failure;
  end process;

end behavior;
