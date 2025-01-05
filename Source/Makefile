GHDL_OPTS=-fsynopsys --std=08
LIB_NAME=src
TARGET=system

all: elaborate

elaborate: analyze
	ghdl -e ${GHDL_OPTS} --work=${LIB_NAME} ${TARGET}

analyze:
	ghdl -a ${GHDL_OPTS} --work=${LIB_NAME} system.vhdl processor.vhdl memory.vhdl register_bank.vhdl stack.vhdl ring_buffer.vhdl

