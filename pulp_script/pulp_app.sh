#!/bin/bash 

#############################################################################
####### FUNCTIONS ###########################################################
setJsonBoard(){
	BOARD=$1
	cd ./pulp-config/configs/fpgas/
        mv genesys2.json $BOARD.json
        sed -i 's/genesys2/$BOARD/g' $BOARD.json
	cd ../../../
	createBoardFile $BOARD
	mv $BOARD.sh ./configs/fpgas/pulpissimo/
}

usbInfo(){
	for sysdevpath in $(find /sys/bus/usb/devices/usb*/ -name dev); do
	    (
		syspath="${sysdevpath%/dev}"
		devname="$(udevadm info -q name -p $syspath)"
		[[ "$devname" == "bus/"* ]] && exit
		eval "$(udevadm info -q property --export -p $syspath)"
		[[ -z "$ID_SERIAL" ]] && exit
		echo "/dev/$devname - $ID_SERIAL"
	    )
	done
}

UsageExit(){
	echo -e "\
pulp_app [OPTION]   Is a bash script able to create pulp bitstream,
		    upload it into board compile application and run
		    it into board, actually zcu102 is the  default
		    board and hello is the default application.
OPTION
	-s|--bitstream
		create bitstream using PULPissimo_bitstream.sh

	-d|--download
		download bitstream into board using
<<<<<<< HEAD
		make -C pulpissimo-zcu102 download
	-b|--build-sdk-openocd
		build the sdk and opeocd patch
	-c|--compile C_APPDIR
		create cross compiled test elf file of hello
	-t|--terminal T_APPDIR
		if the  terminal with openOCD, gdb and screen, 
		for screen is possible to select usb number using
		-u option
	-e|--export-variables
		After -b option the environment varible  are setted in .environ.env 
		file, so this action set variable find in .environ.env in ~/.bash_profile
		so that each time that a shell is open the variable are setted.
		After the execution of the action you should restart shell 
		to have variable setted. 
	-h|--help
		print this help
	-u|--usb-for-screen USB|all|i
		selection of usb for minicom connection example:
		-u ttyUSB0
		all option istead screen all usb
		i option show corrently usb and their name
	-o|--board BOARD
		selection of target board
	-r|--connector CONNECTOR_NAME
		CONNECTOR_NAME should be the name of jtag programmer and debugger
		used to upload and debug application on pulpissimo. This 
		connector should support openOCD. This name is used to call 
		./pulpissimo/fpga/pulpissimo-\$BOARD/\$CONNECTOR_NAME.cfg 
		as configuration of openOCD.
=======
		make -C pulpissimo-[board] download

	-c|--compile directory_of_application
		create cross compiled test elf file of hello

	-u|--usb-for-screen usb_name|all|i
		selection of usb for screen connection example:
		-u ttyUSB0
		all option istead screen all usb
		i option show current usb and their name
	-t|--terminal directory_of_application
		opens 3 terminals for communication and debugging 
		with FPGA through UART, gdb and OpenOCD 
		for screen is possible to select usb number using
		-u option
>>>>>>> 64e7cd01f0da5e303c120422fa68cafb4d400657
	directory_of_application will be placed in this path
	./pulp-rt-examples/directory_of_application/
	in order to find application directory, while in this path
	./pulp-rt-examples/directory_of_application/build/pulpissimo/test/test
	to find executable.
"
	exit 1;	
}

createBoardFile(){
	BOARD=$1
	echo "#!/bin/bash
BOARD=VARIABLE

scriptDir=\"\$\(dirname \"\$\(readlink -f \"\$\{BASH_SOURCE[0]}\")\")\"

export PULP_CURRENT_CONFIG=pulpissimo@config_file=fpgas/pulpissimo/$BOARD.json

export PULP_CURRENT_CONFIG_ARGS=platform=fpga

if [ -e \${scriptDir}/../../../init.sh ]; then
    source \${scriptDir}/../../../init.sh
fi
" > $1.sh
}

source $BASHLIB/ccommon.sh

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

DIR=`pwd`
#sudo chmod 2775 /usr/bin/screen
#sudo pkill -9 screen



### VARIABLES
BOARD="zcu102"
BITSTREAM=0
DOWNLOAD=0
COMPILE=0
TERMINALS=0
NOTHING=1
USB="ttyUSB0"
BUILD_SDK_OPENOCD=0
EXPORT=0
CONNECTOR_NAME="olimex-arm-usb-tiny-h"

exitflag=0
LOG=$DIR"/pulp_app_log"
ENVIRON_FILE=$DIR/.environ.env
###

#######################################################################
####### COMMAND LINE ARGUMENT HANDLE ##################################

TEMP=`getopt -o sdc:t:ehbu:o: --long bitstream,download,compile:,terminals:,--export-variables,help,build-sdk-openocd,usb-for-screen:,board: -- "$@"`

eval set -- "$TEMP"

while true; do
	case $1 in
		###### ACTION ##########
		-s|--bitstream)
			BITSTREAM=1	
			NOTHING=0
			shift
			;;
		-d|--download)
			DOWNLOAD=1	
			NOTHING=0
			shift
			;;
		-b|--build-sdk-openocd)
			BUILD_SDK_OPENOCD=1
			NOTHING=0
			shift
			;;
	       	-c|--compile)
			COMPILE=1
			shift
			C_APPDIR=$1
			echo $1
			NOTHING=0
			shift
		-t|--terminals)
			TERMINALS=1
			shift
			T_APPDIR=$1
			echo $1
			NOTHING=0
			shift                                                                           
			;;
		-e|--export-variables)
			NOTHING=0
			EXPORT=1
			shift
			;;
		-h|--help)
			UsageExit
			;;
		######## OPTION #######################à
		-u|--usb-for-screen)
			shift
			USB=$1
			echo $1
			shift
			;;
		-o|--board)
			shift
                        case $1 in
                                zcu102)
                                        ;;
                                zcu104)
                     USB          ;;
                                genesys2)
                                        ;;
                                zedboard)
                                        ;;
                                nexys)
                                        ;;
                                nexys_video)
                                        ;;
                                default)
                                        echo "Error board: zcu102, zcu104, genesys2, zedboard, nexys or nexys_video"
                                        exit 1;
                                        ;;
                        esac
                        BOARD=$1
			shift
			;;
		-r|--connector)
			shift
			cd ./pulpissimo/fpga/pulpissimo-$BOARD
			if test -f $1.cfg; then
				CONNECTOR_NAME=$1
			else
				Print "r" "At ./pulpissimo/fpga/pulpissimo-$BOARD there isn't openocd configuration file $1.cfg!! create it"
				UsageExit
			fi
			;;
		--)
			break;;
		*)
			UsageExit
			;;
	esac		
done

if [[ $NOTHING -eq 1 ]] && [[ $USB != "i" ]]; then
	echo $Red"Please give at least an argument!!"
	UsageExit
fi

#######################################################################
###### PROGRAM ######################################################

# Setting environment variable
if [[ $EXPORT  -eq 1 ]]; then
	if test -f "$ENVIRON_FILE"; then
		Print "e" "Set environment var"
		while read var; do
			export_var "$(echo $var| cut -d "=" -f 1)" "$(echo $var| cut -d "=" -f 2)";
			echo "$var exported";
		done < $ENVIRON_FILE
		Print "e" "Restart shell to use variable!!"
	else
		echo "Error environment not setted!!!"
		exitflag=1
	fi 
fi

mkdir -p $LOG

if [[ $BITSTREAM -eq 1 ]]; then
	Print "b" " Bitstream generation:"
	cd $DIR/pulpissimo
	##### Generate the necessary synthesis include scripts #####
	#It will parse the ips_list.yml using the PULP IPApproX IP
        # management tool to generate tcl scripts for all the IPs used in 
	# the PULPissimo project. These files are later on sourced by Vivado
        #to generate the bitstream for PULPissimo.
	./update-ips
	# generate bitstream 
	cd fpga
	mon_run "make clean_$BOARD" "$LOG/bitstream_log.txt" 1 $LINENO
	
	mon_run "make $BOARD" "$LOG/bitstream_log.txt" 0 $LINENO
	cd $DIR
fi

if [[ $DOWNLOAD -eq 1 ]]; then
	Action "Have you connected usb cables for riscv download at port J2 of $BOARD?"
	cd $DIR/pulpissimo/fpga
	Print "f" " Flashing fpga"
	mon_run "make -C pulpissimo-$BOARD download" "$LOG/flashing_log.txt" 1 $LINENO
fi

if [[ $BUILD_SDK_OPENOCD -eq 1 ]] || [[ $COMPILE -eq 1 ]] ; then
	cd $DIR/pulp-sdk
	setJsonBoard $BOARD
	source configs/pulpissimo.sh
	source configs/fpgas/pulpissimo/$BOARD.sh
        mon_run "sudo apt-get install autoconf automake texinfo make libtool pkg-config libusb-1.0 libftdi1 libusb-0.1" "$LOG/build_sdk_openocd_dep" 1 $LINENO
	source sourceme.sh
	export PULP_RISCV_GCC_TOOLCHAIN="/opt/riscv"
	export OPENOCD="$DIR/pulp-sdk/pkg/openocd/1.0/bin"
fi

if [[ $BUILD_SDK_OPENOCD -eq 1 ]]; then
	mon_run "./pulp-tools/bin/plpbuild checkout build --p openocd --stdout" "$LOG/checkout.txt" 1 $LINENO
	mon_run "make all" "$LOG/make_all.txt" 1 $LINENO
	env | grep -e "PULP\|OPENOCD" > $ENVIRON_FILE
fi

if [[ $COMPILE -eq 1 ]]; then
	Print "c" " Compiling"
	cd $DIR/pulp-rt-examples/$C_APPDIR
	echo $(pwd)
        mon_run "make clean all" "$LOG/make_log.txt" 1 $LINENO
fi

if [[ $USB == "i" ]] ; then
	usbInfo
fi
if [[ $TERMINALS -eq 1 ]] && [[ $exitflag -eq 0 ]]; then
	Action "Have you connected usb cables for UART  at port J38 of zcu102 and ARM-USB_TINY-H connector to J55 port?"
  		
  	cd $DIR
        # openOCD terminal
	gnome-terminal --geometry=70x15+0+0 -- bash -c "$OPENOCD/openocd -f $DIR/pulpissimo/fpga/pulpissimo-$BOARD/$CONNECTOR_NAME.cfg; exec bash"
	
	# gdb terminal
	gnome-terminal --geometry=70x15+1000+0 -- bash -c "$PULP_RISCV_GCC_TOOLCHAIN/bin/riscv32-unknown-elf-gdb -x $DIR/pulpissimo/fpga/pulpissimo-$BOARD/elf_run.gdb ./pulp-rt-examples/$T_APPDIR/build/pulpissimo/test/test; exec bash"
	
	# Various UART terminal
	if [[ $USB != "all" ]]; then
		sudo chmod 777 /dev/$USB
		sudo gnome-terminal --geometry=70x15+1000+355 -- bash -c "sudo screen /dev/$USB 115200; exec bash"
	else

		for i in {0...5}; do
			sudo chmod 777 /dev/ttyUSB$i
		done
		sudo gnome-terminal --geometry=70x15+0+355 -- bash -c "sudo screen /dev/ttyUSB0 115200; exec bash"
		sudo gnome-terminal --geometry=70x15+200+355 -- bash -c "sudo screen /dev/ttyUSB1 115200; exec bash"
		sudo gnome-terminal --geometry=70x15+300+355 -- bash -c "sudo screen /dev/ttyUSB2 115200; exec bash"
		sudo gnome-terminal --geometry=70x15+400+355 -- bash -c "sudo screen /dev/ttyUSB3 115200; exec bash"
		sudo gnome-terminal --geometry=70x15+500+355 -- bash -c "sudo screen /dev/ttyUSB4 115200; exec bash"
		sudo gnome-terminal --geometry=70x15+600+355 -- bash -c "sudo screen /dev/ttyUSB5 115200; exec bash"
	fi

fi



