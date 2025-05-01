library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control_unit is
  generic (
    DELAY_CYCLES : integer := 100000000;
    blink_value : integer := 6
  );
  port (
    clk                : in  std_logic;
    reset              : in  std_logic;
    center_btn         : in  std_logic;
    done_patt          : in  std_logic;
    score_valid        : in  std_logic;
    level_up           : in  std_logic;
    repeat_level       : in  std_logic;
    all_switches_down  : in  std_logic;
    level              : out std_logic_vector(1 downto 0);
    ones_count         : out std_logic_vector(3 downto 0);
    enable_patt        : out std_logic;
    start_compare      : out std_logic;
    led_mode           : out std_logic_vector(1 downto 0); -- "00"=OFF, "01"=BLINK, "10"=SHOW
    state_out          : out std_logic_vector(4 downto 0) -- For debugging
  );
end control_unit;

architecture Behavioral of control_unit is

  type state_type is (
    idle, blink_all, generate_pattern, wait_pattern_done,
    show_pattern_once, wait_for_btn_eval, show_pattern_again,
    wait_score, wait_switches_down, delay_after_clear,
    check_score, next_level, end_state
  );

  signal state              : state_type := idle;
  signal next_state         : state_type;
  signal level_reg          : std_logic_vector(1 downto 0) := "00";
  signal delay_counter      : integer range 0 to DELAY_CYCLES := 0;
  signal blink_counter      : integer range 0 to blink_value := 0;
  signal ones_count_reg     : std_logic_vector(3 downto 0) := (others => '0');
  signal level_up_reg       : std_logic := '0';
  signal repeat_level_reg   : std_logic := '0';
  signal switches_down_reg  : std_logic := '0';
  signal score_valid_reg    : std_logic := '0';

begin

  -- Synchronous process
  process(clk, reset)
  begin
    if reset = '1' then
      state <= idle;
      level_reg <= "00";
      delay_counter <= 0;
      blink_counter <= 0;
      ones_count_reg <= (others => '0');
      level_up_reg <= '0';
      repeat_level_reg <= '0';
      switches_down_reg <= '0';
      score_valid_reg <= '0';

    elsif rising_edge(clk) then
      state <= next_state;

      -- Capture signals
      if state = wait_score and score_valid = '1' then
        level_up_reg <= level_up;
        repeat_level_reg <= repeat_level;
        score_valid_reg <= '1';

        -- Sicurezza extra
        if (level_up = '1' and repeat_level = '1') then
          assert false report "Errore: sia level_up che repeat_level sono alti contemporaneamente!" severity failure;
        elsif (level_up = '0' and repeat_level = '0') then
          assert false report "Errore: né level_up né repeat_level sono alti con score_valid=1!" severity failure;

        end if;

      end if;


      if state = check_score and next_state /= check_score then
        score_valid_reg <= '0';
        level_up_reg <= '0';
        repeat_level_reg <= '0';
      end if;
        
      switches_down_reg <= all_switches_down;


      -- Delay counter
      if state = show_pattern_once or state = delay_after_clear then
        if delay_counter < DELAY_CYCLES then
          delay_counter <= delay_counter + 1;
        end if;
      else
        delay_counter <= 0;
      end if;

      -- Blink counter
      if state = blink_all then
        if blink_counter < blink_value then
          blink_counter <= blink_counter + 1;
        end if;
      else
        blink_counter <= 0;
      end if;

      -- Update level
      if state = check_score and level_up_reg = '1' then
        if level_reg < "10" then
          level_reg <= std_logic_vector(unsigned(level_reg) + 1);
        end if;
      end if;

      -- Update ones_count
      if state = blink_all then
        if level_reg = "00" then
          ones_count_reg <= "0110"; -- 6
        else
          ones_count_reg <= "1000"; -- 8
        end if;
      end if;
    end if;
  end process;

  -- FSM process
  process(state, center_btn, done_patt, score_valid_reg, level_up_reg, switches_down_reg, delay_counter, blink_counter, repeat_level_reg)
  begin
    next_state     <= state;
    enable_patt    <= '0';
    start_compare  <= '0';
    led_mode       <= "00";

    case state is
      when idle =>
        if center_btn = '1' then
          next_state <= blink_all after 1 ns;
        end if;

      when blink_all =>
        led_mode <= "01";
        if blink_counter = blink_value then
          next_state <= generate_pattern;
        end if;

      when generate_pattern =>
        enable_patt <= '1';
        next_state <= wait_pattern_done;

      when wait_pattern_done =>
        if done_patt = '1' then
          next_state <= show_pattern_once;
        end if;

      when show_pattern_once =>
        led_mode <= "10";
        if delay_counter >= DELAY_CYCLES then
          next_state <= wait_for_btn_eval;
        end if;

      when wait_for_btn_eval =>
        led_mode <= "00";
        if center_btn = '1' then
          next_state <= show_pattern_again;
        end if;

      when show_pattern_again =>
        led_mode <= "10";
        start_compare <= '1';
        next_state <= wait_score;

      when wait_score =>
        led_mode <= "10";
        if score_valid = '1' then
          next_state <= wait_switches_down;
        end if;

      when wait_switches_down =>
        led_mode <= "10";
        if switches_down_reg = '1' then
          led_mode <= "00";
          next_state <= delay_after_clear;
        end if;

      when delay_after_clear =>
        if delay_counter >= DELAY_CYCLES then
          next_state <= check_score;
        end if;

      when check_score =>
         if level_reg = "10" and level_up_reg = '1' then
           next_state <= end_state;
          elsif level_up_reg = '1' then
            next_state <= next_level;
          elsif repeat_level_reg = '1' then
            next_state <= generate_pattern;
          end if;

      when next_level =>
        next_state <= blink_all;
        
      when end_state =>
       led_mode <= "01";
    end case;
  end process;

  -- Output mapping
  level <= level_reg;
  ones_count <= ones_count_reg;
  state_out <= std_logic_vector(to_unsigned(state_type'pos(state), 5));

end Behavioral;