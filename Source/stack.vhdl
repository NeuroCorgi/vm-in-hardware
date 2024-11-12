library ieee;
use ieee.std_logic_1164.all;

entity stack is
  generic (
    stack_size : Positive := 128;
    data_width : Positive := 16
  );
  port (
    data_in  : in  Std_Logic_Vector(data_width - 1 downto 0);
    data_out : out Std_Logic_Vector(data_width - 1 downto 0);
    pop      : in  Std_Logic;
    we       : in  Std_Logic;

    clk : in Std_Logic;
    rst : in Std_Logic
  );
end;

architecture stack_arch of stack is
  type StackT is array (0 to stack_size) of Std_Logic_Vector(data_width - 1 downto 0);
  signal stacka : StackT := (others => (others => '0'));
  signal top : Integer range 0 to stack_size + 1 := 0;
begin
  main : process(clk, rst)
  begin
    if rst = '0' then
      top <= 0;
      stacka <= (others => (others => '0'));
    elsif rising_edge(clk) then
      if we = '1' then
        stacka(top + 1) <= data_in;
        top <= top + 1;
      elsif pop = '1' then
        top <= top - 1;
      end if;
    end if;
  end process;

  data_out <= stacka(top);
end stack_arch;
