# Clock signal
set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports {clk}];

#Switches
set_property -dict { PACKAGE_PIN A8    IOSTANDARD LVCMOS33 } [get_ports { resetn }];

#GPIO
set_property -dict { PACKAGE_PIN H5    IOSTANDARD LVCMOS33 } [get_ports { gpio_o[0] }]; # LD4
set_property -dict { PACKAGE_PIN J5    IOSTANDARD LVCMOS33 } [get_ports { gpio_o[1] }]; # LD5
set_property -dict { PACKAGE_PIN T9    IOSTANDARD LVCMOS33 } [get_ports { gpio_o[2] }]; # LD6
set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports { gpio_o[3] }]; # LD7
set_property -dict { PACKAGE_PIN D9    IOSTANDARD LVCMOS33 } [get_ports { gpio_o[4] }]; # BTN0
set_property -dict { PACKAGE_PIN C9    IOSTANDARD LVCMOS33 } [get_ports { gpio_o[5] }]; # BTN1
set_property -dict { PACKAGE_PIN B9    IOSTANDARD LVCMOS33 } [get_ports { gpio_o[6] }]; # BTN2
set_property -dict { PACKAGE_PIN B8    IOSTANDARD LVCMOS33 } [get_ports { gpio_o[7] }]; # BTN3

set_property -dict { PACKAGE_PIN D10 IOSTANDARD LVCMOS33 } [get_ports { ser_tx_o }];
set_property -dict { PACKAGE_PIN A9  IOSTANDARD LVCMOS33 } [get_ports { ser_rx_i }];

