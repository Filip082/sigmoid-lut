# ==============================================================================
#  Vivado CLI Makefile — sigmoid LUT
# ==============================================================================

SRC     = src/sigmoid_lut.sv sim/tb.sv
TOP     = tb
SNAP    = tb_snap
HEX     = data/sigmoid.hex

XVLOG   = xvlog --sv
XELAB   = xelab --debug typical
XSIM    = xsim

# ==============================================================================
#  Targets
# ==============================================================================

.PHONY: all
all: sim

.PHONY: environment
environment:
	@echo "--- Enter Virtual Environment ---"
	distrobox enter vivado-box

.PHONY: lut
lut:
	@echo "--- Generating LUT hex ---"
	python3 scripts/gen_lut.py

.PHONY: sim
sim: lut
	@echo "--- Compiling ---"
	$(XVLOG) $(SRC)
	@echo "--- Elaborating ---"
	$(XELAB) $(TOP) -s $(SNAP)
	@echo "--- Simulating ---"
	$(XSIM) $(SNAP) --runall

.PHONY: wave
wave:
	vivado xsim.wdb &

.PHONY: clean
clean:
	@echo "--- Cleaning ---"
	rm -rf xsim.dir ./*.log ./*.pb ./*.jou ./*.wdb $(HEX)
