library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity binary_to_bcd is
  generic (
    bits   : integer := 8;
    digits : integer := 3
  );
  port (
    clk     : in  std_logic;
    reset   : in  std_logic;
    ena     : in  std_logic;
    binary  : in  std_logic_vector(bits-1 downto 0);
    busy    : out std_logic;
    bcd     : out std_logic_vector(digits*4-1 downto 0)
  );
end entity;

architecture Behavioral of binary_to_bcd is
  type state_type is (idle, convert);
  signal state       : state_type := idle;
  signal binary_reg  : std_logic_vector(bits-1 downto 0);
  signal bcd_reg     : std_logic_vector(digits*4-1 downto 0);
  signal bit_count   : integer range 0 to bits := 0;
begin

  process(clk, reset)
  begin
    if reset = '1' then
      state <= idle;
      binary_reg <= (others => '0');
      bcd_reg <= (others => '0');
      bit_count <= 0;
      busy <= '0';
      bcd <= (others => '0');
    elsif rising_edge(clk) then
      case state is
        when idle =>
          busy <= '0';
          if ena = '1' then
            binary_reg <= binary;
            bcd_reg <= (others => '0');
            bit_count <= 0;
            state <= convert;
            busy <= '1';
          end if;

        when convert =>
          for i in 0 to digits-1 loop
            if unsigned(bcd_reg(i*4+3 downto i*4)) >= 5 then
              bcd_reg(i*4+3 downto i*4) <= std_logic_vector(unsigned(bcd_reg(i*4+3 downto i*4)) + 3);
            end if;
          end loop;

          bcd_reg <= bcd_reg(digits*4-2 downto 0) & binary_reg(bits-1);
          binary_reg <= binary_reg(bits-2 downto 0) & '0';

          bit_count <= bit_count + 1;
          if bit_count = bits-1 then
            state <= idle;
            busy <= '0';
            bcd <= bcd_reg(digits*4-2 downto 0) & binary_reg(bits-1);
          end if;
      end case;
    end if;
  end process;

end Behavioral;