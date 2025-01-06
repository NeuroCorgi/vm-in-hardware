library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library src;
use src.processor;
use src.memory;

entity processor_tb is
end entity processor_tb;

architecture testbench of processor_tb is
  constant ADDR_WIDTH : Integer := 15;
  constant DATA_WIDTH : Integer := 16;

  signal clk : Std_Logic := '0';
  signal rst : Std_Logic := '1';
  signal we  : Std_Logic := '0';

  signal address : Integer := 0;
  signal data_in  : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal data_out : std_logic_vector(DATA_WIDTH - 1 downto 0);

  signal cin, cout : Std_Logic_Vector(7 downto 0);
  signal cin_r, cout_w : Std_Logic;
  signal nempty : Std_Logic;

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

  component processor
    generic (
      addr_width : Integer;
      data_width : Integer
    );
    port (
      data_in  : in  Std_Logic_Vector(data_width - 1 downto 0);
      data_out : out Std_Logic_Vector(data_width - 1 downto 0);
      address  : out Integer range 0 to 2 ** addr_width - 1;
      we       : out Std_Logic;

      cout   : out std_logic_vector(7 downto 0);
      cout_w : out std_logic;

      cin    : in  std_logic_vector(7 downto 0);
      cin_av : in  std_logic;
      cin_r  : out std_logic;
      
      rst : in Std_Logic;
      clk : in Std_Logic
    );
  end component;

begin

  mem : memory
    generic map (
      file_name  => "fib.bin.hex",
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

  pr : processor
    generic map (
      addr_width => ADDR_WIDTH,
      data_width => DATA_WIDTH
    )
    port map (
      address => address,
      data_in => data_out,
      data_out => data_in,
      we => we,

      cin => cin,
      cin_r => cin_r,
      cin_av => nempty,

      cout => cout,
      cout_w => cout_w,

      clk => clk,
      rst => rst
    );

  clk <= not clk after 1 ns;

  init : process
  begin
    rst <= '0';
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    rst <= '1';

    wait;
  end process;

end testbench;
