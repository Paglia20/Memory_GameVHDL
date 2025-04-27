library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity debouncer is
  generic (
    counter_size : integer := 12
  );
  port (
    clock  : in std_logic;
    reset  : in std_logic;
    bouncy : in std_logic;
    pulse  : out std_logic
  );
end debouncer;

architecture behavioral of debouncer is

  signal counter         : unsigned(counter_size - 1 downto 0) := (others => '1');
  signal candidate_value : std_logic := '0';
  signal stable_value    : std_logic := '0';
  signal pulse_reg       : std_logic := '0';
  signal prev_stable     : std_logic := '0';

begin

  process(clock, reset)
  begin
    if reset = '1' then
      counter         <= (others => '1');
      candidate_value <= '0';
      stable_value    <= '0';
      pulse_reg       <= '0';
      prev_stable     <= '0';

    elsif rising_edge(clock) then
      pulse_reg <= '0'; -- default, unless explicitly raised

      -- Debouncing logic
      if bouncy = candidate_value then
        if counter = 0 then
          if stable_value /= candidate_value then
            stable_value <= candidate_value;
          end if;
        else
          counter <= counter - 1;
        end if;
      else
        candidate_value <= bouncy;
        counter <= (others => '1');
      end if;

      -- Pulse generation only on stable 0->1 edge
      if stable_value = '1' and prev_stable = '0' then
        pulse_reg <= '1';
      end if;

      -- Update previous stable value
      prev_stable <= stable_value;
    end if;
  end process;

  pulse <= pulse_reg;

end behavioral;