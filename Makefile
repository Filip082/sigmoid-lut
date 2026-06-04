# ==============================================================================
#  Vivado CLI Makefile — sigmoid LUT
# ==============================================================================

SRC     = src/sigmoid_lut.sv $(wildcard sim/*.sv)
TOP     = top
SNAP    = top_snap
HEX     = data/sigmoid.hex
PYTHON  = venv/bin/python3

XVLOG   = xvlog --sv
XELAB   = xelab --debug typical
XSIM    = xsim

# ==============================================================================
#  Targets
# ==============================================================================

.PHONY: all
all: lut
	sim

.PHONY: environment
environment:
	@echo "--- Enter Virtual Environment ---"
	distrobox enter vivado-box

venv/bin/python3: requirements.txt
	@echo "--- Setting up venv ---"
	python3 -m venv venv
	venv/bin/pip install -q -r requirements.txt

.PHONY: lut
lut: venv/bin/python3
	@echo "--- Generating LUT hex ---"
	@mkdir -p data
	$(PYTHON) scripts/gen_lut.py

.PHONY: sim
sim:
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
