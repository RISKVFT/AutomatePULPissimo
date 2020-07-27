# AutomatePULPissimo

Here you can find a series of bash script aimed to automatize the PULPissimo installation and debugging processes for the ZCU102 board (and some other boards).

## Software and Hardware requirements
For installation of PULPissimo project, some devices, softwares and packages are required. In particular, before start you need:
- ZCU102,  ZCU104,  Genesys2,  Zedboard,  Nexys or Nexys_video board (we used `ZCU102`);
- microUSB-USB cables;
- JTAG adapter supporting openOCD (we used olimex-arm-usb-tiny-h programmer and debugger adapter);
- Ubuntu 18.04 (or Ubuntu 16.04) with at least 97GB available (85GB for Vivado and 12GB for Pulpissimo project);
- Vivado 2019.2 (or older);

For example, we tested the installation of PULPissimo project in a virgin `Virtual Machine with Ubuntu 16.04.4 LTS 64-bit and 120GB of free disk space`.

## What you will get at the end of the process
At the end of the installation process, you will have the PULPissimo environment correctly installed, meaning that the following tools will be downloaded and installed (and configured for the ZCU102 board by default):
- PULPissimo SDK;
- pulp riscv-gnu-toolchain;
- pulp-builder;
- OpenOCD (correct version);
- pulpissimo;
- pulp rt example applications;
- virtual platform;


## Example of use
After having cloned this repository, we install all scripts
with:
```
./install.sh
```
`pulp_install`, `pulp_app` and `pulp_script`  are now available in whatever shell after shell restart.
We now create a pulpissimo project folder for installation:
```bash
export PULP_DIR="pulp_riscv"
mkdir $PULP_DIR 
```

### Installation of PULPissimo project (WARNING LONG OPERATION!!!)
```bash
cd $PULP_DIR
pulp_install -v -c pulp -t y
```
With this command the following tools will be installed:
- pulp-riscv-gnu-toolchain, env variable sets: `PULP_RISCV_GCC_TOOLCHAIN`, `VSIM_PATH`
- pulp-sdk
- pulp-builder
- pulpissimo 
- pulp-rt-example
- virtual platform

 All variables set will be saved in `~/.bash_profile` so they will be automatically loaded each time a new shell is created.

Now you should connect all usb cables to the board board, for zcu102: `J2 as fpga JTAG programmer, J83 as UART interface, and J55 (pin 1,3,5,7,9) as pulpissimo programmer/debugger`!!
### Bitstream generation   (WARNING LONG OPERATION!!!)
For bitstream generation and download into fpga you need 
the vivado executable available in the shell environment. Usually
this is not done by Vivado installation, so you can easly add
`/tools/Xilinx/Vivado/<vivado_version>/bin` to $PATH executable.
If you don't have vivado executable in $PATH environment, please set it with  
```bash
export PATH=$PATH:/tools/Xilinx/Vivado/<vivado_version>/bin".
```
Then this command generates the bitstream for fpga download and binary file for flashing:
```
pulp_app -s
```
### Download bitstream into fpga
Using this command the bitstream will be downloaded using J2 connector (in zcu102 board).
```
pulp_app -d
```
### Build of sdk and openocd patch (WARNING LONG OPERATION!!!)
```
pulp_app -b
```
### Compiling hello application
This command compiles application in `./pulp-rt-examples/hello`
```
pulp_app -c "hello"
```
### Verify USB connection
With this command you will be able to understand which is the correct USB used as UART by pulpissimo, it is connected to 
J83 connector in the zcu102 board.
```
pulp_app -u i
```
### Download and debug application on pulpissimo!!!!
Your board name will be called `BOARD` and should be among: zcu102, zcu104, genesys2, zedboard, nexys and nexys_video.
Your connector name will be `CONNECTOR_NAME` and you have to place openOCD config file, for JTAG programmer, in `./pulpissimo/fpga/pulpissimo-BOARD/` and name it `$CONNECTOR_NAME.cfg`.
This command will start the debug process of hello application on the selected board, with the selected JTAG programmer, using `USB` as UART to communicate with pulpissimo. 
```bash
pulp_app -o $BOARD -r $CONNECTOR_NAME -u $USB -t "hello"
```

### Faster alternatives
If you know the `correct UART usb`, you have connected all the three connectors, you have `already vivado in PATH` variable and you have `./pulpissimo/fpga/pulpissimo-$BOARD/$CONNECTOR_NAME.cfg` file, you can do all the previous operations in an atomic command:
```bash
pulp_app -s -d -b -c "hello" -o $BOARD -r $CONNECTOR_NAME -u $USB -t "hello"
```
## Files description
```bash
AutomatizePULP
	├── [pulp_script]
	│   	 ├── pulp_script.sh
	│   	 ├── pulp_install.sh
	│   	 └── pulp_app.sh
	├── [manpages]
	│  	 ├── pulp_script.1
	│  	 ├── pulp_install.1
	│   	 └── pulp_app.1
	├── [lib]
	│   	 └── ccommon.sh
	├── [bitstream]
	│   	 ├── xilinx_pulpissimo.bit
	│  	 └── xilinx_pulpissimo.bin
	├── README.md
	├── push.sh
	├── pulp_env_example.env
	├── LICENSE
	└── install.sh
```


### install.sh: 
This script simply puts pulp_app.sh and pulp_install.sh into the right directories into the filesystem to be always accessible.
It copies `pulp_script/pulp_app.sh and pulp_script/pulp_install.sh` in /usr/bin/ and manpages/pulp_app.1 and manpages/pulp_install.1 into /usr/share/man/man1.
Then it also copies lib/ccommon.sh script into custom folder `/usr/lib/bash-lib` where there are all the user defined bash functions.

### pulp_env_example.env: 
It is an example of what you can find in your personal pulp_env_example.env file once you launch the PULPissimo installation. It contains the environment variables required by the various scripts to perform a correct PULPissimo installation.

### manpages: 
In this directory are contained all man pages, there are the man of pulp_app.sh, pulp_install.sh and pulp_script.sh. You can use them after executing ./install.sh.

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
- [pulp-riscv-gnu-toolchain](https://github.com/pulp-platform/pulp-riscv-gnu-toolchain)
- [pulp-sdk](https://github.com/pulp-platform/pulp-sdk.git)
- [pulp-builder](https://github.com/pulp-platform/pulp-builder.git)
- [pulpissimo](https://github.com/pulp-platform/pulpissimo.git)
- [pulp-rt-example](https://github.com/pulp-platform/pulp-rt-examples.git)
	
For more informations look the comments inside the script and in manpages.
	
### pulp_script/pulp_app.sh:
This is the script to launch if you want to run an application on the FPGA. In particular there are different options:
- -s|--bitstream:
                create bitstream using PULPissimo_bitstream.sh
- -d|--download:
                download bitstream into board using
                make -C pulpissimo-zcu102 download
- -b|--build-sdk-openocd:
                build the sdk and opeocd patch
- -c|--compile C_APPDIR :
                create cross compiled test elf file of hello
- -t|--terminal T_APPDIR: 
                if the  terminal with openOCD, gdb and screen, 
                for screen is possible to select usb number using
                -u option
- -e|--export-variables: 
                After -b option the environment varible  are setted in .environ.env 
                file, so this action set variable find in .environ.env in ~/.bash_profile
                so that each time that a shell is open the variable are setted.
                After the execution of the action you should restart shell 
                to have variable setted. 
- -h|--help:
                print this help
- -u|--usb-for-screen USB|all|i: 
                selection of usb for minicom connection example:
                -u ttyUSB0
                all option istead screen all usb
                i option show corrently usb and their name
- -o|--board BOARD:
                selection of target board
- -r|--connector CONNECTOR_NAME:
                CONNECTOR_NAME should be the name of jtag programmer and debugger
                used to upload and debug application on pulpissimo. This 
                connector should support openOCD. This name is used to call 
                ./pulpissimo/fpga/pulpissimo-\$BOARD/\$CONNECTOR_NAME.cfg 
                as configuration of openOCD.

	
### lib/ccommon.sh:
This is a bash library file.

### pulp_script/pulp_script.sh
In this script are contained a complete use of pulp_install and pulp_app command. It is interactive and perform following action:
- Install pulpissimo project with pulp_install;
- Create pulpissimo bitstream;
- Download it into fpga;
- Build sdk and openOCD path;
- Compile hello example application;
- Open multiple terminal in order to debug this application on fpga.


### Team

- Fiore Luca
- Neri Marcello
- Ribaldone Elia

--------------------
