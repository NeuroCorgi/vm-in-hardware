library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library src;
use src.memory;

entity memory_tb is
end entity memory_tb;

architecture testbench of memory_tb is
  constant ADDR_WIDTH : Integer := 4;
  constant DATA_WIDTH : Integer := 16;

  signal clk : std_logic := '0';
  signal rst : std_logic := '0';
  signal we  : std_logic := '0';

  signal address  : integer := 0;
  signal data_in  : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal data_out : std_logic_vector(DATA_WIDTH - 1 downto 0);

  component memory
    generic (
      file_name  : String;
      addr_width : Integer;
      data_width : Integer
    );
    port (
      address  : in  integer range 0 to 2 ** addr_width - 1;
      data_in  : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
      data_out : out std_logic_vector(DATA_WIDTH - 1 downto 0);
      we       : in  std_logic;

      rst : in std_logic;
      clk : in std_logic
    );
  end component;
  
begin

  mem : memory
    generic map (
      file_name => "memreg.hex",
      addr_width => ADDR_WIDTH,
      data_width => DATA_WIDTH
    )
    port map (
      address => address,
      data_in => data_in,
      data_out => data_out,
      we => we,
      clk => clk,
      rst => rst
    );

  clk <= not clk after 50 ns;

  test : process
  begin
    we <= '0';
    rst <= '0';
    wait until rising_edge(clk);
    rst <= '1';
    wait until rising_edge(clk);

    address <= 0;
    wait until rising_edge(clk);
    assert to_integer(unsigned(data_out)) = 19;
    report "Address 0: " & to_string(to_integer(unsigned(data_out)));
    
    address <= 10;
    wait until rising_edge(clk);
    report "Address 10: " & to_string(to_integer(unsigned(data_out)));
    assert to_integer(unsigned(data_out)) = 32769;

    report "all tests completed";

    wait;
  end process;

end testbench;

