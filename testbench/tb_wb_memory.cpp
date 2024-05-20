#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include <Vwb_memory.h>
#include <Vwb_memory___024root.h>

#define MAX_SIM_TIME (20)

void dut_cycle(Vwb_memory *dut, VerilatedVcdC *m_trace, vluint64_t &sim_time)
{
    dut->clk = 0;
    dut->eval();
    m_trace->dump(sim_time);
    sim_time++;

    dut->clk = 1;
    dut->eval();
    m_trace->dump(sim_time);
    sim_time++;
}

int main(int argc, char **argv, char **env)
{
    Vwb_memory *dut = new Vwb_memory;
    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 5);
    m_trace->open("wavefrom.vcd");

    std::cout << "Start test for memory." << "\n";

    vluint64_t sim_time = 0;
    dut->eval();

    /* Test initial block. */
    dut_cycle(dut, m_trace, sim_time);
    assert(dut->wb_data_o == 0xaa55);

    /* Wishbone write. */
    dut->wb_sel_i = 0xf;
    dut->wb_stb_i = 0x1;
    dut->wb_data_i = 0x9988;
    dut->wb_we_i = 0x1;
    dut->wb_addr_i = 0x4;
    dut_cycle(dut, m_trace, sim_time);
    dut_cycle(dut, m_trace, sim_time);

    assert(dut->wb_data_o == 0x9988);
    dut_cycle(dut, m_trace, sim_time);

    std::cout << "All tests passed for memory!!!" << "\n";

    m_trace->close();
    delete dut;

    return 0;
}

