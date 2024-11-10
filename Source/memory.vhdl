library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

use std.textio.all;

entity memory is
  generic (
    file_name  : string := "memory.hex";
    addr_width : integer := 16;
    data_width  : integer := 16
  );
  port (
    address  : in  integer range 0 to 2 ** addr_width - 1;
    data_in  : in  std_logic_vector(data_width - 1 downto 0);
    data_out : out std_logic_vector(data_width - 1 downto 0);
    we       : in  std_logic;

    rst : in std_logic;
    clk : in std_logic
  );
end;

architecture memory_arch of memory is
  type MemoryT is array(0 to 2 ** addr_width - 1) of std_logic_vector(data_width - 1 downto 0);
  signal mem : MemoryT;
  
begin

  init : process
    file file_handler : text open read_mode is file_name;
    variable line_number : line;
    variable i : integer := 0;
    variable hex_string : string(1 to data_width / 4);
    variable hex_value : std_logic_vector(data_width - 1 downto 0);
    
    function hex2slv(hex_string : string) return std_logic_vector is
      variable result : std_logic_vector(hex_string'length * 4 - 1 downto 0) := (others => '0');
      variable index : integer := 0;
    begin
      for j in hex_string'reverse_range loop
        case hex_string(j) is
          when '0' => result(index * 4 + 3 downto index * 4) := "0000";
          when '1' => result(index * 4 + 3 downto index * 4) := "0001";
          when '2' => result(index * 4 + 3 downto index * 4) := "0010";
          when '3' => result(index * 4 + 3 downto index * 4) := "0011";
          when '4' => result(index * 4 + 3 downto index * 4) := "0100";
          when '5' => result(index * 4 + 3 downto index * 4) := "0101";
          when '6' => result(index * 4 + 3 downto index * 4) := "0110";
          when '7' => result(index * 4 + 3 downto index * 4) := "0111";
          when '8' => result(index * 4 + 3 downto index * 4) := "1000";
          when '9' => result(index * 4 + 3 downto index * 4) := "1001";
          when 'A' | 'a' => result(index * 4 + 3 downto index * 4) := "1010";
          when 'B' | 'b' => result(index * 4 + 3 downto index * 4) := "1011";
          when 'C' | 'c' => result(index * 4 + 3 downto index * 4) := "1100";
          when 'D' | 'd' => result(index * 4 + 3 downto index * 4) := "1101";
          when 'E' | 'e' => result(index * 4 + 3 downto index * 4) := "1110";
          when 'F' | 'f' => result(index * 4 + 3 downto index * 4) := "1111";
          when others => report "Invalid hexadecimal character" severity error;
        end case;
        index := index + 1;
      end loop;
      return result;
    end function;
    
  begin
    while not endfile(file_handler) loop
      readline(file_handler, line_number);
      read(line_number, hex_string);
      hex_value(7 downto 0) := hex2slv(hex_string(1 to 2));
      hex_value(15 downto 8) := hex2slv(hex_string(3 to 4));
      mem(i) <= hex_value;
      -- report "INIT " & to_string(i) & ": " & to_string(unsigned(mem(i))) severity warning;
      i := i + 1;
    end loop;
    file_close(file_handler);
    wait;
  end process;

  main : process(clk)
  begin
    if rising_edge(clk) then
      -- mem(address) <= data_in when we = '1';
    end if;
  end process;

  data_out <= mem(address);
end architecture memory_arch;
