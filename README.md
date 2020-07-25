# AutomatizePULPissimo
Here you can find series of bash script to automatize PULPissimo installation and debug mainly on zcu102 board.

┌──────────────────┐
│FILES ORGANIZATION│
└──────────────────┘

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


- ./install.sh:
	This script simply puts pulp_app.sh and pulp_install.sh into the right directories into the filesystem to be always accessible. It copies ./pulp_script/pulp_app.sh and ./pulp_script/pulp_install.sh in /usr/bin/ and ./manpages/pulp_app.1 and ./manpages/pulp_install.1 into /usr/share/man/man1/. Then it also copies ./lib/ccommon.sh script into custom folder /usr/lib/bash-lib where there are all the user defined bash functions.

- ./pulp_env_example.env: 
	It is an example of what you can find in your personal pulp_env_example.env file once you launch the PULPissimo installation. It contains the environment variables required by the various scripts to perform a correct PULPissimo installation.

- ./manpages/pulp_app.1 and ./manpages/pulp_install.1: 
	Are the man files for pulp_app.1 and pulp_install.sh. You can use them after executing ./install.sh

- ./pulp_script/pulp_install.sh:
	This is the script where all the necessary repositories for toolchain, sdk, pulp-builder and pulpissimo are cloned.
	It checks at the beginning the current OS and if different from Ubuntu or CentOS it exits because for the moment everything  has been verified only for these two OS.
	
- ./pulp_script/pulp_app.sh:
	This is the script to launch if you want to run an application on the FPGA. In particular there are different options:
	-o: selection of target board
	-b: create bitstream using PULPissimo_bitstream.sh
	-d: download bitstream into board using	"make -C pulpissimo-[board] download"
	-c: create cross compiled test elf file of hello
	-u: selection of usb for screen connection
		-u ttyUSB0	--> open one shell with screen on ttyUSB0
		-u all  	--> open many shell with screen on all usb
		-u i 		--> show current usb and their name
	-t:
	
- ./lib/ccommon.sh:
