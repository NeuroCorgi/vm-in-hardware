GHDL_OPTS=-fsynopsys --std=08
LIB_NAME=test
TARGET=processor
all: elaborate

elaborate: analyze
	ghdl -e ${GHDL_OPTS} --work=${LIB_NAME} -P../Source ${TARGET}_tb

analyze:
	ghdl -a ${GHDL_OPTS} --work=${LIB_NAME} -P../Source ${TARGET}_tb.vhdl

run: elaborate
	ghdl run ${GHDL_OPTS} --work=${LIB_NAME} -P../Source ${TARGET}_tb
