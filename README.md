Tiny soc!  
Simplest implementation of SOC with risc-v cpu and my custom modules.  
I just like the feeling of being at hardware and software at the same time, that's the main point  
of why i'm doing that.  
Goal is to implement important parts of the SOC(memory, timer, gpio, uart...) and write firmware  
template for it. After it will works the way it should, i want iterate and go further to  
implement more advanced and mature structure of the SOC.

#### How to run:
* **make test** - compile code in firmware and run it on SOC in simulation.
* **make test_verilator** - run multiple tests in verilator environment.
* **make build** - build vivado project and run synthesis and implementation.

#### Questions and plans:
* Should i use AXI interface for modules.
* SPI flash for loading kernel or maybe PXE boot? 

