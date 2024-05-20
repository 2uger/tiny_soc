
# Give the user some easy overrides for local configuration quirks.
# If you change one of these and it breaks, then you get to keep both pieces.
SHELL = bash
PYTHON = python3
VERIBLE = verible-verilog-
VERILATOR = verilator
ICARUS_SUFFIX =
IVERILOG = iverilog$(ICARUS_SUFFIX)
VVP = vvp$(ICARUS_SUFFIX)
VIVADO_BUILD_DIR = vivado_build

FIRMWARE_OBJS = firmware/start.o firmware/main.o firmware/print.c firmware/gpio.c firmware/timer.c firmware/irq.c
GCC_WARNS  = -Werror -Wall -Wextra -Wshadow -Wundef -Wpointer-arith -Wcast-qual -Wcast-align -Wwrite-strings
GCC_WARNS += -Wredundant-decls -Wstrict-prototypes -Wmissing-prototypes -pedantic # -Wconversion
TOOLCHAIN_PREFIX = riscv64-unknown-elf-
COMPRESSED_ISA = C

# Add things like "export http_proxy=... https_proxy=..." here
GIT_ENV = true

test: testbench.vvp firmware/firmware.hex
	$(VVP) -N $<

test_vcd: testbench.vvp firmware/firmware.hex
	$(VVP) -N $< +vcd +trace +noerror

test_verilator:
	@verilator  -Wall --trace -cc hdl/wb_interconnect.v -Ihdl --exe testbench/tb_wb_interconnect.cpp -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM
	@make -C obj_dir/ -f Vwb_interconnect.mk Vwb_interconnect
	@./obj_dir/Vwb_interconnect

	@verilator  -Wall --trace -cc hdl/wb_memory.v -Ihdl --exe testbench/tb_wb_memory.cpp -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM
	@make -C obj_dir/ -f Vwb_memory.mk Vwb_memory
	@./obj_dir/Vwb_memory

testbench.vvp: testbench.v hdl/picorv32.v hdl/wb_tiny_soc.v hdl/wb_uart.v hdl/wb_memory.v hdl/wb_timer.v hdl/wb_gpio.v hdl/wb_interconnect.v hdl/demux.v hdl/mux.v
	$(IVERILOG) -o $@ -DDEBUGREGS $(subst C,-DCOMPRESSED_ISA,$(COMPRESSED_ISA)) $^
	chmod -x $@

firmware/firmware.hex: firmware/firmware.bin firmware/makehex.py
	$(PYTHON) firmware/makehex.py $< 32768 > $@

firmware/firmware.bin: firmware/firmware.elf
	$(TOOLCHAIN_PREFIX)objcopy -O binary $< $@
	chmod -x $@

firmware/firmware.elf: $(FIRMWARE_OBJS) firmware/link.ld
	$(TOOLCHAIN_PREFIX)gcc -Os -mabi=ilp32 -march=rv32im$(subst C,c,$(COMPRESSED_ISA)) -ffreestanding -nostdlib -o $@ \
		-Wl,--build-id=none,-Bstatic,-T,firmware/link.ld,--strip-debug \
		$(FIRMWARE_OBJS) -lgcc
	chmod -x $@

firmware/start.o: firmware/start.S
	$(TOOLCHAIN_PREFIX)gcc -c -mabi=ilp32 -march=rv32im$(subst C,c,$(COMPRESSED_ISA)) -o $@ $<

firmware/%.o: firmware/%.c
	$(TOOLCHAIN_PREFIX)gcc -c -mabi=ilp32 -march=rv32i$(subst C,c,$(COMPRESSED_ISA)) -Os --std=c99 $(GCC_WARNS) -ffreestanding -nostdlib -o $@ $<

clean:
	rm -f firmware/{firmware.elf,firmware.hex,firmware.bin} firmware/*.o
	rm -f firmware/*.o
	rm -f *.vcd *.vvp
	rm -rf obj_dir/

build:
	@echo "Build whole vivado project."
	$(MAKE) -C $(VIVADO_BUILD_DIR) build

build_clean:
	@echo "Remove all artifacts after build, remove logs."
	$(MAKE) -C $(VIVADO_BUILD_DIR) clean
	rm -rf *.jou *.log

lint:
	@echo "RUN verilator lint."
	@$(VERILATOR) --lint-only -Wall hdl/tiny_soc.v hdl/uart.v hdl/gpio.v hdl/timer.v hdl/wb_memory.v
	@echo -e "\n\nRUN verible lint."
	$(VERIBLE)lint hdl/tiny_soc.v hdl/uart.v

format:
	@$(VERIBLE)format hdl/uart.v hdl/uart.v --inplace --indentation_spaces=4
