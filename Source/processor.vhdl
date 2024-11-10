library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;

entity processor is
  generic (
    data_width : integer := 16;
    addr_width : integer := 15
  );
  port (
    data_in  : in  std_logic_vector(data_width - 1 downto 0);
    address  : out integer range 0 to 2 ** addr_width - 1;
    data_out : out std_logic_vector(data_width - 1 downto 0);
    we       : out std_logic;
    
    rst  : in  std_logic;
    clk  : in  std_logic
    -- halt : out std_logic
  );
end processor;

architecture processor_arch of processor is
  type StateT is
    (PreFetch, Fetch,
     Halt,
     Out1, OutReadArg,
     Noop);
  subtype StageT is integer;

  signal adreg : std_logic_vector(data_width - 1 downto 0);
  signal pc    : std_logic_vector(data_width - 1 downto 0);
  signal state : StateT := Noop;

  signal op1   : std_logic_vector(data_width - 1 downto 0);
  signal op2   : std_logic_vector(data_width - 1 downto 0);
begin

  main : process(clk, rst)
  begin
    if rst = '1' then
      adreg <= (others => '0');
      pc    <= (others => '0');
      state <= Fetch;
    elsif rising_edge(clk) then
      case state is
        when Fetch =>
          case data_in(7 downto 0) is
            when "00000000" =>
              -- report "Transition to halt" severity error;
              state <= Halt;
            when "00010011" =>
              -- report "Transition to out state" severity warning;
              state <= Out1;
            when others =>
              -- report "Unknown state: " & to_string(unsigned(data_in)) severity warning;
          end case;
          pc <= pc + 1;

        when Out1 =>
          -- report "In out state reading..." severity warning;
          op1 <= data_in;
          state <= OutReadArg;
          pc <= pc + 1;
        when OutReadArg =>
          -- report "Just read the one and only arg, writing..." severity warning;
          write(output, to_string(character'val(to_integer(unsigned(op1)))));
          state <= Fetch;
          
        when others => null;
      end case;

    end if;
  end process;

  address <= to_integer(unsigned(pc));
end architecture processor_arch;
