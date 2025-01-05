library ieee;

use ieee.std_logic_1164.all;

entity system is
  generic (
    baud_rate : integer
  );
  port (
    rx : in  std_logic;
    tx : out std_logic;

    clk : in std_logic;
    rst : in std_logic
  );
end entity system;

architecture test of system is

  constant ADDR_WIDTH : Integer := 15;
  constant DATA_WIDTH : Integer := 16;

  signal nclk : Std_Logic;

  signal address : Integer := 0;
  signal data_in  : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal data_out : std_logic_vector(DATA_WIDTH - 1 downto 0);

  signal we : Std_Logic;

  signal cin, cout : Std_Logic_Vector(7 downto 0);
  signal cin_r, cout_w : Std_Logic;

  signal uart_in, uart_out : Std_Logic_Vector(7 downto 0);
  signal uart_r, uart_w : Std_Logic;

  signal out_empty, in_empty : Std_Logic;
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

  component ring_buffer
    generic (
      buffer_size : integer;
      data_width : integer
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
  end component;

  -- component uart
  --   generic (
      
  --   );

begin

  nclk <= not clk;
  nempty <= not in_empty;

  mem : memory
    generic map (
      file_name  => "memory.hex",
      addr_width => ADDR_WIDTH,
      data_width => DATA_WIDTH
    )
    port map (
      address => address,
      data_in => data_in,
      data_out => data_out,
      we => we,

      clk => nclk,
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

  rout : ring_buffer
    generic map (
      buffer_size => 512,
      data_width => 8
    )
    port map(
      data_in => cout,
      data_out => uart_in,

      empty => out_empty,

      we => cout_w,
      re => uart_r,

      rst => rst,
      clk => nclk
    );

  rin : ring_buffer
    generic map (
      buffer_size => 512,
      data_width => 8
    )
    port map (
      data_in => uart_out,
      data_out => cin,

      empty => in_empty,

      we => uart_w,
      re => cin_r,

      rst => rst,
      clk => nclk
    );

  -- uart : uart
  --   generic map (
  --     data_width => 8;
  --     baud_rate => 9600
  --   )
  --   port map (
  --     data_in => uart_in,
  --     data_out => uart_out
  --   );

end architecture test;
