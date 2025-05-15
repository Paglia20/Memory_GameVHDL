LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

entity pattern_generator is
  GENERIC (
    LED_COUNT  : integer := 16;  -- larghezza del pattern
    CNT_WIDTH  : integer := 4    -- bit per rappresentare ones_count (0..8)
  );
  PORT (
    clk        : IN  std_logic;
    reset      : IN  std_logic;                                -- attivo alto
    enable     : IN  std_logic;                                -- genera nuovo pattern quando 1
    ones_count : IN  std_logic_vector(CNT_WIDTH-1 DOWNTO 0);   -- quanti 1 inserire (0..8)
    pattern    : OUT std_logic_vector(LED_COUNT-1 DOWNTO 0);   -- risultato
    done       : OUT std_logic                                 -- sale a '1' quando pronto
  );
end entity pattern_generator;

architecture Behavioral of pattern_generator is

  type state_type is (idle, load, shuffle, done_state);
  signal state       : state_type := idle;

  signal shuffle_pass : integer range 0 to 3 := 0;
  constant MAX_PASSES : integer := 2;

  signal pattern_reg : std_logic_vector(LED_COUNT-1 DOWNTO 0) := (others => '0');
  signal lfsr        : std_logic_vector(LED_COUNT-1 DOWNTO 0) := (others => '1');
  signal i_count     : integer range 0 to LED_COUNT-1 := 0;
  signal target_cnt  : integer range 0 to LED_COUNT := 0;
  signal done_int    : std_logic := '0';

  signal seed_counter : std_logic_vector(LED_COUNT-1 DOWNTO 0) := (others => '0');

begin

  pattern <= pattern_reg;
  done    <= done_int;

  -- Free-running counter for randomness
  process(clk)
  begin
    if rising_edge(clk) then
      seed_counter <= std_logic_vector(unsigned(seed_counter) + 1);
    end if;
  end process;

  process(clk, reset)
    variable temp_bit : std_logic;
    variable j_idx    : integer range 0 to LED_COUNT-1;
  begin
    if reset = '1' then
      state       <= idle;
      pattern_reg <= (others => '0');
      lfsr        <= (others => '1');
      i_count     <= 0;
      target_cnt  <= 0;
      done_int    <= '0';

    elsif rising_edge(clk) then
      case state is

        when idle =>
          done_int <= '0';
          if enable = '1' then
            -- Clamp ones_count
            if unsigned(ones_count) > LED_COUNT then
              target_cnt <= LED_COUNT;
            else
              target_cnt <= to_integer(unsigned(ones_count));
            end if;
            lfsr <= seed_counter;

            state <= load;
          end if;

        when load =>
          -- Set exactly `target_cnt` 1s, rest 0s
          for idx in 0 to LED_COUNT-1 loop
            if idx < target_cnt then
              pattern_reg(idx) <= '1';
            else
              pattern_reg(idx) <= '0';
            end if;
          end loop;
          i_count <= LED_COUNT - 1;
          shuffle_pass <= 0;
          state <= shuffle;

        when shuffle =>
          -- Update LFSR (x^16 + x^14 + 1)
          lfsr <= lfsr(LED_COUNT-2 DOWNTO 0) & (lfsr(LED_COUNT-1) XOR lfsr(LED_COUNT-3));

          -- Pick random index j
          j_idx := to_integer(unsigned(lfsr(CNT_WIDTH-1 DOWNTO 0))) mod (i_count + 1);

          -- Swap bits at i_count and j_idx
          temp_bit := pattern_reg(i_count);
          pattern_reg(i_count) <= pattern_reg(j_idx);
          pattern_reg(j_idx)   <= temp_bit;

          if i_count = 0 then
            if shuffle_pass < MAX_PASSES - 1 then
              shuffle_pass <= shuffle_pass + 1;
              i_count <= LED_COUNT - 1;
            else
              state <= done_state;
            end if;
          else
            i_count <= i_count - 1;
          end if;

        when done_state =>
          done_int <= '1';
          if enable = '0' then
            state <= idle;
          end if;

      end case;
    end if;
  end process;

end architecture Behavioral;