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
  function i2b(e: Integer) return Boolean is
  begin
    case e is
      when 0 => return False;
      when others => return True;
    end case;
  end;
  function b2i(e: Boolean) return Integer is
  begin
    case e is
      when True => return 1;
      when False => return 0;
    end case;
  end;

  subtype Data is Std_Logic_Vector(data_width - 1 downto 0);

  type StateT is
    (Fetch,
     Halt,
     Set, SetReadReg,
     Push,
     Pop,
     Eq, EqReadDest, EqReadFirstArg,
     Gt, GtReadDest, GtReadFirstArg,
     Jmp,
     JmpC, JmpCReadCond,
     Add, AddReadDest, AddReadFirstArg,
     Mult, MultReadDest, MultReadFirstArg,
     Mod1, ModReadDest, ModReadFirstArg,
     And1, AndReadDest, AndReadFirstArg,
     Or1, OrReadDest, OrReadFirstArg,
     Not1, NotReadDest,
     RMem, RMemReadDest, RMemReadComp,
     WMem, WMemReadDest, WMemWriteComp,
     Call,
     Ret,
     Out1,
     In1,
     Noop);
  subtype StageT is integer;

  signal data_inr: Data;

  signal pc    : Data;
  signal state : StateT := Noop;
  signal stage : StageT;

  signal adreg : Data;
  signal mem_we : Std_Logic := '0';
  signal mem_io : Std_Logic := '0';

  signal reg_sell : Integer range 0 to 9;
  signal reg_sel : Integer range 0 to 7;
  signal reg_data : Data;
  signal reg_write: Data;
  signal reg_we: Std_Logic := '0';

  signal stack_top : Data;
  signal stack_write : Data;
  signal stack_we : Std_Logic := '0';
  signal stack_pop : Std_Logic := '0';

  signal op1   : Data;
  signal op2   : Data;

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

  component stack
    generic (
      -- stack_size : Positive;
      data_width : Positive
    );
    port (
      data_in  : in  Std_Logic_Vector(data_width - 1 downto 0);
      data_out : out Std_Logic_Vector(data_width - 1 downto 0);
      pop      : in  Std_Logic;
      we       : in  Std_Logic;

      clk : in Std_Logic;
      rst : in Std_Logic
    );
  end component;

begin

  registers : register_bank
    generic map (
      bank_size => 10,
      data_width => data_width
    )
    port map (
      addr => reg_sell,
      data_in => reg_write,
      data_out => reg_data,
      we => reg_we,

      rst => rst,
      clk => not clk
    );

  st : stack
    generic map (
      data_width => data_width
    )
    port map (
      data_in => stack_write,
      data_out => stack_top,
      pop => stack_pop,
      we => stack_we,

      rst => rst,
      clk => not clk
    );

  main : process(clk, rst)
  begin
    if rst = '0' then
      adreg <= (others => '0');
      pc    <= (others => '0');
      state <= Fetch;
      reg_we    <= '0';
      stack_we  <= '0';
      stack_pop <= '0';
      mem_we <= '0';
      mem_io <= '0';
    elsif rising_edge(clk) then
      case state is
        when Fetch =>
          -- Reset write signals
          mem_we <= '0';
          mem_io <= '0';
          reg_we    <= '0';
          stack_we  <= '0';
          stack_pop <= '0';
          
          case to_integer(unsigned(data_in)) is
            when 0 =>
              state <= Halt;
            when 1 =>
              state <= Set;
            when 2 =>
              state <= Push;
            when 3 =>
              state <= Pop;
            when 4 =>
              state <= Eq;
            when 5 =>
              state <= Gt;
            when 6 =>
              state <= Jmp;
            when 7 =>
              state <= JmpC;
              stage <= 1; -- non zero condition
            when 8 =>
              state <= JmpC;
              stage <= 0; -- zero condition
            when 9 =>
              state <= Add;
            when 10 =>
              state <= Mult;
            when 11 =>
              state <= Mod1;
            when 12 =>
              state <= And1;
            when 13 =>
              state <= Or1;
            when 14 =>
              state <= Not1;
            when 15 =>
              state <= RMem;
            when 16 =>
              state <= WMem;
            when 17 =>
              state <= Call;
            when 18 =>
              state <= Ret;
            when 19 =>
              state <= Out1;
            when 20 =>
              state <= In1;
            when 21 => null; -- noop
            when others =>
              report "Unknown instruction: " & to_string(to_integer(unsigned(data_in)));
              null;
              -- report "Unknown state: " & to_string(unsigned(data_in)) severity warning;
          end case;
          pc <= pc + 1;

        when Halt =>
          report "Machine halted" severity failure;

        when Set =>
          stage <= to_integer(unsigned(data_in)) - 32768;
          state <= SetReadReg;
          reg_sel <= stage when stage >= 0;
          pc <= pc + 1;
        when SetReadReg =>
          -- report "Setting register: " & to_string(stage);
          if (stage >= 0) then
            reg_write <= data_inr;
            reg_we <= '1';
            reg_sel <= stage;
          end if;
          state <= Fetch;
          pc <= pc + 1;

        when Push =>
          stack_write <= data_inr;
          stack_we <= '1';
          state <= Fetch;
          pc <= pc + 1;

        when Pop =>
          if (to_integer(unsigned(data_in)) - 32768) >= 0 then
            reg_sel <= to_integer(unsigned(data_in)) - 32768;
            reg_we <= '1';
            reg_write <= stack_top;
            stack_pop <= '1';
          end if;
          state <= Fetch;
          pc <= pc + 1;

        when Eq =>
          stage <= to_integer(unsigned(data_in)) - 32768;
          state <= EqReadDest;
          pc <= pc + 1;
        when EqReadDest =>
          state <= EqReadFirstArg;
          op1 <= data_inr;
          pc <= pc + 1;
        when EqReadFirstArg =>
          if (stage >= 0) then
            reg_write(data_width - 1 downto 1) <= (others => '0');
            reg_write(0) <= '1' when op1 = data_inr else
                            '0';
            reg_we <= '1';
            reg_sel <= stage;
          end if;
          state <= Fetch;
          pc <= pc + 1;

        when Gt =>
          stage <= to_integer(unsigned(data_in)) - 32768;
          state <= GtReadDest;
          pc <= pc + 1;
        when GtReadDest =>
          state <= GtReadFirstArg;
          op1 <= data_inr;
          pc <= pc + 1;
        when GtReadFirstArg =>
          if (stage >= 0) then
            reg_write(data_width - 1 downto 1) <= (others => '0');
            reg_write(0) <= '1' when op1 > data_inr else
                            '0';
            reg_we <= '1';
            reg_sel <= stage;
          end if;
          state <= Fetch;
          pc <= pc + 1;

        when Jmp =>
          state <= Fetch;
          pc <= data_inr;

        when JmpC =>
          stage <= b2i((data_inr = "0") xor i2b(stage));
          state <= JmpCReadCond;
          pc <= pc + 1;
        when JmpCReadCond =>
          if (stage = 1) then
            pc <= data_inr;
          else
            pc <= pc + 1;
          end if;
          state <= Fetch;

        when Add =>
          stage <= to_integer(unsigned(data_in)) - 32768;
          state <= AddReadDest;
          pc <= pc + 1;
        when AddReadDest =>
          state <= AddReadFirstArg;
          op1 <= data_inr;
          pc <= pc + 1;
        when AddReadFirstArg =>
          if (stage >= 0) then
            reg_write(data_width - 1) <= '0';
            reg_write(data_width - 2 downto 0) <= op1(data_width - 2 downto 0) + data_inr(data_width - 2 downto 0);
            reg_we <= '1';
            reg_sel <= stage;
          end if;
          state <= Fetch;
          pc <= pc + 1;

        when Mult =>
          stage <= to_integer(unsigned(data_in)) - 32768;
          state <= MultReadDest;
          pc <= pc + 1;
        when MultReadDest =>
          state <= MultReadFirstArg;
          op1 <= data_inr;
          pc <= pc + 1;
        when MultReadFirstArg =>
          if (stage >= 0) then
            reg_write(data_width - 1) <= '0';
            reg_write(data_width - 2 downto 0) <=
              Std_Logic_Vector(to_unsigned(to_integer(unsigned(op1(data_width - 2 downto 0))) * to_integer(unsigned(data_inr(data_width - 2 downto 0))) mod 32768, 15));
            reg_we <= '1';
            reg_sel <= stage;
          end if;
          state <= Fetch;
          pc <= pc + 1;

        when Mod1 =>
          stage <= to_integer(unsigned(data_in)) - 32768;
          state <= ModReadDest;
          pc <= pc + 1;
        when ModReadDest =>
          state <= ModReadFirstArg;
          op1 <= data_inr;
          pc <= pc + 1;
        when ModReadFirstArg =>
          if (stage >= 0) then
            reg_write(data_width - 1) <= '0';
            reg_write(data_width - 2 downto 0) <=
              Std_Logic_Vector(to_unsigned(to_integer(unsigned(op1(data_width - 2 downto 0))) mod to_integer(unsigned(data_inr(data_width - 2 downto 0))) mod 32768, 15));
            reg_we <= '1';
            reg_sel <= stage;
          end if;
          state <= Fetch;
          pc <= pc + 1;

        when And1 =>
          stage <= to_integer(unsigned(data_in)) - 32768;
          state <= AndReadDest;
          pc <= pc + 1;
        when AndReadDest =>
          state <= AndReadFirstArg;
          op1 <= data_inr;
          pc <= pc + 1;
        when AndReadFirstArg =>
          if (stage >= 0) then
            reg_write <= op1 and data_inr;
            reg_we <= '1';
            reg_sel <= stage;
          end if;
          state <= Fetch;
          pc <= pc + 1;

        when Or1 =>
          stage <= to_integer(unsigned(data_in)) - 32768;
          state <= OrReadDest;
          pc <= pc + 1;
        when OrReadDest =>
          state <= OrReadFirstArg;
          op1 <= data_inr;
          pc <= pc + 1;
        when OrReadFirstArg =>
          if (stage >= 0) then
            reg_write <= op1 or data_inr;
            reg_we <= '1';
            reg_sel <= stage;
          end if;
          state <= Fetch;
          pc <= pc + 1;

        when Not1 =>
          stage <= to_integer(unsigned(data_in)) - 32768;
          state <= NotReadDest;
          pc <= pc + 1;
        when NotReadDest =>
          if (stage >= 0) then
            -- bit 16 indicates register
            reg_write(data_width - 1) <= '0';
            -- 15 bit negation
            reg_write(data_width - 2 downto 0) <= not data_inr(data_width - 2 downto 0);
            reg_we <= '1';
            reg_sel <= stage;
          end if;
          state <= Fetch;
          pc <= pc + 1;

        when RMem =>
          stage <= to_integer(unsigned(data_in)) - 32768;
          state <= RMemReadDest;
          pc <= pc + 1;
        when RMemReadDest =>
          mem_io <= '1';
          adreg <= data_inr;
          state <= RMemReadComp;
        when RMemReadComp =>
          if (stage >= 0) then
            reg_write <= data_inr;
            reg_we <= '1';
            reg_sel <= stage;
          end if;
          state <= Fetch;
          mem_io <= '0';
          pc <= pc + 1;

        when Wmem =>
          adreg <= data_inr;
          state <= WMemReadDest;
          pc <= pc + 1;
        when WMemReadDest =>
          mem_io <= '1';
          mem_we <= '1';
          data_out <= data_inr;
          state <= WMemWriteComp;
        when WMemWriteComp =>
          state <= Fetch;
          mem_io <= '0';
          pc <= pc + 1;
          
        when Call =>
          -- report "Calling and jumping to " & to_string(to_integer(unsigned(data_inr)));
          -- report "from " & to_string(to_integer(unsigned(pc)));
          stack_write <= pc + 1;
          stack_we <= '1';
          state <= Fetch;
          pc <= data_inr;
        when Ret =>
          -- report "Returning to " & to_string(to_integer(unsigned(stack_top)));
          pc <= stack_top;
          stack_pop <= '1';
          state <= Fetch;

        when Out1 =>
          if (data_inr < 128) then
            write(output, to_string(character'val(to_integer(unsigned(data_inr)))));
          end if;
          state <= Fetch;
          pc <= pc + 1;

        when In1 =>
          pc <= pc + 1;
          
        when others =>
          null;
      end case;

    end if;
  end process;

  we <= mem_we when mem_io = '1' else
        '0';
  address  <=
    to_integer(unsigned(adreg)) when mem_io = '1' else
    to_integer(unsigned(pc));
  data_inr <=
    reg_data when to_integer(unsigned(data_in)) > 32767 else
    data_in;
  
  reg_sell  <=
    reg_sel when reg_we = '1' else
    to_integer(unsigned(data_in)) - 32768 when to_integer(unsigned(data_in)) > 32767 else
    0;
end architecture processor_arch;
