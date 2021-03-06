#!/bin/bash 

#############################################################################
####### FUNCTIONS ###########################################################
setJsonBoard(){
	# This function create the correct json file
	# in pulp-sdk/pulp-config/configs/fpgas/ directory
	# used to build sdk
	# The second file created is the board file used to
	# set board variable and platform to use setted as fpga
	BOARD=$1
	DIR=$2
	cd $DIR/pulp-sdk/pulp-configs/configs/fpgas/pulpissimo
	if ! test -f $BOARD.json; then
		mv *.json $BOARD.json
		sed -i 's/pulpissimo-.*\"/pulpissimo-$BOARD\"/g' $BOARD.json
	fi
	cd $DIR
	createBoardFile $DIR/$BOARD
	cp $DIR/$BOARD.sh $DIR/pulp-sdk/configs/fpgas/pulpissimo/
	mv $DIR/$BOARD.sh $DIR/pulp-sdk/pkg/sdk/dev/configs/fpgas/pulpissimo/
}

usbInfo(){
	# This function is used to give information about usb name
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

UsageExit()
{
	# Print help and exit
	echo -e "$Green""\
pulp_app [OPTION]   Is a bash script able to create pulp bitstream,
		    upload it into board compile application and run
		    it into board, actually zcu102 is the  default
		    board and hello is the default application.
OPTION
	-s|--bitstream
		create bitstream and binary file for flashing, this
		option use vivado
	-d|--download
		download bitstream into board using
		make -C pulpissimo-BOARD download
	-b|--build-sdk-openocd
		build the sdk and opeocd patch
	-c|--compile C_APPDIR
		create cross compiled test elf file from test.c 
		file founded in ./pulp-rt-examples/\$C_APPDIR
	-t|--terminal T_APPDIR
		if the  terminal with openOCD, gdb and screen, 
		for screen is possible to select usb number using
		-u option and -r for connector option. The file
		tested is pulp-rt-examples/\$T_APPDIR/build/pulpissimo/test/test
		created by compilation using -c option.
	-e|--export-variables
		After -b option the environment varible  are setted in .environ.env 
		file, so this action set variable find in .environ.env in ~/.bash_profile
		, in this way each time that a shell is open the variable are setted.
		After the execution of the action you should restart shell 
		to have variable setted. 
	-h|--help
		print this help
	-u|--usb-for-screen USB|all|i
		selection of usb for screen connection example:
		-u ttyUSB0
		all option istead screen all usb
		i option show corrently usb and their name
	-o|--board BOARD
		selection of target board, possible board are
		zcu102, zcu104, genesys2, zedboard, nexys or nexys_video
	-r|--connector CONNECTOR_NAME
		CONNECTOR_NAME should be the name of jtag programmer and debugger
		used to upload and debug application on pulpissimo. This 
		connector should support openOCD. This name is used to call 
		./pulpissimo/fpga/pulpissimo-\$BOARD/\$CONNECTOR_NAME.cfg 
		as configuration of openOCD.
	
"
	exit 1;	
}

createBoardFile(){
	# This board file is used to set board
	BOARD=$(basename $1)
	echo "#!/bin/bash
BOARD=$BOARD

scriptDir=\"\$(dirname \"\$(readlink -f \"\${BASH_SOURCE[0]}\")\")\"

export PULP_CURRENT_CONFIG=pulpissimo@config_file=fpgas/pulpissimo/$BOARD.json

export PULP_CURRENT_CONFIG_ARGS=platform=fpga

if [ -e \${scriptDir}/../../../init.sh ]; then
    source \${scriptDir}/../../../init.sh
fi
" > $1.sh
}
 
# after installation BASHLIB option will be exported by 
# .bash_profile and used here to find ccommon.sh file
# that is placed in $BASHLIB directory by installer
source $BASHLIB/ccommon.sh


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
			NOTHING=0
			shift
			;;
		-t|--terminals)
			TERMINALS=1
			shift
			T_APPDIR=$1
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
			cd $DIR/pulpissimo/fpga/pulpissimo-$BOARD
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
	echo -e "$Red""Please give at least an argument!!"
	UsageExit
fi

#######################################################################
###### PROGRAM ######################################################

# Setting environment variable
# variable previous setted by -b option in $ENVIRON_FILE will be saved in ~/.bash_profile file
# in order to be available in shell after restart.
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

# Creation of log directory for mon_run output
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
	# download of bistream into fpga, remember that this isn't a flashing, 
        # if you restart fpga all configuration will be lost and -d action
	# should be redone.	

	# waiting for user to connect cable for programming
	Action "Have you connected usb cables for riscv download at port J2 of $BOARD?"
	cd $DIR/pulpissimo/fpga
	Print "f" "Download of pulpissimo into $BOARD board"
	mon_run "make -C pulpissimo-$BOARD download" "$LOG/flashing_log.txt" 1 $LINENO
fi

if [[ $BUILD_SDK_OPENOCD -eq 1 ]] || [[ $COMPILE -eq 1 ]] || [[ $TERMINALS -eq 1 ]] ; then
	# Setting of env varible 
	Print "c||b" "Setting environment variable"
	cd $DIR/pulp-sdk
	setJsonBoard $BOARD $DIR
	source $DIR/pulp-sdk/configs/pulpissimo.sh
	source $DIR/pulp-sdk/configs/fpgas/pulpissimo/$BOARD.sh
        mon_run "sudo apt-get install autoconf automake texinfo make libtool pkg-config libusb-1.0 libftdi1 libusb-0.1" "$LOG/build_sdk_openocd_dep" 1 $LINENO
	source $DIR/pulp-sdk/sourceme.sh
	export PULP_RISCV_GCC_TOOLCHAIN="/opt/riscv"
	export OPENOCD="$DIR/pulp-sdk/pkg/openocd/1.0/bin"
fi

if [[ $BUILD_SDK_OPENOCD -eq 1 ]]; then
	# Building of sdk and openocd patch
	mon_run "./pulp-tools/bin/plpbuild checkout build --p openocd --stdout" "$LOG/checkout.txt" 1 $LINENO
	mon_run "make all" "$LOG/make_all.txt" 1 $LINENO
	env | grep -e "PULP\|OPENOCD" > $ENVIRON_FILE
fi

if [[ $COMPILE -eq 1 ]]; then
	# compiling application
	Print "c" " Compiling"
	cd $DIR/pulp-rt-examples/$C_APPDIR
        mon_run "make clean all" "$LOG/make_log.txt" 1 $LINENO
fi

if [[ $USB == "i" ]] ; then
	Print "usbinfo" "Info about usb available"
	usbInfo
fi
if [[ $TERMINALS -eq 1 ]] && [[ $exitflag -eq 0 ]]; then
	Print "t" "Opening terminals"
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
		sudo gnome-terminal --geometry=70x15+0+355 --tab -t "/dev/ttyUSB0" -- bash -c "sudo screen /dev/ttyUSB0 115200; exec bash"
		sudo gnome-terminal --geometry=70x15+200+355 --tab -t "/dev/ttyUSB1" -- bash -c "sudo screen /dev/ttyUSB1 115200; exec bash"
		sudo gnome-terminal --geometry=70x15+400+355 --tab -t "/dev/ttyUSB2" -- bash -c "sudo screen /dev/ttyUSB2 115200; exec bash" 
		sudo gnome-terminal --geometry=70x15+600+355 --tab -t "/dev/ttyUSB3" -- bash -c "sudo screen /dev/ttyUSB3 115200; exec bash" 
		sudo gnome-terminal --geometry=70x15+800+355  --tab -t "/dev/ttyUSB4" -- bash -c "sudo screen /dev/ttyUSB4 115200; exec bash" 
	fi
	Print "t" "Press enter when you want to close terminals."
	read d
	if [[ $(echo $(ps -A  | grep gnome-terminal | tr -s " " | cut -d " " -f 1 ) | wc -m) -lt 3 ]]; then
		sudo kill -9 $(ps -A  | grep gnome-terminal | tr -s " " | cut -d " " -f 2)
	else
		sudo kill -9 $(ps -A  | grep gnome-terminal | tr -s " " | cut -d " " -f 1)
	fi
fi



