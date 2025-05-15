library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity main is
  generic (
    main_counter_size : integer := 12;
    main_DELAY_CYCLES : integer := 130000000
  );

  port (
    clock : in std_logic;
    reset : in std_logic;
    switches : in std_logic_vector(15 downto 0);
    btn_center : in std_logic;
    btn_right : in std_logic;
    btn_left  : in std_logic;
    btn_up    : in std_logic;
    btn_down  : in std_logic; 
    led : out std_logic_vector(15 downto 0);
    an : out std_logic_vector(7 downto 0);
    ca : out std_logic_vector(7 downto 0)
  );
end entity main;

architecture Behavioral of main is

  signal res_n : std_logic;


  signal pulse_center : std_logic;
  signal pulse_right : std_logic;
  signal pulse_left : std_logic;
  signal pulse_up : std_logic;
  signal pulse_down : std_logic;


  signal enable_patt  : std_logic;
  signal start_compare : std_logic;
  signal pattern       : std_logic_vector(15 downto 0);
  signal done_patt     : std_logic;
  signal level         : std_logic_vector(2 downto 0);
  signal ones_count    : std_logic_vector(3 downto 0);
  signal score         : std_logic_vector(3 downto 0);
  signal score_valid   : std_logic;
  signal turns        : std_logic_vector(3 downto 0);
  signal timer        : std_logic_vector(3 downto 0);
  signal level_up      : std_logic;
  signal repeat_level  : std_logic;
  signal turns_enable  : std_logic; 
  signal timer_enable : std_logic;
  signal timer_expired : std_logic;
  signal led_mode      : std_logic_vector(1 downto 0);
  signal state_out_s : std_logic_vector(4 downto 0);

  -- Binary to BCD
  signal zero_bcd : std_logic_vector(3 downto 0) := "0000";

  signal busy_score  : std_logic;
  signal busy_level  : std_logic;
  signal bcd_score   : std_logic_vector(7 downto 0);
  signal bcd_level   : std_logic_vector(7 downto 0);
  signal busy_turns  : std_logic;
  signal bcd_turns  : std_logic_vector(7 downto 0);
  signal bcd_timer    : std_logic_vector(7 downto 0);
  signal busy_timer  : std_logic;


  signal all_switches_down_s : std_logic;

  signal extended_level : std_logic_vector(3 downto 0);
  signal turns_display : std_logic_vector(3 downto 0);
  signal timer_display : std_logic_vector(3 downto 0);

  

  signal score_valid_prev : std_logic := '0';

  signal bcd_score_ena : std_logic := '0';
  signal bcd_level_ena : std_logic := '0';
  signal bcd_turns_ena : std_logic := '0';
  signal bcd_timer_ena : std_logic := '0';

  signal wave_pattern : std_logic_vector(15 downto 0) := "0000000000001111";
  signal wave_counter : integer range 0 to 10000000 := 0; 
  
  
  signal left_btn_hold      : integer range 0 to main_DELAY_CYCLES := 0;


begin

  all_switches_down_s <= not (switches(0) or switches(1) or switches(2) or switches(3) or 
                              switches(4) or switches(5) or switches(6) or switches(7) or 
                              switches(8) or switches(9) or switches(10) or switches(11) or
                              switches(12) or switches(13) or switches(14) or switches(15));

  extended_level<= "0" & level;
  
  res_n <= '1' when (reset = '0' or left_btn_hold >= main_DELAY_CYCLES) ELSE '0';
  
  turns_display <= turns when turns_enable = '1' else zero_bcd;
  timer_display <= timer when timer_enable = '1' else zero_bcd;


process(clock)
begin
  if rising_edge(clock) then
    score_valid_prev <= score_valid;
    
    bcd_level_ena <= not busy_level;
    bcd_turns_ena <= not busy_turns;
    bcd_timer_ena <= not busy_timer;
    
    if score_valid = '1' and score_valid_prev = '0' then
      bcd_score_ena <= '1';
    else
      bcd_score_ena <= '0';
    end if;
    
    
    --left btn
    if btn_left = '1' then
       if left_btn_hold < main_DELAY_CYCLES then
          left_btn_hold <= left_btn_hold + 1;
       end if;
    else
       left_btn_hold <= 0;
    end if;


    if led_mode = "11" then
      if wave_counter = 10000000 then 
          wave_counter <= 0;
          wave_pattern <= wave_pattern(14 downto 0) & wave_pattern(15);
      else
          wave_counter <= wave_counter + 1;
      end if;
      else
          wave_counter <= 0;
          wave_pattern <= "0000000000001111";
      end if;
    end if;


end process;

  -- Debouncers
  debouncer_center : entity work.debouncer
    generic map (counter_size => main_counter_size)
    port map (
      clock => clock,
      reset => res_n,
      bouncy => btn_center,
      pulse => pulse_center
    );

  debouncer_up : entity work.debouncer
    generic map (counter_size => main_counter_size)
    port map (
      clock => clock,
      reset => res_n,
      bouncy => btn_up,
      pulse => pulse_up
    );

  debouncer_left : entity work.debouncer
    generic map (counter_size => main_counter_size)
    port map (
      clock => clock,
      reset => res_n,
      bouncy => btn_left,
      pulse => pulse_left
    );
    
  debouncer_right  : entity work.debouncer
    generic map (counter_size => main_counter_size)
    port map (
      clock => clock,
      reset => res_n,
      bouncy => btn_right,
      pulse => pulse_right
    );

  debouncer_down : entity work.debouncer
    generic map (counter_size => main_counter_size)
    port map (
      clock => clock,
      reset => res_n,
      bouncy => btn_down,
      pulse => pulse_down
    );
  

  -- Pattern Generator
  pattern_generator_inst : entity work.pattern_generator
    port map (
      clk => clock,
      reset => res_n,
      enable => enable_patt,
      ones_count => ones_count,
      pattern => pattern,
      done => done_patt
    );

  -- Datapath
  datapath_inst : entity work.datapath
    port map (
      clk => clock,
      reset => res_n,
      start_compare => start_compare,
      level => level,
      pattern_in => pattern,
      switches => switches,
      score => score,
      turns => turns,
      timer => timer,
      timer_enable => timer_enable,
      score_valid => score_valid,
      level_up => level_up,
      timer_expired => timer_expired,
      repeat_level => repeat_level
    );

  -- Control Unit
  control_unit_inst : entity work.control_unit
    generic map (
      DELAY_CYCLES => main_DELAY_CYCLES
    )
    port map (
      clk => clock,
      reset => res_n,
      center_btn => pulse_center,
      right_btn  => pulse_right,       
      left_btn   => pulse_left,       
      up_btn     => pulse_up,
      down_btn   => pulse_down, 
      done_patt => done_patt,
      score_valid => score_valid,
      level_up => level_up,
      repeat_level => repeat_level,
      all_switches_down => all_switches_down_s,
      level => level,
      ones_count => ones_count,
      enable_patt => enable_patt,
      start_compare => start_compare,
      turns_enable => turns_enable,
      timer_enable => timer_enable,
      timer_expired => timer_expired,
      led_mode => led_mode,
      state_out => state_out_s
    );

  -- Binary to BCD for score
  bcd_score_inst : entity work.binary_to_bcd
    generic map (bits => 4, digits => 2)
    port map (
      clk => clock,
      reset => res_n,
      ena => bcd_score_ena,
      binary => score,
      busy => busy_score,
      bcd => bcd_score
    );

  -- Binary to BCD for level
  bcd_level_inst : entity work.binary_to_bcd
    generic map (bits => 4, digits => 2)
    port map (
      clk => clock,
      reset => res_n,
      ena => bcd_level_ena,
      binary => extended_level,
      busy => busy_level,
      bcd => bcd_level
    );

  -- Binary to BCD for turns
  bcd_turns_inst : entity work.binary_to_bcd
    generic map (bits => 4, digits => 2)
    port map (
      clk => clock,
      reset => res_n,
      ena => bcd_turns_ena,
      binary => turns_display,
      busy => busy_turns,
      bcd => bcd_turns
    );

  -- Binary to BCD for timer
  bcd_timer_inst : entity work.binary_to_bcd
    generic map (bits => 4, digits => 2)
    port map (
      clk => clock,
      reset => res_n,
      ena => bcd_timer_ena,
      binary => timer_display,
      busy => busy_timer,
      bcd => bcd_timer
    );

  -- Seven Segment Driver
  seven_segment_driver_inst : entity work.seven_segment_driver
    generic map (size => 20)
    port map (
      clock => clock,
      reset => res_n,
      digit0 => bcd_score(3 downto 0),
      digit1 => bcd_score(7 downto 4),
      digit2 => bcd_level(3 downto 0),
      digit3 => bcd_level(7 downto 4),
      digit4 => bcd_turns(3 downto 0),
      digit5 => bcd_turns(7 downto 4),
      digit6 => bcd_timer(3 downto 0),
      digit7 => bcd_timer(7 downto 4),
      ca => ca,
      an => an
      );

  -- LED control
  led <=
  (others => '0')         when led_mode = "00" else
  pattern                 when led_mode = "01" else
  (others => '1')         when led_mode = "10" else
  wave_pattern;           -- when led_mode = "11"

end Behavioral;