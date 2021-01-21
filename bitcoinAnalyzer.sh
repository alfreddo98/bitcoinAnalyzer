#!/bin/bash

# Autor: Alfredo Sánchez Sánchez

# Declaramos paletilla de colores:

greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

# Para parar la aplicacion al pulsar control C, llama a la función ctrl_c():
trap ctrl_c INT

function ctrl_c(){
	echo -e "\n${redColour}[!]Exiting...\n${endColour}"
# Para volver obtener el cursor (Se hará un tput civis para esconder el cursor
	tput cnorm;
# Devolveremos un código de estado no exitoso.
	exit 1
}

# Variables globales a utilizar

unconfirmed_transactions="https://www.blockchain.com/es/btc/unconfirmed-transactions"
inspection_transaction_url="https://www.blockchain.com/btc/tx/"
inspection_address_url="https://www.blockchain.com/btc/address/"

# Función de panel de ayuda:
function helpPanel(){
	echo -e "\n${turquoiseColour}[!] Uso del programa: ${endColour}"
# Creamos un bucle para dibujar guiones (estetico)
	for i in $(seq 1 80); do echo -ne "${turquoiseColour}-"; done; echo -ne "${endColour}"
	echo -e "\n\n\t${greyColour}[-e]${endColour}${yellowColour} Modo exploración ${endColour}"
	echo -e "\t\t${greenColour}unconfirmed_transactions${endColour}:${blueColour}:\t Listar transacciones que no se han confirmasdo${endColour}"
	echo -e "\t\t${greenColour}inspect_transactions${endColour}:${blueColour}:\t\t Inspeccionar un hash de transacción${endColour}"
    echo -e "\t\t${greenColour}inspect_address${endColour}:${blueColour}:\t\t Inspeccionar una transacción de una dirección blockchaino${endColour}"
	echo -e "\n\t${greyColour}[-h]${endColour}${yellowColour} Mostrar el panel de ayuda ${endColour}\n"
#Salimos del programa devolviendo un código de error no exitoso y devolvemos el cursor.
	tput cnorm;
	exit 1
}
function unconfirmedTransactions(){
# Se va a ir representando la información de la página web. Para ello, lo primero que se hará es un curl que llame a la página web en que se listan las transacciones blockchain y usando el html2text (que deberá instalarse), se convertirá el resultado a un formato más manejable y legible. Todo el resultado se meterá en un fichero temporal (util), para poder trabajar con el output más adelante sin estar llamando constantemente al servidor. Se comprobará que el fichero util tiene algo y no se avanzará hasta que sea así (el curl podría fallar). Se pretende pillar los hashes actuales, cada hash tiene encima una palabrita que es Hash, si se hace un grep de Hash -A 1 y quitamos lo que nos sobra para obtener todos los hashes.
# Para comprobar que el fichero se ha escrito con curl, me lo declaro antes.
	echo '' > util.tmp
# A traves de un búcle while, se hará todo el rato la petición y la escritura en el fichero hasta que en el fichero haya más de una línea que es lo que hay cuando se crea.
	while [ "$(cat util.tmp | wc -l)" == "1" ]; do
		curl -s "$unconfirmed_transactions" | html2text > util.tmp
	done

#Filtramos el fichero, para ello nos creamos una variable llamada hashes en la que metemos todos los hashes.
	hashes=$(cat util.tmp | grep "Hash" -A 1 | grep -v -E "Hash|\--|Tiempo")
#Lo bueno de meterlo en variables, es que se puede ir iterando para todos los hashes dentro de las variable.

	tput cnorm
}

# Creación de menu con getops, para ser user friendly: e será para exploración,
# Variable para distinguir desde fuera cuando se tiene que ir a que sitio.
parameter_counter=0;
while getopts "e:h:" arg; do
	case $arg in
# Guarda el parámetro -e en la variable exploration_mode.
		e) exploration_mode=$OPTARG; let parameter_counter+=1;; # Se suma 1 a parameter_counter.
# Llama a al función de panel de ayuda si -h:
		h) helpPanel;;
	esac
done

# Ocultamos el cursor.
tput civis 

# Si se ejecuta mal el programa, se llama a la función helpPanel para enseñar el panel de ayuda.
if [ $parameter_counter -eq 0 ]; then 
	helpPanel
else
# Vemos el valor de exploration_mode haciendo un echo (lo llamamos a nivel de sistema en vez de poner directamente directamente a la variable ($explotation_mode) para tener control de que es lo que se quiere mostrar y la ejecución que se quiere hacer.  Se compara con los posibles valores que se pueden introducir (unconfirmed_transactions, inspect_transactions o inspect_address)
	if [ "$(echo $exploration_mode)" == "unconfirmed_transactions" ]; then
# Si se introduce unconfirmed_transactions se llama a la función unconfirmedTransactions
	unconfirmedTransactions
	fi
fi
