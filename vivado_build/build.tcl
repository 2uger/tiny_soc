set PROJECT_NAME tiny_soc
set PROJECT_CONSTRAINT_FILE ./constraints.xdc
set HDL_SOURCE ../hdl
set SOURCE_FILES [list \
    "$HDL_SOURCE/picorv32.v"\
    "$HDL_SOURCE/wb_tiny_soc.v"\
    "$HDL_SOURCE/wb_uart.v"\
    "$HDL_SOURCE/wb_memory.v"\
    "$HDL_SOURCE/wb_gpio.v"\
    "$HDL_SOURCE/wb_timer.v"\
    "$HDL_SOURCE/wb_interconnect.v"\
    "$HDL_SOURCE/mux.v"\
    "$HDL_SOURCE/demux.v"\
]
set DIR_OUTPUT ./build
file mkdir ${DIR_OUTPUT}

create_project -force ${PROJECT_NAME} ${DIR_OUTPUT}/${PROJECT_NAME} -part xc7a35tlcsg324-2L

# Read source files.
add_files -fileset sources_1 $SOURCE_FILES
add_files -fileset constrs_1 -quiet ${PROJECT_CONSTRAINT_FILE}

# Setup synthesis strategy and properties.
set_property strategy Flow_AreaOptimized_high [get_runs synth_1]
# Setup implementation strategy and properties.
set_property strategy Performance_ExtraTimingOpt [get_runs impl_1]

# Launch Synthesis and wait on completion
launch_runs synth_1 -jobs 32
wait_on_run synth_1
open_run synth_1 -name netlist_1

# Generate a timing and power reports and write to disk.
# report_timing_summary -delay_type max -report_unconstrained -check_timing_verbose -max_paths 10 -input_pins -file ${DIR_OUTPUT}/syn_timing.rpt
# report_power -file ${DIR_OUTPUT}/syn_power.rpt

# Launch Implementation and wait on completion.
launch_runs impl_1 -to_step write_bitstream -jobs 32
wait_on_run impl_1

# Generate a timing and power reports and write to disk, comment out the open_run for batch mode.
open_run impl_1
# report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -max_paths 10 -input_pins -file ${DIR_OUTPUT}/imp_timing.rpt
# report_power -file ${DIR_OUTPUT}/imp_power.rpt

# Output hardware description and bitsream file.
file mkdir ${DIR_OUTPUT}/products
write_hw_platform -fixed -force -file ${DIR_OUTPUT}/products/system_top.xsa
write_bitstream -force ${DIR_OUTPUT}/products/bit.bit

exit
