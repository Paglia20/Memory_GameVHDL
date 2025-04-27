library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_debouncer is
--  Port ( );
end tb_debouncer;

architecture Behavioral of tb_debouncer is

component debouncer 
  generic (
    counter_size : integer := 2 -- with 2, it takes 55 ns to detect a pulse and get's updated at the next clock rise
  );
  port (
    clock, reset : in std_logic;
    bouncy : in std_logic;
    pulse : out std_logic
  );
end component;

signal clock : std_logic := '0';
signal reset : std_logic := '0';
signal bouncy : std_logic := '0';
signal pulse : std_logic := '0';

begin
    -- dut instantiator, uses the internal signal to mimic hardware's
   dut : debouncer
   port map(
      clock  => clock,
      reset  => reset,
      bouncy => bouncy,
      pulse   => pulse
   );

   clock <= not(clock) after 5 ns;

   dut_test_proc : process
   begin

      reset <= '1';
      wait for 10 ns;
      reset <= '0';
      wait for 10 ns;

      --Simulates a quick bounce — a press that's too fast to be considered stable.

      bouncy <= '0';
      wait for 10 ns;

      bouncy <= '1';
      wait for 10 ns;

      bouncy <= '0';
      wait for 10 ns;

      bouncy <= '1';
      wait for 15 ns;

        -- this one is long enough for a second pulse to be generated 
      bouncy <= '0';
      wait for 10 ns;

      bouncy <= '1';
      wait for 75 ns;
      bouncy <= '0';

      wait for 50 ns;
      bouncy <= '1';
      wait for 300 ns;  -- ensure longer than debounce count
      bouncy <= '0';

      wait;
      end process;
   
      -- Stop simulation after a while
      end_sim_proc : process
      begin
         wait for 900 ns;
         assert false report "Simulation finished after 900ns." severity failure;
      end process;

end Behavioral;