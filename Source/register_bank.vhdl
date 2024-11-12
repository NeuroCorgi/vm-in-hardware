library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity register_bank is
  generic (
    bank_size  : integer := 8;
    data_width : integer := 16
  );
  port (
    addr     : in  integer range 0 to bank_size - 1;
    data_in  : in  std_logic_vector(data_width - 1 downto 0);
    data_out : out std_logic_vector(data_width - 1 downto 0);
    we       : in  std_logic;

    rst      : in  std_logic;
    clk      : in  std_logic
  );
end register_bank;

architecture register_bank_arch of register_bank is
  type RegistersT is array (0 to bank_size - 1) of
    std_logic_vector(data_width - 1 downto 0);

  signal registers : RegistersT := (others => (others => '0'));
begin
  process(clk, rst)
  begin
    if rst = '0' then
      registers <= (others => (others => '0'));
    elsif rising_edge(clk) and we = '1' then
      registers(addr) <= data_in;
    end if;
  end process;

  data_out <= registers(addr);
end architecture register_bank_arch;
