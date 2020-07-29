#!/bin/bash

source ./lib/ccommon.sh

install_script(){
	sudo chmod 777 ./pulp_script/$1.sh
	sudo cp ./pulp_script/$1.sh /usr/bin/$1
	sudo chmod 777 /usr/bin/$1
	sudo install -g 0 -o 0 -m 0644 ./manpages/$1.1 /usr/share/man/man1/
	sudo gzip /usr/share/man/man1/$1.1
}
install_lib(){
	sudo chmod 777 ./lib/$1
	sudo cp ./lib/$1 /usr/lib/bash-lib
}

sudo mkdir -p /usr/lib/bash-lib
export_var "BASHLIB" "/usr/lib/bash-lib"

install_lib ccommon.sh
install_script pulp_install
install_script pulp_app
install_script pulp_script


echo "Restart terminal before use program"
