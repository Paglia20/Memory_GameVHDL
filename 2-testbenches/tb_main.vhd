-- Testbench per MAIN (senza note)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_main is
end entity;

architecture behavior of tb_main is

  component main
    generic (
      main_counter_size : integer := 12;
      main_DELAY_CYCLES : integer := 100000000;
      main_blink_value  : integer := 6
    );
    port (
      clock : in std_logic;
      reset : in std_logic;
      switches : in std_logic_vector(15 downto 0);
      btn_center : in std_logic;
      led : out std_logic_vector(15 downto 0);
      an : out std_logic_vector(3 downto 0);
      ca : out std_logic_vector(7 downto 0)
    );
  end component;

  signal clock : std_logic := '0';
  signal reset : std_logic := '0';
  signal switches : std_logic_vector(15 downto 0) := (others => '0');
  signal btn_center : std_logic := '0';
  signal led : std_logic_vector(15 downto 0);
  signal an : std_logic_vector(3 downto 0);
  signal ca : std_logic_vector(7 downto 0);

  constant clk_period : time := 10 ns;

begin

  uut: main
    generic map (    
      main_counter_size => 4,
      main_DELAY_CYCLES => 5,
      main_blink_value  => 6
    )
    port map (
      clock => clock,
      reset => reset,
      switches => switches,
      btn_center => btn_center,
      led => led,
      an => an,
      ca => ca
    );

  clock_process : process
  begin
    while now < 10 ms loop
      clock <= '0';
      wait for clk_period / 2;
      clock <= '1';
      wait for clk_period / 2;
    end loop;
    wait;
  end process;

  stim_proc: process
  begin
    reset <= '1';
    wait for 100 ns;
    reset <= '0';
    wait for 100 ns;

    btn_center <= '1';
    wait for 300 ns;
    btn_center <= '0';

    wait for 2 us;

    switches <= "1000110000001110"; 
    wait for 200 ns;

    btn_center <= '1';
    wait for 300 ns;
    btn_center <= '0';

    wait for 100 ns;

    switches <= (others => '0');

    -- second level
    wait for 500 ns;
    switches <= "1000110001010100";
    wait for 200 ns;

    btn_center <= '1';
    wait for 300 ns;
    btn_center <= '0';

    wait for 100 ns;

    switches <= (others => '0');

    wait;


  end process;

    -- Timeout per evitare loop infiniti
    end_sim_proc : process
    begin
      wait for 2 ms;
      assert false report "Timeout raggiunto (2ms). Simulazione interrotta." severity failure;
    end process;

end architecture;
