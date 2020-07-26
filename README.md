# AutomatizePULP

Here you can find series of bash script to automatize PULPissimo installation and debug mainly on zcu102 board.

## Example of use
After have cloned this repository you could install all scripts
with:
```
./install.sh
```
pulp_install, pulp_app and pulp_script  are now available in whatever shell after shell restart.
You could now create a pulpissimo project folder for installation:
```
export PULP_DIR="pulp_riscv"
mkdir $PULP_DIR 
```

### Installation of PULPissimo project WARNING LONG OPERATION!!!
```
cd $PULP_DIR
pulp_install -v -c pulp -t y
```
With this command will be installed:
- pulp-riscv-gnu-toolchain, env variable setted: PULP_RISCV_GCC_TOOLCHAIN, VSIM_PATH
- pulp-sdk
- pulp-builder
- pulpissimo 
- pulp-rt-example
- virtual platform
all variable setted will be saved in ~/.bash_profile so will be loaded at each shell start.
Now you should connect all usb cable to board, for zcu102: J2 as fpga JTAG programmer, J38 as UART interface, and J55 (pin 1,3,5,7,9) as pulpissimo programmer/debugger!!
### bitstream generation   WARNING LONG OPERATION!!!
For bitstream generation and download into fpga you need 
the vivado executable available in the shell, usually
this is not done by vivado installation so you can easly add
/tools/Xilinx/Vivado/<vivado_version>/bin to $PATH executable.
If you haven't vivado exascutable in $PATH environment please set it\n export PATH=$PATH:/tools/Xilinx/Vivado/<vivado_version>/bin"
This command generate bitstream for fpga download and binary file for flashing:
```
pulp_app -s
```
### download bistream into fpga
Using this command the bitstream will be downloaded using J2 connector (in zcu102 board).
```
pulp_app -d
```
### build of sdk and openocd patch WARNING LONG OPERATION!!!
```
pulp_app -b
```
### compiling hello application
This command compile application in ./pulp-rt-examples/hello
```
pulp_app -c "hello"
```
### see what is UART usb
With this command you will be able to understand what is correct USB used ad UART
```
pulp_app -u i
```
### download and debug application on pulpissimo!!!!
Your board name will be called BOARD and should be between: zcu102,zcu104,genesys2, zedboard, nexys and nexys_video.
Your connector name will be CONNECTOR_NAME.
You have to placed openOCD config file in ./pulpissimo/fpga/pulpissimo-zcu102/ and named it $CONNECTOR_NAME.cfg.
echo "Give me a valid usb name which is inside /dev directory (ttyUSB0 as default)"
read USB

pulp_app -o $BOARD -r $CONNECTOR_NAME -u $USB -t "hello"


### If you know correct UART usb, have connected all three connector, you have
already vivado in PATH variable and you have ./pulpissimo/fpga/pulpissimo-$BOARD/$CONNECTOR_NAME.cfg file, you could do all previous action in a unic command:
```
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
- -s|--bitstream
                create bitstream using PULPissimo_bitstream.sh
- -d|--download
                download bitstream into board using
                make -C pulpissimo-zcu102 download
- -b|--build-sdk-openocd
                build the sdk and opeocd patch
- -c|--compile C_APPDIR
                create cross compiled test elf file of hello
- -t|--terminal T_APPDIR
                if the  terminal with openOCD, gdb and screen, 
                for screen is possible to select usb number using
                -u option
- -e|--export-variables
                After -b option the environment varible  are setted in .environ.env 
                file, so this action set variable find in .environ.env in ~/.bash_profile
                so that each time that a shell is open the variable are setted.
                After the execution of the action you should restart shell 
                to have variable setted. 
- -h|--help
                print this help
- -u|--usb-for-screen USB|all|i
                selection of usb for minicom connection example:
                -u ttyUSB0
                all option istead screen all usb
                i option show corrently usb and their name
- -o|--board BOARD
                selection of target board
- -r|--connector CONNECTOR_NAME
                CONNECTOR_NAME should be the name of jtag programmer and debugger
                used to upload and debug application on pulpissimo. This 
                connector should support openOCD. This name is used to call 
                ./pulpissimo/fpga/pulpissimo-\$BOARD/\$CONNECTOR_NAME.cfg 
                as configuration of openOCD.

	
### lib/ccommon.sh:
This is a bash library file.


### Team

- Fiore Luca
- Neri Marcello
- Ribaldone Elia

--------------------
