# AutomatizePULPissimo

Here you can find series of bash script to automatize PULPissimo installation and debug mainly on zcu102 board.

## Files description

AutomatizePULPissimo
	│
	├─install.sh			
	├─pulp_env_example.env
	├─[manpages]
	│	  │
	│	  ├─pulp_install.1
	│	  └─pulp_app.1
	│
	├─[pulp_script]
	│	│
	│	├─pulp_install.sh
	│	└─pulp_app.sh
	│
	└─[lib]
		│
		└─ccommon.sh



### install.sh: 
This script simply puts pulp_app.sh and pulp_install.sh into the right directories into the filesystem to be always accessible.<br/>
It copies pulp_script/pulp_app.sh and pulp_script/pulp_install.sh in /usr/bin/ and manpages/pulp_app.1 and manpages/pulp_install.1 into /usr/share/man/man1/.<br/>
Then it also copies lib/ccommon.sh script into custom folder /usr/lib/bash-lib where there are all the user defined bash functions.

### pulp_env_example.env: 
It is an example of what you can find in your personal pulp_env_example.env file once you launch the PULPissimo installation. It contains the environment variables required by the various scripts to perform a correct PULPissimo installation.

### manpages/pulp_app.1 and manpages/pulp_install.1: 
Are the man files for pulp_app.1 and pulp_install.sh. You can use them after executing ./install.sh

### pulp_script/pulp_install.sh:
This is the script where all the necessary repositories for toolchain, sdk, pulp-builder and pulpissimo are cloned.<br/>
It checks at the beginning the current OS and if different from Ubuntu or CentOS it exits because for the moment everything  has been verified only for these two OS.<br/>

The different options are:

- -v: verbose option, script print many others informations
- -c: This option define what cross compiler the script install:
	- pulp    	--> newlib cross-compiler for all pulp variants
					 This will use the multilib support to build the libraries for 
					 the various cores (riscy, zeroriscy and so on). The right libraries 
					 will be selected depending on which compiler options you use.
	- newlib  	--> Newlib cross-compiler, You should now be able
					 to use riscv-gcc and its cousins.
	- linux  	--> Linux cross compiler 64 bit
					 Supported architectures are rv64i plus standard extensions (a)tomics, 
					 (m)ultiplication and division, (f)loat, (d)ouble, or (g)eneral for MAFD.
					 Supported ABIs are ilp32 (32-bit soft-float), ilp32d (32-bit hard-float), ilp32f 
					 (32-bit with single-precision in registers and double in memory, niche use only), 
					 lp64 lp64f lp64d (same but with 64-bit long and pointers).
	- linux32 	--> Linux cross compiler 32 bit
					 Supported architectures are rv32i plus standard extensions (a)tomics, 
					 (m)ultiplication and division, (f)loat, (d)ouble, or (g)eneral for MAFD.
					 Supported ABIs are ilp32 (32-bit soft-float), ilp32d (32-bit hard-float), ilp32f 
					 (32-bit with single-precision in registers and double in memory, niche use only), 
					 lp64 lp64f lp64d (same but with 64-bit long and pointers).
	- linuxm  	--> Linux cross-compiler, both 32 and 64 supported
- -p: selection of usb for screen connection
	- 0 --> start from scratch
	- 1	--> start after the toolchain
	- 2	--> start after the sdk
	- 3 --> start after pulp-builder
	- 4	--> test (hello)
	- 5	--> virtual platform
- -t: Decide if install test suite or not<br/>

Useful links:
- https://github.com/pulp-platform/pulp-riscv-gnu-toolchain
- https://github.com/pulp-platform/pulp-sdk.git
- https://github.com/pulp-platform/pulp-builder.git
- https://github.com/pulp-platform/pulpissimo.git
- https://github.com/pulp-platform/pulp-rt-examples.git
	
For more informations look the comments inside the script.
	
### pulp_script/pulp_app.sh:
This is the script to launch if you want to run an application on the FPGA. In particular there are different options:
- -o: selection of target board
- -b: create bitstream using PULPissimo_bitstream.sh
- -d: download bitstream into board using	"make -C pulpissimo-[board] download
- -c: create cross compiled test elf file of hello
- -u: selection of usb for screen connection
	- -u ttyUSB0	--> open one shell with screen on ttyUSB0
	- -u all  	--> open many shell with screen on all usb
	- -u i 		--> show current usb and their name
- -t:
	
### lib/ccommon.sh:

--------------------


### Team


--------------------
