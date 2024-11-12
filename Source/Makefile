GHDL_OPTS=-fsynopsys --std=08
LIB_NAME=src

all: elaborate

elaborate: analyze
	ghdl -e ${GHDL_OPTS} --work=${LIB_NAME} ${TARGET}

analyze:
	ghdl -a ${GHDL_OPTS} --work=${LIB_NAME} processor.vhdl memory.vhdl register_bank.vhdl stack.vhdl

