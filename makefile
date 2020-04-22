#DIRS
SIM_DIR = sim
RTL_DIR = rtl
RPTS_DIR = rpts
DATA_DIR = data
ALIAS_DIR = alias
LOGS_DIR = logs
SCRIPTS_DIR = scripts

#SIMULATOR/COMPILER (IVERILOG) PARAMS
CC = iverilog
ASM = vvp
RUNNAME = run
RUNFILES = rtl/memory.v rtl/decode.v rtl/register_file_new.v rtl/register.v rtl/alu.v rtl/top.v
#RUNFILES = fpga/7SD_Testing.srcs/sources_1/new/alu.v
#TESTBENCH = $(SIM_DIR)/tb_revised.v
TESTBENCH = $(SIM_DIR)/top_tb.v
CFLAGS = -o $(RUNNAME) -Wall -Winfloop -g2012
TESTBENCHOUT = $(DATA_DIR)/dumpfile.vcd

#WAVEFORM VIEWER (GTKWAVE) PARAMS
WAVEVIEWER = gtkwave
VFLAGS = -O $(LOGS_DIR)/$@.log -o
#WAVEFORM SAVE FILE
VIEW = $(DATA_DIR)/base.gtkw

#SYNTHESIS (YOSYS) PARAMS
SYNTHESIS = yosys
SYNTHFRONTEND = verilog
SYNTHBACKEND = ilang
ifeq ($(SYNTHBACKEND), ilang)
SYNTHBACKENDEXT = il
else ifeq ($(SYNTHBACKEND), verilog)
SYNTHBACKENDEXT = v
endif
SYNTHFILE = $(DATA_DIR)/synthesize.$(SYNTHBACKENDEXT)
SYNTHOUT = -o $(SYNTHFILE) -b $(SYNTHBACKEND)
SYNTHSCRIPT = $(SCRIPTS_DIR)/synthesize.ys
SYNTHFLAGS = -Q -q
SYNTHLOG = -l $(LOGS_DIR)/$@.log -t
BDSHOW = show -format dot -viewer xdot -prefix $(DATA_DIR)/show
DOT = $(DATA_DIR)/show.dot
DOTVIEWER = xdot

$(RUNNAME): $(RUNFILES) $(TESTBENCH) proj
	$(CC) $(CFLAGS) $(RUNFILES) $(TESTBENCH)
	$(ASM) $(RUNNAME) > $(RPTS_DIR)/$(RUNNAME).rpt

proj:
	mkdir -p $(SIM_DIR) $(RTL_DIR) $(RPTS_DIR) $(DATA_DIR) $(ALIAS_DIR) $(LOGS_DIR) $(SCRIPTS_DIR)

$(RUNNAME)_notb: $(RUNFILES)
	$(CC) $(CFLAGS) $(RUNFILES)
	$(ASM) $(RUNNAME) > $(RPTS_DIR)/$(RUNNAME)_notb.rpt

wave: $(TESTBENCHOUT)
	#$(WAVEVIEWER) $(TESTBENCHOUT) $(VFLAGS) &
	$(WAVEVIEWER) $(TESTBENCHOUT) $(VFLAGS) $(VIEW) &

synth: $(RUNFILES)
	$(SYNTHESIS) $(RUNFILES) $(SYNTHSCRIPT) $(SYNTHOUT) $(SYNTHFLAGS) $(SYNTHLOG)

netlist: $(SYNTHFILE)
	$(SYNTHESIS) -f $(SYNTHBACKEND) $(SYNTHFILE) -o $(DATA_DIR)/synthesize.v $(SYNTHFLAGS) $(SYNTHLOG)

bd: $(RUNFILES)
	$(SYNTHESIS) -f $(SYNTHBACKEND) $(SYNTHFILE) -p "$(BDSHOW)" $(SYNTHFLAGS) $(SYNTHLOG)

view: $(DOT)
	$(DOTVIEWER) $(DOT) &
