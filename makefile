ACTIVATE_DIR ?= latest
STIM_NUM_OPS ?= 2000

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

#SOFTWARE EMULATOR
SOFTEMU_DIR = /mnt/d/Git/GameBuddy/source
SOFTEMU_VERIF = $(SOFTEMU_DIR)/verif.out
SOFTEMU_TV = $(SOFTEMU_DIR)/stim.tv
HARDEMU_TV = sim/stim/active/stim.tv


$(RUNNAME): $(RUNFILES) $(TESTBENCH) proj
	$(CC) $(CFLAGS) $(RUNFILES) $(TESTBENCH)
	$(ASM) $(RUNNAME) > $(RPTS_DIR)/$(RUNNAME).rpt

.PHONY: proj
proj:
	mkdir -p $(SIM_DIR) $(RTL_DIR) $(RPTS_DIR) $(DATA_DIR) $(ALIAS_DIR) $(LOGS_DIR) $(SCRIPTS_DIR)

.PHONY: wave
wave: $(TESTBENCHOUT) $(VIEW)
	$(WAVEVIEWER) $(TESTBENCHOUT) $(VFLAGS) $(VIEW) &

.PHONY: synth
synth: $(RUNFILES) $(SYNTHSCRIPT)
	$(SYNTHESIS) $(RUNFILES) $(SYNTHSCRIPT) $(SYNTHOUT) $(SYNTHFLAGS) $(SYNTHLOG)

.PHONY: netlist
netlist: $(DATA_DIR)/synthesize.v

$(DATA_DIR)/synthesize.v: $(SYNTHFILE)
	$(SYNTHESIS) -f $(SYNTHBACKEND) $(SYNTHFILE) -o $(DATA_DIR)/synthesize.v $(SYNTHFLAGS) $(SYNTHLOG)

.PHONY: bd
bd: synth
	$(SYNTHESIS) -f $(SYNTHBACKEND) $(SYNTHFILE) -p "$(BDSHOW)" $(SYNTHFLAGS) $(SYNTHLOG)

.PHONY: view
view: $(DOT)
	$(DOTVIEWER) $(DOT) &

.PHONY: gen_rand_stim
gen_rand_stim: $(ALIAS_DIR)/ops.alias $(ALIAS_DIR)/ops_full.alias $(ALIAS_DIR)/ops_full_supported.alias $(ALIAS_DIR)/supported.alias
	python3 $(SCRIPTS_DIR)/asm_to_bit.py -n $(STIM_NUM_OPS) -r -e

.PHONY: activate_stim
activate:
	rm -f sim/stim/active
	ln -s $(ACTIVATE_DIR) sim/stim/active

$(HARDEMU_TV): $(SOFTEMU_VERIF) activate
	$(SOFTEMU_VERIF)
	cp $(SOFTEMU_TV) $(HARDEMU_TV)

.PHONY: gen_vector
gen_vector: $(HARDEMU_TV)

.PHONY: run_new_rand
run_new_rand: gen_rand_stim gen_vector run
