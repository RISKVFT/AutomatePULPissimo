#!/bin/bash
# This script show an example of use of script created to 
# automatize PULPissimo installation in order to speed up
# the setup of architecture and give a faster development
# environment, remember that at the moment the scripts are 
# only tested on zcu102 with olimex-arm-usb-tiny-h connector
# so many option are used but not deeply tested due to hardware
# leak. So for these reason read carefully the readme and the 
# man page of scripts to find solution for you problem.
#

##### SCRIPT USE
# After have cloned this repository you could install all scripts
# with 
# >> ./install.sh
# now pulp_install, pulp_app and pulp_script  are available in whatever shell
# after shell restart
# You could now create a pulpissimo project folder for installation
# >> export PULP_DIR="pulp_riscv"
# >> mkdir $PULP_DIR 

### Installation of PULPissimo project WARNING LONG OPERATION!!!
	# cd $PULP_DIR
pulp_install -v -c pulp -t y
	# will be installed:
	# - pulp-riscv-gnu-toolchain
	# 	env variable setted: PULP_RISCV_GCC_TOOLCHAIN, VSIM_PATH
	# - pulp-sdk
	# - pulp-builder
	# - pulpissimo 
	# - pulp-rt-example
	# - virtual platform
	# all variable setted will be saved in ~/.bash_profile so will be 
	# loaded at each shell start
echo "Connect all usb cable to board, for zcu102 J2 as fpga JTAG programmer, J38 as UART interface, and J55 (pin 1,3,5,7,9) as pulpissimo programmer/debugger!! press enter after have made connection"
read n
### bitstream generation   WARNING LONG OPERATION!!!
	# For bitstream generation and download into fpga you need 
	# the vivado executable available in the shell, usually
	# this is not done by vivado installation so you can easly add
	# /tools/Xilinx/Vivado/<vivado_version>/bin to $PATH executable
echo -e "If you haven't vivado exascutable in $PATH environment please set it\n export PATH=$PATH:/tools/Xilinx/Vivado/<vivado_version>/bin"
pulp_app -s

### download bistream into fpga
pulp_app -d # J2 is used

### build of sdk and openocd patch WARNING LONG OPERATION!!!
pulp_app -b

### compiling hello application
pulp_app -c "hello"

### see what is UART usb
pulp_app -u i

### download and debug application on pulpissimo!!!!
echo "Give me your board name between: zcu102,zcu104,genesys2, zedboard, nexys and nexys_video"
read BOARD
echo "Give me your connector name"
read CONNECTOR_NAME
echo "Be carfull to have placed openOCD config file in ./pulpissimo/fpga/pulpissimo-zcu102/ and named it $CONNECTOR_NAME.cfg, press enter if you have this file in correct directory!!"
echo r
echo "Give me a valid usb name which is inside /dev directory (ttyUSB0 as default)"
read USB

pulp_app -o $BOARD -r $CONNECTOR_NAME -u $USB -t "hello"


### If you know correct UART usb, have connected all three connector, you have
# already vivado in PATH variable and you have ./pulpissimo/fpga/pulpissimo-$BOARD/$CONNECTOR_NAME.cfg file, you could do all previous action in a unic command:
#  >> pulp_app -s -d -b -c "hello" -o $BOARD -r $CONNECTOR_NAME -u $USB -t "hello"
