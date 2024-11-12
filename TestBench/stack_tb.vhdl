library ieee;
use ieee.std_logic_1164.all;

library src;
use src.stack;

entity stack_tb is
end entity;

architecture testbench of stack_tb is

  signal data_in  :  Std_Logic_Vector(2 downto 0);
  signal data_out :  Std_Logic_Vector(2 downto 0);
  signal pop : Std_Logic := '0';
  signal we  :  Std_Logic := '0';
  
  signal rst : Std_Logic := '0';
  signal clk : Std_Logic := '0';

  component stack is
    generic (
      data_width : Positive;
      stack_size : Positive
    );
    port (
      data_in  : in  Std_Logic_Vector(data_width - 1 downto 0);
      data_out : out Std_Logic_Vector(data_width - 1 downto 0);
      pop : in Std_Logic;
      we  : in Std_Logic;

      clk : in Std_Logic;
      rst : in Std_Logic
    );
  end component;
begin

  st : stack
    generic map (
      data_width => 3,
      stack_size => 4
    )
    port map (
      data_in => data_in,
      data_out => data_out,
      pop => pop,
      we => we,

      rst => rst,
      clk => clk
    );

  clk <= not clk after 50 ns;

  main : process
  begin
    rst <= '0';
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    rst <= '1';

    report "Starting testing";
    wait until falling_edge(clk);

    data_in <= "101";
    we <= '1';
    wait until falling_edge(clk);
    we <= '0';
    assert data_out = "101";

    wait;
  end process;
end testbench;
