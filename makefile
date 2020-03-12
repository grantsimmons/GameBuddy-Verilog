#SIMULATOR/COMPILER (IVERILOG) PARAMS
CC = iverilog
ASM = vvp
RUNNAME = run
RUNFILES = rtl/alu.v
TESTBENCH = sim/tb.v
CFLAGS = -o $(RUNNAME) -Wall -Winfloop -g2012
TESTBENCHOUT = data/dumpfile.vcd

#WAVEFORM VIEWER (GTKWAVE) PARAMS
WAVEVIEWER = gtkwave
VFLAGS = -O logs/$@.log

#SYNTHESIS (YOSYS) PARAMS
SYNTHESIS = yosys
SYNTHFRONTEND = verilog
SYNTHBACKEND = ilang
ifeq ($(SYNTHBACKEND), ilang)
SYNTHBACKENDEXT = il
else ifeq ($(SYNTHBACKEND), verilog)
SYNTHBACKENDEXT = v
endif
SYNTHFILE = data/synthesize.$(SYNTHBACKENDEXT)
SYNTHOUT = -o $(SYNTHFILE) -b $(SYNTHBACKEND)
SYNTHSCRIPT = scripts/synthesize.ys
SYNTHFLAGS = -Q -q
SYNTHLOG = -l logs/$@.log -t
BDSHOW = show -format dot -viewer xdot -prefix data/show
DOT = data/show.dot
DOTVIEWER = xdot

proj:
	mkdir rpts logs data
	
$(RUNNAME): $(RUNFILES) $(TESTBENCH)
	$(CC) $(CFLAGS) $(RUNFILES) $(TESTBENCH)
	$(ASM) $(RUNNAME) > rpts/$(RUNNAME).rpt

$(RUNNAME)_notb: $(RUNFILES)
	$(CC) $(CFLAGS) $(RUNFILES)
	$(ASM) $(RUNNAME) > rpts/$(RUNNAME)_notb.rpt

wave: $(TESTBENCHOUT)
	$(WAVEVIEWER) $(TESTBENCHOUT) $(VFLAGS) &

synth: $(RUNFILES)
	$(SYNTHESIS) $(RUNFILES) $(SYNTHSCRIPT) $(SYNTHOUT) $(SYNTHFLAGS) $(SYNTHLOG)

netlist: $(SYNTHFILE)
	$(SYNTHESIS) -f $(SYNTHBACKEND) $(SYNTHFILE) -o data/synthesize.v $(SYNTHFLAGS) $(SYNTHLOG)

bd: $(RUNFILES)
	$(SYNTHESIS) -f $(SYNTHBACKEND) $(SYNTHFILE) -p "$(BDSHOW)" $(SYNTHFLAGS) $(SYNTHLOG)

view: $(DOT)
	$(DOTVIEWER) $(DOT) &
