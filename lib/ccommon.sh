#!/usr/bin/bash

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

Print(){
        echo -e -n "$Red""[$1] "
        echo -e  "$Green""$2"
        echo -en "\e[0m"
}

Action(){
	echo -e "$Red""$1, press enter when you have done."
        echo -en "\e[0m"
	read n
}

Print_verbose () {
       # stampa $1 solo se $2 = 1
       if [[ $2 = 1 ]]; then
           echo -e "$1"
        fi
}

monitor_file () {
	   # stampa in numero di righe del file in questione 
	   # riscrivendo la riga ogni volta dando l'effetto progressivo
	   file=$1 # name of file to monitor
	   str=$2  # str before line number
	   id=$3 # id of process ($!)
	   var=0
	   var_err=0
	   while true; do 
		   # calcolo delle righe dell'output file
		   var=$(cat $file | wc -l); 
		   # calcolo delle righe dell'error file
		   var_err=$(cat $(echo $file | cut -d "." -f 1)_err.txt | wc -l) 
	           # calcolo delle righe totali
		   res=$(($var+$var_err))
		   # se le righe sono maggiori di 1 stampo il log
		   if [[ $res -ne 0 ]]; then 
			if [[ $var -lt $var_old ]]; then
				lastline=$(tail -n 1 $file)
			else
				lastline=$(tail -n 1 $(echo $file | cut -d "." -f 1)_err.txt)
			fi
			
			if [[ $var -ne $var_old ]] || [[ $var_err -ne $var_err_old ]]; then
				printf "[i]  %-50s]:%-5d | %-70s\r" "${str:0:50}" "$res" "${lastline:0:70}"
			fi
			if ! test -d /proc/$id; then
				break
			fi
		   else
			   printf "[i]  %-50s]:%-5d \r" "${str:0:50}" "$res"
		   fi
		   var_old=$var
		   var_err_old=$var_err
	   done
	   printf "[i]  %-50s]:%-5d \n" "${str:0:50}" "$res"
}

monitor_file_error () {
	   # stampa tutte le righe con errore e 
	   # se  ce se sono chiude lo script
	   # $1 è il nome del file con eventuali errori
	   cat $1 | grep -ni "error" --color > error_log.txt
   	   if [[ $(cat error_log.txt | wc -l) -gt 0 ]]; then
		   echo -e $( \
		   echo "[!]  An error has been found!!!!!\n";\
		   echo "[!]  command: $2\n";\
		   echo "[!]  Log file with error: "$1\n;\
	   	   echo "[!]  These are error lines of the log file:\n";\
		   cat error_log.txt ;\
		   echo "\n[!]  These are error lines from the error log file:\n";\
		   cat $(echo $1 | cut -d "." -f 1)_err.txt ;\
		   echo "\n[!]  More info in file $1\n" ) > error_monitor.txt
		   #exit 1
		   return 0
	   fi
}

## This function is used many times during installation and perform following 
# action:
#	1) execute a command in background ( $1 )
#	2) redirect it's output in a log file ( $2 )
#	3) continuously control log file printing the file line and last
#		line in terminal.
#	4) At the end check the log file in order to find errors, in this case
#		print this error and exit
#	5) $4 option set if the log file should be ovewritten (1) or the 
#		new content chould be appended, is useful if you want that two 
#		or more command share log file.
#	6) $5 is the script line, can be gived using $LINENO varible,
#		this is useful if you want to know where an error occur in 
#		your script since $5 argument is printed.
mon_run (){
	   # $1 è il comando da eseguire
	   # $2 è il file in cui scrivere il log
	   # $3 se è 1 sovrascrivo il file
	   # $4 è l'eventuale numero di riga
	   echo "Line $4: $1" >> trace_command.txt
	   sudo mkdir -p $(dirname $2)
	   sudo touch $2
	   sudo touch $(echo $2 | cut -d "." -f 1)_err.txt
	   sudo chmod 777 $2
	   sudo chmod 777 $(echo $2 | cut -d "." -f 1)_err.txt
	   if [[ $3 -eq 1 ]]; then
		   $1 > $2 2> $(echo $2 | cut -d "." -f 1)_err.txt &
	   else
		   	$1 >> $2 2>> $(echo $2 | cut -d "." -f 1)_err.txt &
	   fi
	   monitor_file "$2" "line $4: [$1" $!
	   monitor_file_error $2 "Line $4: $1"
}

export_path (){
	   export PATH=$PATH:$1
	   if [[ `grep -c "export PATH=$PATH:$1" ~/.bash_profile` -eq 0 ]] ; then
		   echo "export PATH=$PATH:$1" >> ~/.bash_profile
           fi
}

export_var (){
	   export $1=$2
	   if [[ `grep -c ".bash\_profile" ~/.bashrc` -eq 0 ]] ; then
		   echo -e "if [ -f ~/.bash_profile ]; then\n. ~/.bash_profile\nfi" >> ~/.bashrc
	   fi
	   if [[ `grep -c "export $1=$2" ~/.bash_profile` -eq 0 ]]; then
	   	echo "export $1=$2" >> ~/.bash_profile
	   fi

}
