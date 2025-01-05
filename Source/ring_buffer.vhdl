library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

entity ring_buffer is
  generic (
    buffer_size : integer := 128;
    data_width  : integer := 16
  );
  port (
    data_in  : in  std_logic_vector(data_width - 1 downto 0);
    data_out : out std_logic_vector(data_width - 1 downto 0);

    empty : out std_logic;

    we  : in std_logic;
    re  : in std_logic;
    rst : in std_logic;
    clk : in std_logic
  );
end ring_buffer;

architecture buffer_arch of ring_buffer is
  type buffer_array is array(0 to buffer_size - 1) of std_logic_vector(data_width - 1 downto 0);
  signal ring : buffer_array := (others => (others => '0'));
  signal read_ptr, write_ptr : integer range 0 to buffer_size - 1 := 0;

begin

  empty <= '1' when read_ptr = write_ptr else '0';
  data_out <= ring(read_ptr);

  process(clk, rst)
  begin
    if rst = '0' then
      ring <= (others => (others => '0'));
      read_ptr <= 0;
      write_ptr <= 0;
    elsif rising_edge(clk) then
      if re = '1' then
        read_ptr <= (read_ptr + 1) mod buffer_size;
      end if;
      if we = '1' then
        ring(write_ptr) <= data_in;
        write_ptr <= (write_ptr + 1) mod buffer_size;
      end if;
    end if;
  end process;

end architecture buffer_arch;
