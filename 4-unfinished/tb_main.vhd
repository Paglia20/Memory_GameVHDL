library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_main is
end tb_main;

architecture behavior of tb_main is

  -- Component declaration
  component main
    port (
      clock : in std_logic;
      reset : in std_logic;
      switches : in std_logic_vector(15 downto 0);
      btn_center : in std_logic;
      led : out std_logic_vector(15 downto 0);
      an : out std_logic_vector(3 downto 0);
      ca : out std_logic_vector(7 downto 0);
      state_out          : out std_logic_vector(4 downto 0) -- For debugging
    );
  end component;

  -- Signals
  signal clock_tb    : std_logic := '0';
  signal reset_tb    : std_logic := '1';
  signal switches_tb : std_logic_vector(15 downto 0) := (others => '0');
  signal btn_center_tb : std_logic := '0';
  signal led_tb      : std_logic_vector(15 downto 0);
  signal an_tb       : std_logic_vector(3 downto 0);
  signal ca_tb       : std_logic_vector(7 downto 0);
  signal state_out_s : std_logic_vector(4 downto 0);


  constant clk_period : time := 10 ns;

begin

  -- Clock generation
  clk_process : process
  begin
    loop
      clock_tb <= '0'; wait for clk_period / 2;
      clock_tb <= '1'; wait for clk_period / 2;
    end loop;
  end process;

  -- Instantiate the Unit Under Test (UUT)
  uut: main
    port map (
      clock => clock_tb,
      reset => reset_tb,
      switches => switches_tb,
      btn_center => btn_center_tb,
      led => led_tb,
      an => an_tb,
      ca => ca_tb,
      state_out => state_out_s
    );

  -- Stimulus process
  stim_proc : process
  begin
    -- Reset pulse
    reset_tb <= '1';
    wait for 20 ns;
    reset_tb <= '0';
    wait for 20 ns;

    -- Simulate a button press
    btn_center_tb <= '1';
    wait for 120 ns;
    btn_center_tb <= '0';

    -- Simulate some switch patterns
    switches_tb <= x"00F0"; -- some switches ON
    wait for 100 ns;

    switches_tb <= x"0F0F"; -- change switches
    wait for 100 ns;

    switches_tb <= (others => '0'); -- all switches OFF
    wait for 100 ns;

    -- Finish simulation
    wait for 500 ns;
    assert false report "Simulation finished" severity failure;
  end process;

end behavior;