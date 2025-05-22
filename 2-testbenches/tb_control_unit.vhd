library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_control_unit is
end tb_control_unit;

architecture behavior of tb_control_unit is

  component control_unit
    generic (
      DELAY_CYCLES : integer := 5
    );
    port (
      clk               : in  std_logic;
      reset             : in  std_logic;
      center_btn        : in  std_logic;
      done_patt         : in  std_logic;
      score_valid       : in  std_logic;
      level_up          : in  std_logic;
      repeat_level      : in  std_logic;
      all_switches_down : in  std_logic;

      level             : out std_logic_vector(1 downto 0);
      ones_count        : out std_logic_vector(3 downto 0);
      enable_patt       : out std_logic;
      start_compare     : out std_logic;
      led_mode          : out std_logic_vector(1 downto 0);
      state_out         : out std_logic_vector(4 downto 0)
    );
  end component;

  signal clk_tb               : std_logic := '0';
  signal reset_tb             : std_logic := '1';
  signal center_btn_tb        : std_logic := '0';
  signal done_patt_tb         : std_logic := '0';
  signal score_valid_tb       : std_logic := '0';
  signal level_up_tb          : std_logic := '0';
  signal repeat_level_tb      : std_logic := '0';
  signal all_switches_down_tb : std_logic := '0';

  signal level_tb             : std_logic_vector(1 downto 0);
  signal ones_count_tb        : std_logic_vector(3 downto 0);
  signal enable_patt_tb       : std_logic;
  signal start_compare_tb     : std_logic;
  signal led_mode_tb          : std_logic_vector(1 downto 0);
  signal state_out_tb         : std_logic_vector(4 downto 0);

  constant clk_period : time := 10 ns;

begin

  -- Clock generator
  clk_process : process
  begin
    loop
      clk_tb <= '0'; wait for clk_period / 2;
      clk_tb <= '1'; wait for clk_period / 2;
    end loop;
  end process;

  uut: control_unit
    generic map (
      DELAY_CYCLES => 5
    )
    port map (
      clk                => clk_tb,
      reset              => reset_tb,
      center_btn         => center_btn_tb,
      done_patt          => done_patt_tb,
      score_valid        => score_valid_tb,
      level_up           => level_up_tb,
      repeat_level       => repeat_level_tb,
      all_switches_down  => all_switches_down_tb,
      level              => level_tb,
      ones_count         => ones_count_tb,
      enable_patt        => enable_patt_tb,
      start_compare      => start_compare_tb,
      led_mode           => led_mode_tb,
      state_out          => state_out_tb
    );

    stim_proc : process
    begin
        -- Reset
        reset_tb <= '1';
        wait for 20 ns;
        reset_tb <= '0';
        wait for 20 ns;
    

        center_btn_tb <= '1';
        wait for clk_period;
        center_btn_tb <= '0';
    

        wait until enable_patt_tb = '1';
        wait for clk_period;
    

        done_patt_tb <= '1';
        wait for clk_period;
        done_patt_tb <= '0';
    
        -- Attesa per simulare player pronto
        wait for 50 ns;
        center_btn_tb <= '1';
        wait for 2*clk_period;
        center_btn_tb <= '0';
    

        wait until start_compare_tb = '1';
        wait for clk_period;
        score_valid_tb <= '1';

        -- Level Up Check         **(happens while score_valid is true in datapath)**

         level_up_tb <= '1';
         wait for 2*clk_period; 
         level_up_tb <= '0';


        --  Repeat Level Check

        -- repeat_level_tb <= '1';
        -- wait for 2*clk_period; -- almeno 2 clock! 
        -- repeat_level_tb <= '0';


        score_valid_tb <= '0';
    

        wait for 30 ns;
        all_switches_down_tb <= '1';
        wait for 3 * clk_period;
        all_switches_down_tb <= '0';
  
    
        -- Fine test
        wait until state_out_tb = "00001";
        report "Test completato. Finito primo livello";
        assert false report "Fine simulazione." severity failure;
    end process;

  -- Timeout per evitare loop infiniti
  end_sim_proc : process
  begin
    wait for 700 ns;
    assert false report "Timeout raggiunto (700ns). Simulazione interrotta." severity failure;
  end process;

  
  monitor_state_proc : process(clk_tb)
begin
  if rising_edge(clk_tb) then
    case to_integer(unsigned(state_out_tb)) is
      when 0 => report "Stato: idle";
      when 1 => report "Stato: blink_all";
      when 2 => report "Stato: generate_pattern";
      when 3 => report "Stato: wait_pattern_done";
      when 4 => report "Stato: show_pattern_once";
      when 5 => report "Stato: wait_for_btn_eval";
      when 6 => report "Stato: show_pattern_again";
      when 7 => report "Stato: wait_score";
      when 8 => report "Stato: wait_switches_down";
      when 9 => report "Stato: delay_after_clear";
      when 10 => report "Stato: check_score";
      when 11 => report "Stato: next_level";
      when others => report "Stato: sconosciuto!";
    end case;
  end if;
end process;

end behavior;
