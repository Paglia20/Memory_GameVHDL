library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity datapath is
  generic (
    DELAY_CYCLES : integer := 100000000
  );
  port (
    clk          : in  std_logic;
    reset        : in  std_logic;
    start_compare: in  std_logic;  
    level        : in  std_logic_vector(2 downto 0); -- 2-bit: 00=liv1, 01=liv2, 10=liv3, 011 = LVL4, 100= LVL5
    pattern_in   : in  std_logic_vector(15 downto 0);
    switches     : in  std_logic_vector(15 downto 0);
    timer_enable : in  std_logic; 
    score        : out std_logic_vector(3 downto 0);
    score_valid  : out std_logic;  
    turns        : out std_logic_vector(3 downto 0);
    timer        : out std_logic_vector(3 downto 0);
    level_up     : out std_logic;
    timer_expired : out std_logic;
    repeat_level : out std_logic
  );
end datapath;

architecture Behavioral of datapath is

  type state_type is (idle, compare, score_calculated, done);
  signal state         : state_type := idle;

  signal pattern_reg   : std_logic_vector(15 downto 0) := (others => '0');
  signal switches_reg  : std_logic_vector(15 downto 0) := (others => '0');
  signal score_reg     : integer range 0 to 15 := 0;
  signal turns_reg     : integer := 0;
  signal temp_score    : integer range -16 to 32 := 0;
  signal bit_index     : integer range 0 to 15 := 0;
  signal level_up_int  : std_logic := '0';
  signal repeat_level_int : std_logic := '0';
  signal score_valid_int  : std_logic := '0';
  signal timer_reg      : integer range 0 to 10 := 0;
  signal delay_counter  : integer range 0 to DELAY_CYCLES := 0;
  signal timer_expired_int : std_logic := '0';

begin

  process(clk, reset)
  variable new_score : integer range -16 to 32;


  begin
    if reset = '1' then
      state        <= idle;
      score_reg    <= 0;
      score_valid_int  <= '0';
      pattern_reg  <= (others => '0');
      switches_reg <= (others => '0');
      bit_index    <= 0;
      temp_score   <= 0;
      level_up_int <= '0';
      repeat_level_int <= '0';

    elsif rising_edge(clk) then
      case state is

        when idle =>
          score_valid_int <= '0';
          level_up_int <= '0';
          repeat_level_int <= '0';

          if start_compare = '1' then
            pattern_reg  <= pattern_in;
            switches_reg <= switches;
            bit_index    <= 0;
            temp_score   <= 0;
            state        <= compare;
          end if;


        when compare =>
          if pattern_reg(bit_index) = '1' and switches_reg(bit_index) = '1' then
            temp_score <= temp_score + 1;
          elsif pattern_reg(bit_index) = '0' and switches_reg(bit_index) = '1' then
            temp_score <= temp_score - 1;
          elsif pattern_reg(bit_index) = '1' and switches_reg(bit_index) = '0' and level = "010" then -- livello 3
            temp_score <= temp_score - 1;
          end if;

          if bit_index = 15 then
            state <= score_calculated;
          else
            bit_index <= bit_index + 1;
          end if;
              
        when score_calculated =>
          state <= done;

        when done =>
            new_score := score_reg + temp_score;

            if new_score < 0 then
              score_reg <= 0;
              level_up_int <= '0';
              repeat_level_int <= '1';
            elsif new_score >= 5 then --16
              level_up_int <= '1';
              repeat_level_int <= '0';
              score_reg    <= 0;
              turns_reg    <= 0;
            else
              score_reg <= new_score;
              if turns_reg < 5 then    --16
                turns_reg <= turns_reg + 1;
              end if;
              level_up_int <= '0';
              repeat_level_int <= '1';
            end if;

            score_valid_int <= '1';
            state <= idle;
      end case;

      -- Countdown timer logic
      if timer_enable = '1' then
        if timer_reg = 0 then
          timer_expired_int <= '0';
        elsif delay_counter = DELAY_CYCLES then
          delay_counter <= 0;
          timer_reg <= timer_reg - 1;
        
          if timer_reg = 1 then
            timer_expired_int <= '1';  -- Will be 0 in next cycle
          else
            timer_expired_int <= '0';
          end if;
          
        else
          delay_counter <= delay_counter + 1;
          timer_expired_int <= '0';
        end if;
          
      else
        if level = "011" then 
        timer_reg <= 10;        
        else 
        timer_reg <= 5;
        end if;
        delay_counter <= 0;
        timer_expired_int <= '0';
      end if;
    end if;
  end process;

  score <= std_logic_vector(to_unsigned(score_reg, 4));
  turns <= std_logic_vector(to_unsigned(turns_reg, 4));
  score_valid <= score_valid_int;
  level_up <= level_up_int;
  repeat_level <= repeat_level_int;
  timer <= std_logic_vector(to_unsigned(timer_reg, 4));
  timer_expired <= timer_expired_int;

end Behavioral;