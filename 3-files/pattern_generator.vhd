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

  -- FSM states
  type state_type is (idle, load, shuffle, done_state);
  signal state       : state_type := idle;
  

  signal shuffle_pass : integer range 0 to 3 := 0;
  constant MAX_PASSES : integer := 2; -- fai 2 shuffle pass


  -- registro del pattern
  signal pattern_reg : std_logic_vector(LED_COUNT-1 DOWNTO 0) := (others => '0');
  -- LFSR per generazione numeri casuali
  signal lfsr        : std_logic_vector(LED_COUNT-1 DOWNTO 0) := (others => '1');
  -- contatore per lo shuffle (da LED_COUNT-1 downto 1)
  signal i_count     : integer range 0 to LED_COUNT-1 := 0;
  -- numero di 1 da inserire
  signal target_cnt  : integer range 0 to LED_COUNT := 0;
  -- flag interno di “done”
  signal done_int    : std_logic := '0';

begin

  -- esponi output
  pattern <= pattern_reg;
  done    <= done_int;

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
            -- cattura quanti 1 voglio (clamp a 0..LED_COUNT)
            if unsigned(ones_count) > LED_COUNT then
                target_cnt <= LED_COUNT;
              else
                target_cnt <= to_integer(unsigned(ones_count));
              end if;
            state      <= load;
          end if;

        when load =>
          -- carica inizialmente i primi target_cnt bit a '1', il resto a '0'
          for idx in 0 to LED_COUNT-1 loop
            if idx < target_cnt then
              pattern_reg(idx) <= '1';
            else
              pattern_reg(idx) <= '0';
            end if;
          end loop;
          i_count <= LED_COUNT - 1;
          state   <= shuffle;
          shuffle_pass <= 0;



        when shuffle =>
          -- aggiorna LFSR (x^16 + x^14 + 1) come esempio
          lfsr <= lfsr(LED_COUNT-2 DOWNTO 0) & (lfsr(LED_COUNT-1) XOR lfsr(LED_COUNT-3));

          -- scegli indice j tra 0 e i_count (inclusi)
          j_idx := to_integer(unsigned(lfsr(CNT_WIDTH-1 DOWNTO 0))) mod (i_count + 1);

          -- esegui swap tra posizione i_count e j_idx
          temp_bit               := pattern_reg(i_count);
          pattern_reg(i_count)   <= pattern_reg(j_idx);
          pattern_reg(j_idx)     <= temp_bit;

          -- check i_count && shuffle pass 
          if i_count = 0 then
            if shuffle_pass < MAX_PASSES - 1 then
              -- fai un altro giro di shuffle
              shuffle_pass <= shuffle_pass + 1;
              i_count      <= LED_COUNT - 1;
            else
              -- tutti i passaggi completati
              state <= done_state;
            end if;
          else
            i_count <= i_count - 1;
          end if;
          

        when done_state =>
          done_int <= '1';
          -- aspetta che enable torni a zero per nuovo trigger
          if enable = '0' then
            state <= idle;
          end if;

      end case;
    end if;
  end process;

end architecture Behavioral;
