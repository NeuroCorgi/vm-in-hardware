---
# Document
title: VM in hardware - Embedded System 
date: December, 2024
author: Aleksandr Pokatilov, Jurijs Zuravlovs
lang: en-GB
toc: true
toc-depth: 1
# References
csl: ieee.csl
bibliography: references.bib
link-citations: true
link-bibliography: true
# Meta
colorlinks: true
reference-links: true
output: pdf_document
documentclass: report
papersize: a4paper
geometry:
- top=2cm
- left=2cm
- right=2cm
- bottom=2cm
---

## 1. Purpose of the System

The goal of this project is to design a virtual machine (VM) processor using VHDL (VHSIC Hardware Description Language) that can execute a set of instructions to run a basic text-based adventure game. This project is inspired by the [Synacor VM Challenge](https://github.com/Aneurysm9/vm_challenge/tree/main), which challenges participants to create a processor capable of running a virtual machine for an adventure game. By combining our skills, we aimed to implement an embedded system that could perform these tasks and showcase our understanding of embedded system design.

This is `Top Level` diagram of the system architecture:

![execution](img/toplvl.png)

## 2. System Components Overview

The project is divided into several main components, each implemented as a separate VHDL file. Below is an overview of each component and its purpose:

```mermaid
flowchart 
  subgraph System_Design
    Start[Start System] --> InitMemory[Initialize Memory]
    InitMemory --> InitProcessor[Initialize Processor]
    InitProcessor --> InitRegisterBank[Initialize Register Bank]
    InitProcessor --> InitStack[Initialize Stack]
    InitProcessor --> InitUART[Initialize UART]
    
    InitMemory -->|Hex File Loaded| Memory[Memory]
    InitRegisterBank --> RegisterBank[Register Bank]
    InitStack --> Stack[Stack]
    InitUART --> UART[UART Module]
    
    Processor[Processor Execution]
    Memory -->|Fetch Instruction| Processor
    Processor -->|Decode Instruction| RegisterBank
    Processor -->|Arithmetic/Logic Operations| RegisterBank
    Processor -->|Push/Pop Data| Stack
    Processor -->|Read/Write Memory| Memory
    Processor -->|Transmit/Receive Data| UART
    
    Processor -->|Output/Result| Output[Display Output or Status]
    Processor -->|Halt| End[End System]

    classDef memory fill:#E3F2FD,stroke:#2196F3,stroke-width:2px;
    classDef processor fill:#FFEBEE,stroke:#F44336,stroke-width:2px;
    classDef registerBank fill:#E8F5E9,stroke:#4CAF50,stroke-width:2px;
    classDef stack fill:#FFF8E1,stroke:#FFC107,stroke-width:2px;
    classDef uart fill:#E8DAEF,stroke:#8E44AD,stroke-width:2px;

    Memory:::memory
    Processor:::processor
    RegisterBank:::registerBank
    Stack:::stack
    UART:::uart
  end
```

### 2.1 Explanation of the Flowchart

1. **Initialization Phase**:
   - The system initializes all components: memory, processor, register bank, stack, and UART.
   - Memory is loaded from a hex file, which sets up initial data.
   - The UART module is prepared to handle serial communication.

2. **Processor Execution**:
   - The processor fetches instructions from memory, decodes them, and executes the required operations.
   - It interacts with the register bank for temporary storage, the stack for managing function calls or temporary data, and the UART for transmitting or receiving data.

3. **Component Interactions**:
   - **Memory**: Provides instructions and stores data.
   - **Register Bank**: Handles temporary data storage for arithmetic and logic operations.
   - **Stack**: Manages data for function calls and supports push/pop operations.
   - **UART**: Facilitates serial communication, receiving input from a terminal and transmitting output.

4. **Output**:
   - After execution, results are displayed or sent via the UART module. The system ends when a `Halt` instruction is encountered.

## 3. Extended Description

### 3.1 Memory (`memory.vhdl`)

This file implements the main memory component, which stores instructions and data for the processor. The memory is addressed using a 16-bit address bus, and data is read or written based on control signals. Here’s an example of how memory read and write operations are managed:

#### Entity Declaration

```vhdl
-- memory.vhdl
entity memory is
  generic (
    -- Name of the hex file to load
    file_name  : string := "memory.hex";
     -- Address size in bits
    addr_width : integer := 16;
    -- Data size in bits
    data_width : integer := 16 
  );
  port (
    -- Memory address input
    address  : in  integer range 0 to 2 ** addr_width - 1; 
    -- Data to write
    data_in  : in  std_logic_vector(data_width - 1 downto 0); 
    -- Data to read
    data_out : out std_logic_vector(data_width - 1 downto 0);
    we       : in  std_logic;  -- Write enable
    rst      : in  std_logic;  -- Reset signal
    clk      : in  std_logic   -- Clock signal
  );
end;

```

#### Architecture Definition

```vhdl
-- memory.vhdl
-- Define a memory array type
architecture memory_arch of memory is
  type MemoryT is array(0 to 2 ** addr_width - 1) of std_logic_vector(data_width - 1 downto 0);              
  -- Stores initial memory values
  signal mem : MemoryT; 
  -- Active memory for read/write operations
  signal mem2 : MemoryT; 
begin
```

- MemoryT: Defines an array of memory words with std_logic_vector values of width data_width.
- mem: Used to store the initial memory values loaded from the hex file.
- mem2: Operates as the main memory during execution, allowing read and write operations.

#### Initialization Process

The init process loads data from a hex file into the mem array.

```vhdl
-- memory.vhdl
  -- Process to initialize memory from a hex file
  init : process
    -- Open the hex file in read mode
    file file_handler : text open read_mode is file_name;  
    -- Variable to hold each line from the file
    variable line_number : line;
    -- Memory index for loading data                          
    variable i : integer := 0;               
    -- Variable to store hex string              
    variable hex_string : string(1 to data_width / 4);     
    -- Converted binary data
    variable hex_value : std_logic_vector(data_width - 1 downto 0); 
```

- `file_handler:` Opens the specified file (file_name) for reading.
- `hex_string:` Temporarily holds hex strings read from the file.
- `hex_value:` Converts hex_string into a std_logic_vector format.

The hex2slv function converts a hexadecimal string to a std_logic_vector, facilitating loading data from the hex file.

- Purpose: Maps each hex character ('0' to 'F') to a 4-bit binary representation.

```vhdl
    -- Function to convert hex string to std_logic_vector
    function hex2slv(hex_string : string) return std_logic_vector is
      -- Variable to hold the binary result
      variable result : std_logic_vector(hex_string'length * 4 - 1 downto 0) := (others => '0');
      -- Index to iterate through hex characters
      variable index : integer := 0;                      
    begin
      -- Loop through each hex character
      for j in hex_string'reverse_range loop          
        -- Check the hex character   
        case hex_string(j) is                              
          when '0' => result(index * 4 + 3 downto index * 4) := "0000";
          when '1' => result(index * 4 + 3 downto index * 4) := "0001";
          when '2' => result(index * 4 + 3 downto index * 4) := "0010";
          ...
          -- Error for invalid characters
          when others => report "Invalid hexadecimal character" severity error; 
        end case;
        -- Move to the next hex character
        index := index + 1;                               
      end loop;
      -- Return the binary result
      return result;                                      
    end function;
```

#### Reading and loading data

- Loop: Reads each line in the file, converts hex to binary, and stores it in mem.
- hex2slv usage: Converts each hex string segment into std_logic_vector to initialize mem.

```vhdl
 -- Loop through the hex file to read and initialize memory
    while not endfile(file_handler) loop
      -- Read a line from the hex file
      readline(file_handler, line_number);
      -- Read the hex string              
      read(line_number, hex_string);                     
      -- Convert first 2 hex chars to binary
      hex_value(7 downto 0) := hex2slv(hex_string(1 to 2)); 
      -- Convert next 2 hex chars to binary
      hex_value(15 downto 8) := hex2slv(hex_string(3 to 4)); 
      -- Store the binary data in memory
      mem(i) <= hex_value;               
      -- Increment the memory index                
      i := i + 1;                                        
    end loop;
    -- Close the hex file
    file_close(file_handler); 
    -- End the process                           
    wait;                                                
  end process;
```

#### Memory Process

- Reset (`rst`): Resets mem2 to initial values stored in mem upon activation.
- Write Enable (`we`): Allows data to be written to the specified address in mem2 when active.
- Data Output (`data_out`): Continuously outputs data from mem2 at the specified address.

```vhdl
  -- Process for handling memory read/write operations
  main : process(clk)
  begin
    if (rst = '0') then                            -- Check if reset signal is active
      mem2 <= mem;                                 -- Reset active memory to initial values
    elsif rising_edge(clk) and we = '1' then       -- On rising clock edge and write enabled
      mem2(address) <= data_in;                    -- Write input data to memory
    end if;
  end process;

  -- Output the data at the specified address
  data_out <= mem2(address);                       -- Assign the data from memory to output
end architecture memory_arch;
```

### 3.2. Processor (`processor.vhdl`)

The `processor.vhdl` file defines a processor capable of executing instructions by fetching them from memory, decoding their operation, executing the appropriate logic, and managing state transitions. It interacts with a register bank and a stack, supporting operations like arithmetic, logic, memory read/write, and control flow. This architecture implements a state machine to manage instruction execution. Here’s an example of an instruction fetch and decode cycle:

#### Entity declaration

```vhdl
-- processor.vhdl
entity processor is
  generic (
    data_width : integer := 16;  -- Data width (16 bits)
    addr_width : integer := 15   -- Address width (15 bits)
  );
  port (
    data_in  : in  std_logic_vector(data_width - 1 downto 0); -- Data input
    address  : out integer range 0 to 2 ** addr_width - 1;    -- Memory address output
    data_out : out std_logic_vector(data_width - 1 downto 0); -- Data output
    we       : out std_logic;                                -- Write enable
    rst      : in  std_logic;                                -- Reset signal
    clk      : in  std_logic                                 -- Clock signal
  );
end processor;
```

 Define a processor module with interfaces for memory (data_in, data_out, address, we) and control signals (rst, clk).

#### Architecture overview

 ```vhdl
architecture processor_arch of processor is
  subtype Data is Std_Logic_Vector(data_width - 1 downto 0);
  type StateT is (Fetch, Halt, Set, Add, Mult, Jmp, Out1, ...);
  signal state : StateT := Fetch; -- Processor starts in Fetch state
  signal pc    : Data;           -- Program counter
  signal reg_data : Data;        -- Register data for operations
  signal stack_top : Data;       -- Stack top for stack operations
  signal mem_we, stack_we, reg_we : Std_Logic := '0'; -- Control signals
begin 
 ```

#### Register Bank and Stack Components

 ```vhdl
component register_bank
  generic (
    bank_size  : integer;
    data_width : integer
  );
  port (
    addr     : in integer range 0 to bank_size - 1;
    data_in  : in std_logic_vector(data_width - 1 downto 0);
    data_out : out std_logic_vector(data_width - 1 downto 0);
    we       : in std_logic;
    rst      : in std_logic;
    clk      : in std_logic
  );
end component;

component stack
  generic (data_width : Positive);
  port (
    data_in  : in  std_logic_vector(data_width - 1 downto 0);
    data_out : out std_logic_vector(data_width - 1 downto 0);
    pop      : in  std_logic;
    we       : in  std_logic;
    clk      : in  std_logic;
    rst      : in  std_logic
  );
end component;
 ```

Manages data storage and retrieval for arithmetic and logic operations.  Handles function calls and temporary data storage.

#### State machine

Implements a state machine to handle instruction execution.

- Fetch: Fetches the next instruction from memory.
- Halt: Stops processor execution.
- Add, Mult: Perform arithmetic operations.
- Jmp: Modifies the program counter for jumps.

```vhdl
main : process(clk, rst)
begin
  if rst = '0' then
    state <= Fetch;          -- Reset state to Fetch
    pc    <= (others => '0');-- Reset program counter
    reg_we <= '0';           -- Disable register writes
    mem_we <= '0';           -- Disable memory writes
  elsif rising_edge(clk) then
    case state is
      when Fetch =>
        case to_integer(unsigned(data_in)) is
          when 0 => state <= Halt; -- Halt instruction
          when 1 => state <= Set;  -- Set a register
          when 9 => state <= Add;  -- Perform addition
          when 10 => state <= Mult;-- Perform multiplication
          when 6 => state <= Jmp;  -- Jump to an address
          when 19 => state <= Out1;-- Output a value
          when others => 
            report "Unknown instruction: " & to_string(to_integer(unsigned(data_in)));
        end case;
        pc <= pc + 1; -- Increment program counter
      when Halt =>
        report "Processor halted" severity failure;
      when Add =>
        reg_we <= '1'; -- Enable register write
        reg_data <= reg_data + data_in; -- Perform addition
        state <= Fetch; -- Return to Fetch state
      when others =>
        null; -- Handle other states
    end case;
  end if;
end process;
```

#### Memory and register interaction

Handles data flow between memory, registers, and the processor.

```vhdl
data_inr <= reg_data when to_integer(unsigned(data_in)) > 32767 else data_in;
reg_sell <= to_integer(unsigned(data_in)) - 32768;
data_out <= data_inr;
address  <= to_integer(unsigned(pc));
we       <= mem_we when mem_io = '1' else '0';
```

Key states include Fetch for retrieving instructions, Add for performing addition, Jmp for jumping to a new instruction address, and Halt for stopping execution. The processor works with external memory for data storage, a register bank for temporary values, and a stack for managing function calls.

This design is efficient for basic operations, allowing the processor to handle tasks like arithmetic, comparisons, and program control in an organized way. Its state-driven architecture ensures clear and consistent execution of instructions.

### 3.3 Register bank (`register_bank.vhdl`)

The file implements a register bank, which is a collection of small, fast storage units (registers) used in a processor. It allows reading and writing to specific registers based on an address, synchronized with a clock signal.

#### Entity Declaration

```vhdl
-- register_bank.vhdl
entity register_bank is
  generic (
    bank_size  : integer := 8;    -- Number of registers
    data_width : integer := 16    -- Width of each register in bits
  );
  port (
    addr     : in  integer range 0 to bank_size - 1; -- Address to select a register
    data_in  : in  std_logic_vector(data_width - 1 downto 0); -- Input data for writing
    data_out : out std_logic_vector(data_width - 1 downto 0); -- Output data for reading
    we       : in  std_logic;    -- Write enable signal
    rst      : in  std_logic;    -- Reset signal
    clk      : in  std_logic     -- Clock signal
  );
end register_bank;
```

#### Register array Definition

```vhdl
architecture register_bank_arch of register_bank is
  type RegistersT is array (0 to bank_size - 1) of
    std_logic_vector(data_width - 1 downto 0); -- Define an array of registers

  -- Initialize registers to zero
  signal registers : RegistersT := (others => (others => '0')); 
begin
```

#### Register operation process

```vhdl
process(clk, rst)
begin
  if rst = '0' then
    -- Reset all registers to zero
    registers <= (others => (others => '0')); 
  elsif rising_edge(clk) and we = '1' then
    -- Write data to the register at the specified address
    registers(addr) <= data_in; 
  end if;
end process;
```

#### Register read operation

```vhdl
-- Output the data from the selected register
data_out <= registers(addr);
```

The `register_bank.vhdl` file defines a register bank for storing temporary data in a processor.
It has a customizable number of registers (`bank_size`), each with a specific width (`data_width`).
When reset (`rst`) is active, all registers are cleared.
On each clock cycle (`clk`), if the write enable signal (`we`) is active, the selected register (`addr`) is updated with input data (`data_in`).
The output (`data_out`) always reflects the value of the selected register.
This design ensures fast and efficient data storage and retrieval for processors.

### 3.4 Stack (`stack.vhdl`)

The file implements a stack, a Last-In-First-Out (`LIFO`) data structure, commonly used in processors for managing temporary data, function calls, and return addresses.
This stack is parameterized by `stack_size` (number of elements it can hold) and `data_width` (width of each element).
The stack supports operations like push, pop, and reset.

#### Entity declaration

```vhdl
-- stack.vhdl
entity stack is
  generic (
    -- Maximum size of the stack
    stack_size : Positive := 128;   
    -- Width of each data element
    data_width : Positive := 16     
  );
  port (
    -- Data to push onto the stack
    data_in  : in  Std_Logic_Vector(data_width - 1 downto 0); 
    -- Data popped from the stack
    data_out : out Std_Logic_Vector(data_width - 1 downto 0); 
    pop      : in  Std_Logic;       -- Signal to pop data
    we       : in  Std_Logic;       -- Signal to push data
    clk      : in  Std_Logic;       -- Clock signal
    rst      : in  Std_Logic        -- Reset signal
  );
end;
```

#### Stack operations

```vhdl
main : process(clk, rst)
begin
  if rst = '0' then
    -- Reset the stack pointer to the bottom
    top <= 0;
    -- Clear all stack entries                              
    stacka <= (others => (others => '0')); 
  elsif rising_edge(clk) then
    if we = '1' then
      stacka(top + 1) <= data_in;     -- Push new data onto the stack
      top <= top + 1;                 -- Increment the stack pointer
    elsif pop = '1' then
      top <= top - 1;                 -- Pop the top data off the stack
    end if;
  end if;
end process;
```

#### Architecture implementation

```vhdl
architecture stack_arch of stack is
  -- Stack array type
  type StackT is array (0 to stack_size) of Std_Logic_Vector(data_width - 1 downto 0);
  -- Actual stack storage
  signal stacka : StackT := (others => (others => '0'));
  -- Tracks the top of the stack
  signal top : Integer range 0 to stack_size + 1 := 0; 
begin
```

#### Data output

```vhdl
-- Outputs the value at the top of the stack
data_out <= stacka(top); 
```

The stack.vhdl file defines a stack, a Last-In-First-Out (`LIFO`) storage system, with customizable size and data width.
When reset (rst) is active, the stack clears all data, and the top pointer resets to zero.
Data is pushed onto the stack when the write enable (we) signal is active, incrementing the top pointer.
The pop signal removes the top element by decrementing the pointer.
The output (data_out) always shows the current top value.
This stack is efficient for temporary storage, function calls, and return addresses in processors.

### 3.5 UART (`uart.vhdl`)

The `uart.vhdl` file implements a Universal Asynchronous Receiver-Transmitter (UART) module tailored for the DE10-Nano board. It enables serial communication by converting parallel data to serial for transmission (`tx`) and serial data to parallel for reception (`rx`). The module operates at a standard baud rate of 9600 bps and is synchronized with the system clock of 50 MHz.

#### Baud rate generator

The baud rate generator divides the system clock (clk) to produce a slower clock signal (baud_clk) that matches the desired baud rate. The formula for the divider is:

$$Divider = \frac{SystemClock}{BaudRate}$$

For the DE10-Nano board:

$$Divider = \frac{50MHz}{9600bps} = 5208$$ 

```vhdl
-- uart.vhdl
constant clk_freq : integer := 50000000;  -- System clock (50 MHz)
constant baud_rate : integer := 9600;    -- Desired UART baud rate
constant divider : integer := clk_freq / baud_rate; -- Divider value

signal baud_clk : std_logic := '0';       -- Baud clock signal
signal baud_counter : integer range 0 to divider := 0;

-- Baud Clock Process
process(clk, reset)
begin
    if reset = '1' then
        baud_counter <= 0;
        baud_clk <= '0';
    elsif rising_edge(clk) then
        if baud_counter = divider - 1 then
            baud_counter <= 0;
            baud_clk <= not baud_clk;    -- Toggle baud clock
        else
            baud_counter <= baud_counter + 1;
        end if;
    end if;
end process;
```

This process creates a clock signal that controls the speed of data transmission and reception.

#### Transmitter (`tx`)

The transmitter converts 8-bit parallel input (tx_data) into a 10-bit serial frame, consisting of:

- A start bit (0).
- 8 data bits.
- A stop bit (1).

The transmission process moves through four states: IDLE, START, DATA, and STOP.

```vhdl
-- uart.vhdl
process(baud_clk, reset)
begin
    if reset = '1' then
        tx <= '1'; -- Idle state is high
        tx_state <= IDLE;
    elsif rising_edge(baud_clk) then
        case tx_state is
            when IDLE =>
                if tx_start = '1' then
                    tx_reg <= '0' & tx_data & '1'; -- Add start and stop bits
                    tx_state <= START;
                end if;
            when START =>
                tx <= tx_reg(0);                   -- Transmit start bit
                tx_reg <= tx_reg(9 downto 1) & '0';
                tx_state <= DATA;
            when DATA =>
                tx <= tx_reg(0);                   -- Transmit data bits
                tx_reg <= tx_reg(9 downto 1) & '0';
                if tx_bit_count < 7 then
                    tx_bit_count <= tx_bit_count + 1;
                else
                    tx_state <= STOP;
                end if;
            when STOP =>
                tx <= '1';                         -- Transmit stop bit
                tx_state <= IDLE;
        end case;
    end if;
end process;
```

#### Receiver (`rx`)

The receiver listens for a start bit (`0`) to begin receiving data. It captures 8 data bits into a shift register and validates the stop bit (`1`).

```vhdl
-- uart.vhdl
process(baud_clk, reset)
begin
    if reset = '1' then
        rx_state <= IDLE;
        rx_done <= '0';
    elsif rising_edge(baud_clk) then
        case rx_state is
            when IDLE =>
                if rx = '0' then -- Detect start bit
                    rx_state <= START;
                end if;
            when START =>
                if rx = '0' then -- Confirm start bit
                    rx_state <= DATA;
                else
                    rx_state <= IDLE; -- False start
                end if;
            when DATA =>
                rx_shift_reg(rx_bit_count) <= rx; -- Capture data bits
                if rx_bit_count < 7 then
                    rx_bit_count <= rx_bit_count + 1;
                else
                    rx_state <= STOP;
                end if;
            when STOP =>
                if rx = '1' then -- Validate stop bit
                    rx_data <= rx_shift_reg;      -- Store received data
                    rx_done <= '1';               -- Signal reception complete
                end if;
                rx_state <= IDLE;
        end case;
    end if;
end process;
```

The UART module supports real-time communication with a terminal, allowing input via the rx pin. Data received from the terminal is converted from serial to parallel and made available as rx_data, with the rx_done flag indicating completion. The transmitter converts parallel data into serial format, adding start and stop bits for synchronization. This design enables efficient terminal input handling for debugging, command input, or interfacing with DE10-Nano device.

## 4. Test bench

The [test benches](https://github.com/NeuroCorgi/vm-in-hardware/tree/main/TestBench) provided validate the functionality of key components in the system, including memory, processor, register bank, and stack. Each test bench is tailored to ensure that the components operate as expected under various conditions. The memory test bench verifies data retrieval from specific addresses initialized from a hex file, confirming proper memory mapping and reset behavior. The processor test bench evaluates instruction fetching, decoding, and execution. The register bank test bench tests read and write operations to registers, ensuring data integrity and correct updates. Lastly, the stack test bench validates push and pop operations, ensuring proper LIFO behavior. Together, these test benches confirm the correctness and robustness of the design, making it ready for deployment on the DE10-Nano board.

## 4. Executing flow

![execution](img/image.png)
The system executes in several stages, from setup and self-test to running the game.

### Compilation and Setup

The project is compiled using the make command, which initializes the processor's test bench.

```bash
make -C TestBench run TARGET=processor
```

During compilation, ghdl compiles and runs the test bench. Assertion warnings about NUMERIC_STD.TO_INTEGER appear but default to zero.

### 4.1 Self-Test Execution

The self-test checks the processor and provides a completion code upon success.

```plaintext
Self-test complete, all tests pass
The self-test completion code is: BNCyODLfQkIL
```

### 4.2 Game Initialization

After passing the self-test, the game begins. The player sees an introductory message and starts the adventure.

```plaintext
== Foothills ==
You find yourself standing at the base of an enormous mountain...
Things of interest here:
- tablet
Exits:
- doorway
- south
```

## 5. Conclusion

This embedded systems assignment demonstrates the design and implementation of a fully functional system for the DE10-Nano board using VHDL. The project integrates key components—processor, memory, register bank, stack, and UART—into a cohesive and modular system. Each component has been designed to perform a specific role, contributing to the system's overall functionality.
The processor is the control unit, responsible for fetching, decoding, and executing instructions while coordinating with other components. The memory stores program instructions and data, initialized from a hex file for easy configuration. The register bank provides fast, temporary storage for arithmetic and logic operations, ensuring efficient data handling. The stack manages function calls, temporary data, and control flow through a robust push/pop mechanism. Finally, the UART enables serial communication, allowing real-time input from a terminal and output to external devices, enhancing the system’s interactivity and usability.
This project highlights the practical application of embedded systems concepts on the DE10-Nano board, showcasing the integration of digital components in VHDL to create a robust and scalable system. The inclusion of UART adds an interactive feature, making the design suitable for debugging and interfacing with external devices. The assignment successfully demonstrates the principles of modularity and efficient hardware design, providing a solid foundation for further exploration in embedded systems development.