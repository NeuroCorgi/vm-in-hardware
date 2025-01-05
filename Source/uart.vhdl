library ieee;
use ieee.std_logic_1164.all;

entity uart is
  generic (
    clock_freq : integer;
    data_width : integer := 8;
    baud_rate  : integer := 9600
  )
  port (
    data_in  : in  Std_Logic_Vector(data_width - 1 downto 0);
    data_out : out Std_Logic_Vector(data_width - 1 downto 0);

    clk : Std_Logic;
  );
end uart;
