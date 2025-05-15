library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control_unit is
  generic (
    DELAY_CYCLES : integer := 100000000
  );
  port (
    clk                : in  std_logic;
    reset              : in  std_logic;
    center_btn         : in  std_logic;
    right_btn          : in  std_logic;
    left_btn           : in  std_logic;
    up_btn             : in  std_logic;
    down_btn           : in  std_logic;
    done_patt          : in  std_logic;
    score_valid        : in  std_logic;
    level_up           : in  std_logic;
    repeat_level       : in  std_logic;
    all_switches_down  : in  std_logic;
    timer_expired      : in  std_logic;
    level              : out std_logic_vector(2 downto 0); 
    ones_count         : out std_logic_vector(3 downto 0);
    enable_patt        : out std_logic;
    start_compare      : out std_logic;
    turns_enable       : out std_logic;
    timer_enable       : out std_logic;
    led_mode           : out std_logic_vector(1 downto 0); -- "00"=OFF, "01"=PATTERN, "10"=ALL ON, "11"=WIN
    state_out          : out std_logic_vector(4 downto 0)
  );
end control_unit;

architecture Behavioral of control_unit is

  type state_type is (
    idle, blink_all, generate_pattern, wait_pattern_done,
    show_pattern_once, wait_for_btn_eval, wait_score,
    wait_switches_down, menu_actions, delay_after_clear,
    check_score, next_level, end_state
  );

  signal state              : state_type := idle;
  signal next_state         : state_type;
  signal level_reg          : std_logic_vector(2 downto 0) := (others => '0'); 
  signal delay_counter      : integer range 0 to DELAY_CYCLES := 0;
  signal ones_count_reg     : std_logic_vector(3 downto 0) := (others => '0');
  signal level_up_reg       : std_logic := '0';
  signal repeat_level_reg   : std_logic := '0';
  signal switches_down_reg  : std_logic := '0';
  signal score_valid_reg    : std_logic := '0';
  signal turn_count         : integer range 0 to 15 := 0;
  signal show_pattern_flag  : std_logic := '0';
  signal show_turns_flag    : std_logic := '0';

begin

  process(clk, reset)
  begin
    if reset = '1' then
      report "resetting!" severity note; 
      state             <= idle;
      level_reg         <= (others => '0');
      delay_counter     <= 0;
      ones_count_reg    <= (others => '0');
      level_up_reg      <= '0';
      repeat_level_reg  <= '0';
      switches_down_reg <= '0';
      score_valid_reg   <= '0';
      turn_count        <= 0;
      show_pattern_flag <= '0';
      show_turns_flag   <= '0';

    elsif rising_edge(clk) then
      state <= next_state;

      if state = wait_score and score_valid = '1' then
        level_up_reg     <= level_up;
        repeat_level_reg <= repeat_level;
        score_valid_reg  <= '1';

        if level_up = '1' and repeat_level = '1' then
          assert false report "Errore: level_up e repeat_level alti insieme!" severity failure;
        elsif level_up = '0' and repeat_level = '0' then
          assert false report "Errore: entrambi bassi con score_valid!" severity failure;
        end if;
      end if;

      if state = check_score and next_state /= check_score then
        level_up_reg     <= '0';
        repeat_level_reg <= '0';
        score_valid_reg  <= '0';
      end if;

      switches_down_reg <= all_switches_down;

      if state = show_pattern_once or state = delay_after_clear or state = blink_all then
        if delay_counter < DELAY_CYCLES then
          delay_counter <= delay_counter + 1;
        end if;
      else
        delay_counter <= 0;
      end if;

      if state = check_score and level_up_reg = '1' then
        if unsigned(level_reg) < 5 then 
          level_reg <= std_logic_vector(unsigned(level_reg) + 1);
        end if;
      end if;

      if state = check_score and (level_up_reg = '1' or repeat_level_reg = '1') then
        turn_count <= turn_count + 1;
      end if;

      if state = blink_all then
        if level_reg = "000" then
          ones_count_reg <= "0110"; -- 6
        else
          ones_count_reg <= "1000"; -- 8
        end if;
      end if;

      if state = menu_actions then
        if up_btn = '1' then
          show_pattern_flag <= '1';
        elsif down_btn = '1' then
          show_turns_flag <= '1';
        elsif right_btn = '1' then
          show_pattern_flag <= '0';
          show_turns_flag   <= '0';
        end if;
      end if;

      if state = idle and next_state = blink_all then
        turn_count <= 0;
      end if;
    end if;
  end process;

  process(state, center_btn, done_patt, score_valid_reg, level_up_reg,
          switches_down_reg, delay_counter, repeat_level_reg,
          right_btn, show_pattern_flag, show_turns_flag)
  begin
    next_state     <= state;
    enable_patt    <= '0';
    start_compare  <= '0';
    turns_enable   <= '0';
    timer_enable   <= '0';

    led_mode       <= "00"; 

    case state is
      when idle =>
        if center_btn = '1' then
          next_state <= blink_all;
        end if;

      when blink_all =>
        led_mode <= "10"; -- all on
        if delay_counter >= DELAY_CYCLES then
          next_state <= generate_pattern;
        end if;

      when generate_pattern =>
        enable_patt <= '1';
        next_state  <= wait_pattern_done;


      when wait_pattern_done =>
        if done_patt = '1' then
          next_state <= show_pattern_once;
        end if;

      when show_pattern_once =>
        led_mode <= "01"; -- pattern
        if delay_counter >= DELAY_CYCLES then
          next_state <= wait_for_btn_eval;
        end if;

      when wait_for_btn_eval =>
        led_mode <= "00";
        if level_reg = "100" or level_reg = "011" then
          timer_enable <= '1';
        end if;

        if center_btn = '1' or timer_expired = '1' then
          timer_enable <= '0';
          start_compare <= '1';
          next_state    <= wait_score;
        end if;

      when wait_score =>
        if score_valid_reg = '1' then
          next_state <= wait_switches_down;
        end if;

      when wait_switches_down =>
        led_mode <= "10";
        if switches_down_reg = '1' then
          next_state <= menu_actions;
        end if;

      when menu_actions =>
        if show_pattern_flag = '1' then
          led_mode <= "01";
        elsif show_turns_flag = '1' then
          turns_enable <= '1';
        else
          led_mode <= "00";
        end if;
       
        if right_btn = '1' then
          next_state <= delay_after_clear;
        end if;

      when delay_after_clear =>
        if delay_counter >= DELAY_CYCLES then
          next_state <= check_score;
        end if;

      when check_score =>
        if level_reg = "100" and level_up_reg = '1' then
          next_state <= end_state;
        elsif level_up_reg = '1' then
          next_state <= next_level;
        elsif repeat_level_reg = '1' then
          next_state <= generate_pattern;
        end if;

      when next_level =>
        next_state <= blink_all;

      when end_state =>
        led_mode <= "11";
        report "Game completed!" severity note; 
    end case;
  end process;

  level      <= level_reg;
  ones_count <= ones_count_reg;
  state_out  <= std_logic_vector(to_unsigned(state_type'pos(state), 5));


end Behavioral;