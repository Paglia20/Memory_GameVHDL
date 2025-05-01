library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity main is
  generic (
    main_counter_size : integer := 12;
    main_DELAY_CYCLES : integer := 100000000;
    main_blink_value : integer := 100000000
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
end entity main;

architecture Behavioral of main is

  signal pulse_center : std_logic;
  signal enable_patt  : std_logic;
  signal start_compare : std_logic;
  signal pattern       : std_logic_vector(15 downto 0);
  signal done_patt     : std_logic;
  signal level         : std_logic_vector(1 downto 0);
  signal ones_count    : std_logic_vector(3 downto 0);
  signal score         : std_logic_vector(3 downto 0);
  signal score_valid   : std_logic;
  signal level_up      : std_logic;
  signal repeat_level  : std_logic;
  signal led_mode      : std_logic_vector(1 downto 0);
  signal state_out_s : std_logic_vector(4 downto 0);

  -- Binary to BCD
  signal busy_score  : std_logic;
  signal busy_level  : std_logic;
  signal bcd_score   : std_logic_vector(7 downto 0);
  signal bcd_level   : std_logic_vector(7 downto 0);

  -- All switches down
  signal all_switches_down_s : std_logic;

  -- Extended level
  signal extended_level : std_logic_vector(3 downto 0);

  signal reset_sync : std_logic;


  signal score_valid_prev : std_logic := '0';
  signal level_up_prev : std_logic := '0';

  signal bcd_score_ena : std_logic := '0';
  signal bcd_level_ena : std_logic := '0';
  signal bcd_level_pending:std_logic := '0';

begin
  

  reset_sync <=  reset; 

  all_switches_down_s <= not (switches(0) or switches(1) or switches(2) or switches(3) or 
                              switches(4) or switches(5) or switches(6) or switches(7) or 
                              switches(8) or switches(9) or switches(10) or switches(11) or
                              switches(12) or switches(13) or switches(14) or switches(15));

  extended_level <= "00" & level;


process(clock)
begin
  if rising_edge(clock) then
    score_valid_prev <= score_valid;
    level_up_prev <= level_up;

    -- fronte di salita di level_up
    if level_up = '1' and level_up_prev = '0' then
      if busy_level = '0' then
        bcd_level_ena <= '1';
        bcd_level_pending <= '0';
      else
        bcd_level_ena <= '0';
        bcd_level_pending <= '1';
      end if;
    elsif bcd_level_pending = '1' and busy_level = '0' then
      bcd_level_ena <= '1';
      bcd_level_pending <= '0';
    else
      bcd_level_ena <= '0';
    end if;

    
    if score_valid = '1' and score_valid_prev = '0' then
      bcd_score_ena <= '1';
    else
      bcd_score_ena <= '0';
    end if;
  end if;
end process;

  -- Debouncer
  debouncer_inst : entity work.debouncer
    generic map (counter_size => main_counter_size)
    port map (
      clock => clock,
      reset => reset_sync,
      bouncy => btn_center,
      pulse => pulse_center
    );

  -- Pattern Generator
  pattern_generator_inst : entity work.pattern_generator
    port map (
      clk => clock,
      reset => reset_sync,
      enable => enable_patt,
      ones_count => ones_count,
      pattern => pattern,
      done => done_patt
    );

  -- Datapath
  datapath_inst : entity work.datapath
    port map (
      clk => clock,
      reset => reset_sync,
      start_compare => start_compare,
      level => level,
      pattern_in => pattern,
      switches => switches,
      score => score,
      score_valid => score_valid,
      level_up => level_up,
      repeat_level => repeat_level
    );

  -- Control Unit
  control_unit_inst : entity work.control_unit
    generic map (
      DELAY_CYCLES => main_DELAY_CYCLES,
      blink_value  => main_blink_value
    )
    port map (
      clk => clock,
      reset => reset_sync,
      center_btn => pulse_center,
      done_patt => done_patt,
      score_valid => score_valid,
      level_up => level_up,
      repeat_level => repeat_level,
      all_switches_down => all_switches_down_s,
      level => level,
      ones_count => ones_count,
      enable_patt => enable_patt,
      start_compare => start_compare,
      led_mode => led_mode,
      state_out => state_out_s
    );

  -- Binary to BCD for score
  bcd_score_inst : entity work.binary_to_bcd
    generic map (bits => 4, digits => 2)
    port map (
      clk => clock,
      reset => reset_sync,
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
      reset => reset_sync,
      ena => bcd_level_ena,
      binary => extended_level,
      busy => busy_level,
      bcd => bcd_level
    );

  -- Seven Segment Driver
  seven_segment_driver_inst : entity work.seven_segment_driver
    generic map (size => 20)
    port map (
      clock => clock,
      reset => reset_sync,
      digit0 => bcd_score(3 downto 0),
      digit1 => bcd_score(7 downto 4),
      digit2 => bcd_level(3 downto 0),
      digit3 => bcd_level(7 downto 4),
      ca => ca,
      an => an
    );

  -- LED control
  led <= 
    (others => '0') when led_mode = "00" else
    pattern when led_mode = "10" else
    (others => '1');

end Behavioral;