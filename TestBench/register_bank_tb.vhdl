library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library src;
use src.register_bank;

entity register_bank_tb is
end entity register_bank_tb;

architecture testbench of register_bank_tb is
  constant DATA_WIDTH : integer := 4;
  constant BANK_SIZE  : integer := 2;

  subtype register_a is integer range 0 to BANK_SIZE - 1;
  subtype register_t is std_logic_vector(DATA_WIDTH - 1 downto 0);

  signal clk : std_logic := '0';
  signal rst : std_logic := '0';

  signal we       : std_logic  := '0';
  signal addr     : register_a := 0;
  signal data_in  : register_t := (others => '0');
  signal data_out : register_t;

  component register_bank
    generic (
      bank_size  : integer;
      data_width : integer
    );
    port (
      addr     : in  integer range 0 to bank_size - 1;
      data_in  : in  std_logic_vector(data_width - 1 downto 0);
      data_out : out std_logic_vector(data_width - 1 downto 0);
      we       : in  std_logic;

      rst      : in  std_logic;
      clk      : in  std_logic
    );
  end component;
  
begin

  C : register_bank
    generic map (
      bank_size  => BANK_SIZE,
      data_width => DATA_WIDTH
      )
    port map (
      addr     => addr,
      data_in  => data_in,
      data_out => data_out,
      we       => we,
      rst      => rst,
      clk      => clk
      );

  init : process
  begin
    clk <= '0';
    rst <= '1';
    report "Init conditions set";
    wait for 10 ns;

    loop
      clk <= '0';
      wait for 50 ns;
      clk <= '1';
      wait for 50 ns;
    end loop;

    wait;
  end process;

  test : process
  begin
    wait for 110 ns;

    addr <= 0;
    wait for 100 ns;

    assert to_integer(unsigned(data_out)) = 0;

    addr <= 1;
    wait for 100 ns;

    assert to_integer(unsigned(data_out)) = 0;
    
  end process;

  end architecture testbench;
  
