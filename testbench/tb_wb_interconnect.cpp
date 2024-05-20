#include <cstdlib>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include <Vwb_interconnect.h>
#include <Vwb_interconnect___024root.h>

#define WB_N_SLAVES   (4)
#define WB_ADDR_RAM   (0x2000)
#define WB_ADDR_UART  (0x9000)
#define WB_ADDR_GPIO  (0x9100)
#define WB_ADDR_TIMER (0x9200)

#define WB_SEL_RAM   (0b0001)
#define WB_SEL_UART  (0b0010)
#define WB_SEL_GPIO  (0b0100)
#define WB_SEL_TIMER (0b1000)

uint8_t one_hot_to_dec[] = {1, 1, 2, 0, 3, 0, 0, 0, 4};

void dut_cycle(Vwb_interconnect *dut, VerilatedVcdC *m_trace, vluint64_t &sim_time)
{
    dut->clk = 0;
    dut->eval();

    dut->clk = 1;
    dut->eval();
    m_trace->dump(sim_time++);

    dut->clk = 0;
    dut->eval();
    m_trace->dump(sim_time++);
}

int main(int argc, char **argv, char **env)
{
    Verilated::commandArgs(argc, argv);

    Vwb_interconnect *dut = new Vwb_interconnect;
    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 5);
    m_trace->open("wavefrom.vcd");

    std::cout << "Start test for wishbone interconnect." << "\n";

    vluint64_t sim_time = 0;
    dut->eval();

    /* "Constant" values. */
    dut->wbs_cyc_i = 1;
    dut->wbs_stb_i = 1;
    dut->wbs_we_i = 1;
    dut->wbs_data_i = 0x9999;
    dut->wbs_sel_i = 0b1111;

    std::vector<std::vector<int>> slaves = {
        {WB_ADDR_RAM, WB_SEL_RAM},
        {WB_ADDR_UART, WB_SEL_UART},
        {WB_ADDR_GPIO, WB_SEL_GPIO},
        {WB_ADDR_TIMER, WB_SEL_TIMER}
    }; 
    for (auto &slave : slaves) {
        dut->wbs_addr_i = slave[0];

        dut->eval();
        assert(dut->rootp->wb_interconnect__DOT__sel == slave[1]);
        assert(dut->wbm_cyc_o == slave[1]);
        assert(dut->wbm_stb_o == slave[1]);
        assert(dut->wbm_we_o == slave[1]);

        assert(dut->wbm_addr_o[one_hot_to_dec[slave[1]] - 1] == slave[0]);
        assert(dut->wbm_data_o[one_hot_to_dec[slave[1]] - 1] == 0x9999);
        assert((((dut->wbm_sel_o) >> (WB_N_SLAVES * (one_hot_to_dec[slave[1]] - 1))) & 0xf) == 0b1111);
    
        dut_cycle(dut, m_trace, sim_time);
    }
    dut_cycle(dut, m_trace, sim_time);

    std::cout << "All tests passed for wishbone interconnect!!!" << "\n";

    m_trace->close();
    delete dut;

    return 0;
}

