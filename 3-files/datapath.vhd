library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity datapath is
  port (
    clk          : in  std_logic;
    reset        : in  std_logic;
    start_compare: in  std_logic;  -- segnale per iniziare confronto
    level        : in  std_logic_vector(1 downto 0); -- 2-bit: 00=liv1, 01=liv2, 10=liv3
    pattern_in   : in  std_logic_vector(15 downto 0);
    switches     : in  std_logic_vector(15 downto 0);
    score        : out std_logic_vector(3 downto 0);
    score_valid  : out std_logic;  -- 1 clock dopo il confronto
    level_up     : out std_logic;
    repeat_level : out std_logic
  );
end datapath;

architecture Behavioral of datapath is

  type state_type is (idle, compare, done);
  signal state         : state_type := idle;

  signal pattern_reg   : std_logic_vector(15 downto 0) := (others => '0');
  signal switches_reg  : std_logic_vector(15 downto 0) := (others => '0');
  signal score_reg     : integer range 0 to 15 := 0;
  signal temp_score    : integer range -16 to 32 := 0;
  signal bit_index     : integer range 0 to 15 := 0;
  signal level_up_int  : std_logic := '0';
  signal repeat_level_int : std_logic := '0';
  signal score_valid_int  : std_logic := '0';

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
           -- score_reg    <= 0;
            state        <= compare;
          end if;

        when compare =>
          -- confronto singolo bit per ciclo
          if pattern_reg(bit_index) = '1' and switches_reg(bit_index) = '1' then
            temp_score <= temp_score + 1;
          elsif pattern_reg(bit_index) = '0' and switches_reg(bit_index) = '1' then
            temp_score <= temp_score - 1;
          elsif pattern_reg(bit_index) = '1' and switches_reg(bit_index) = '0' and level = "10" then -- livello 3
            temp_score <= temp_score - 1;
          end if;

          if bit_index = 15 then
            state <= done;
          else
            bit_index <= bit_index + 1;
          end if;

          when done =>
            new_score := score_reg + temp_score;

            -- clamp e aggiornamento
            if new_score < 0 then
              score_reg <= 0;
              level_up_int <= '0';
              repeat_level_int <= '1';
            elsif new_score >= 16 then
              score_reg <= 15;
              level_up_int <= '1';
              score_reg    <= 0;
              repeat_level_int <= '0';
            else
              score_reg <= new_score;
              level_up_int <= '0';
              repeat_level_int <= '1';
            end if;

            score_valid_int <= '1';
            state <= idle;
      end case;
    end if;
  end process;

  score <= std_logic_vector(to_unsigned(score_reg, 4));
  score_valid <= score_valid_int;
  level_up <= level_up_int;
  repeat_level <= repeat_level_int;

end Behavioral;
