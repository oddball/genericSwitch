ifneq ($(wildcard vmakefile),)
include vmakefile
endif

compile: clean
	test -d work || vlib work
	vlog sv_pkg/genericSwitchPkg.sv +incdir+rtl/
	vlog tb/*.sv rtl/*.sv ../genMem/rtl/*.v \
	+incdir+rtl/ +incdir+../genMem/generated/
	vmake work > vmakefile


.PHONY: whole_library

sim: whole_library
	vsim -c tb -novopt -do "run -all; quit -force";

gui: whole_library
	vsim tb -voptargs="+acc" -debugDB -do "do do/run_all.do";

.PHONY: whole_library

indent:
	emacs -batch -l ~/.emacs rtl/*.sv tb/*.sv -f verilog-batch-indent

clean:
	rm -rf work transcript vsim.wlf vmakefile vsim.dbg



