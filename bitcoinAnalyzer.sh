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
# Quitamos todos los ficheros temporales que se crearon
	rm util* 2>/dev/null
# Devolveremos un código de estado no exitoso.
	exit 1
}

# Variables globales a utilizar (Direcciones url)

unconfirmed_transactions="https://www.blockchain.com/es/btc/unconfirmed-transactions"
inspection_transaction_url="https://www.blockchain.com/es/btc/tx/"
inspection_address_url="https://www.blockchain.com/es/btc/address/"
bitcoin_value_url="https://cointelegraph.com/bitcoin-price-index"

# Funciones para representar la información en tablas, vamos a usar varias funciones para crear tablas sacadas del repositorio de github htbExplorer de s4vitar: https://github.com/s4vitar/htbExplorer/blob/master/htbExplorer. Estas funciones serán: printTable(), removeEmptyLines(), repeatString(), isEmptyString() y trimString(). Estas funciones van llamandose unas a otras para crear tablas perfectas.
function printTable(){

    local -r delimiter="${1}"
    local -r data="$(removeEmptyLines "${2}")"

    if [[ "${delimiter}" != '' && "$(isEmptyString "${data}")" = 'false' ]]
    then
        local -r numberOfLines="$(wc -l <<< "${data}")"

        if [[ "${numberOfLines}" -gt '0' ]]
        then
            local table=''
            local i=1

            for ((i = 1; i <= "${numberOfLines}"; i = i + 1))
            do
                local line=''
                line="$(sed "${i}q;d" <<< "${data}")"

                local numberOfColumns='0'
                numberOfColumns="$(awk -F "${delimiter}" '{print NF}' <<< "${line}")"

                if [[ "${i}" -eq '1' ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi

                table="${table}\n"

                local j=1

                for ((j = 1; j <= "${numberOfColumns}"; j = j + 1))
                do
                    table="${table}$(printf '#| %s' "$(cut -d "${delimiter}" -f "${j}" <<< "${line}")")"
                done

                table="${table}#|\n"

                if [[ "${i}" -eq '1' ]] || [[ "${numberOfLines}" -gt '1' && "${i}" -eq "${numberOfLines}" ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi
            done

            if [[ "$(isEmptyString "${table}")" = 'false' ]]
            then
                echo -e "${table}" | column -s '#' -t | awk '/^\+/{gsub(" ", "-", $0)}1'
            fi
        fi
    fi
}

function removeEmptyLines(){

    local -r content="${1}"
    echo -e "${content}" | sed '/^\s*$/d'
}

function repeatString(){

    local -r string="${1}"
    local -r numberToRepeat="${2}"

    if [[ "${string}" != '' && "${numberToRepeat}" =~ ^[1-9][0-9]*$ ]]
    then
        local -r result="$(printf "%${numberToRepeat}s")"
        echo -e "${result// /${string}}"
    fi
}
:
function isEmptyString(){

    local -r string="${1}"

    if [[ "$(trimString "${string}")" = '' ]]
    then
        echo 'true' && return 0
    fi

    echo 'false' && return 1
}

function trimString(){

    local -r string="${1}"
    sed 's,^[[:blank:]]*,,' <<< "${string}" | sed 's,[[:blank:]]*$,,'
}
# Función de panel de ayuda:
function helpPanel(){
	echo -e "\n${turquoiseColour}[!] Uso del programa: ${endColour}"
# Creamos un bucle para dibujar guiones (estetico)
	for i in $(seq 1 80); do echo -ne "${turquoiseColour}-"; done; echo -ne "${endColour}"
	echo -e "\n\n\t${grayColour}[-e]${endColour}${yellowColour} Modo exploración ${endColour}"
	echo -e "\t\t${greenColour}unconfirmed_transactions${endColour}:${blueColour}:\t Listar transacciones que no se han confirmasdo${endColour}"
	echo -e "\t\t${greenColour}inspect_transactions${endColour}:${blueColour}:\t\t Inspeccionar un hash de transacción${endColour}"
    echo -e "\t\t${greenColour}inspect_address${endColour}:${blueColour}:\t\t Inspeccionar una transacción de una dirección blockchaino${endColour}"
	echo -e "\n\t${greyColour}[-n]${endColour}${yellowColour} Número de resultados a mostrar ${endColour}${blueColour} \n\t\t(Ejemplo para monstrar 10 últimas transacciones: -n 10) \n\t\t Si no se indica nada, el valor por defecto, será 100. ${endColour}\n"
	echo -e "\n\t${grayColour}[-i]${endColour}${yellowColour} Proporcionar el identificador de transación ${endColour}${blueColour} \n\t\t(Ejemplo -i 45198fewd4dfe5d41s55fd31ds3df) ${endColour}"
    echo -e "\n\t${grayColour}[-a]${endColour}${yellowColour} Proporcionar dirección de una Wallet a inspeccionar ${endColour}${blueColour} \n\t\t(Ejemplo -a asddds454215sd6ads4652) ${endColour}"
	echo -e "\n\t${grayColour}[-h]${endColour}${yellowColour} Mostrar el panel de ayuda ${endColour}\n"

#Salimos del programa devolviendo un código de error no exitoso y devolvemos el cursor.
	tput cnorm;
	exit 1
}
function unconfirmedTransactions(){
# Cogemos el numero de transacciones
	number_output=$1
# Se va a ir representando la información de la página web. Para ello, lo primero que se hará es un curl que llame a la página web en que se listan las transacciones blockchain y usando el html2text (que deberá instalarse), se convertirá el resultado a un formato más manejable y legible. Todo el resultado se meterá en un fichero temporal (util), para poder trabajar con el output más adelante sin estar llamando constantemente al servidor. Se comprobará que el fichero util tiene algo y no se avanzará hasta que sea así (el curl podría fallar). Se pretende pillar los hashes actuales, cada hash tiene encima una palabrita que es Hash, si se hace un grep de Hash -A 1 y quitamos lo que nos sobra para obtener todos los hashes.
# Para comprobar que el fichero se ha escrito con curl, me lo declaro antes.
	echo '' > util.tmp
# A traves de un búcle while, se hará todo el rato la petición y la escritura en el fichero hasta que en el fichero haya más de una línea que es lo que hay cuando se crea.
	while [ "$(cat util.tmp | wc -l)" == "1" ]; do
		curl -s "$unconfirmed_transactions" | html2text > util.tmp

	done
#Filtramos el fichero, para ello nos creamos una variable llamada hashes en la que metemos todos los hashes, pillamos solo los number_output primeros resultados.
	hashes=$(cat util.tmp | grep "Hash" -A 1 | grep -v -E "Hash|\--|Tiempo" | head -n $number_output)
#Lo bueno de meterlo en variables, es que se puede ir iterando para todos los hashes dentro de las variable.
#Vamos a representar la información en tablas, vamos a usar varias funciones para crear tablas sacadas del repositorio de github htbExplorer de s4vitar: https://github.com/s4vitar/htbExplorer/blob/master/htbExplorer
#Lo separaremos con / y se mete en un fichero util.table donde se representarán las tablas.
	echo "Hash/Cantidad/Bitcoin/Tiempo" > util.table
#Se itera para ver todos los hashes de la variable hashes.
	for hash in $hashes; do
#En el curl lo que obtenemos es en la línea 6 la cantidad de dinero en dolares, en la línea 4 la cantidad de dinero en bitcoins y en la línea 2 el tiempo.
		echo "${hash}/$(cat util.tmp | grep "$hash" -A 6 | tail -n 1)/$(cat util.tmp | grep "$hash" -A 4 | tail -n 1)/$(cat util.tmp | grep "$hash" -A 2 | tail -n 1)" >> util.table
	done
#Calculamos el total de euros gastados y lo metemos en un fichero llamado money:

	cat util.table | tr '/' ' ' | awk '{print $2}' | grep -v "Cantidad" | tr -d '$' | sed 's/\..*//g' | tr -d ',' >> utilDinero

#Calculamos en una variable llamada dinero, la suma de todo el dinero total gastado
	money=0; cat utilDinero | while read dinero; do
		let money+=$dinero
		echo $money > utilMoney.tmp
	done;

	cat utilMoney.tmp 2>/dev/null

    if [ "$(echo $?)" == "1" ]; then
          echo -e "${redColour} \n No hay internet, conectese a Internet para conectar "
          tput cnorm;
          rm util* 2>/dev/null
          exit 1
    fi



#Representamos el número con puntos y con el dolar delante y lo metemos en un fichero que se usará para representar la tabla del dinero total:

	echo -n "Cantidad total/" > utilAmount.table
	echo "\$$(printf "%'.d\n" $(cat utilMoney.tmp))" >> utilAmount.table

#Validamos si utilAmount.table tiene o no contenido:

	if [ "$(cat util.table | wc -l)" != "1" ]; then
#Pintamos la tabla en color verde.
		echo -ne "${greenColour}"
#Llamamos a printTable para sacarlo en formato tabla. El primer parámetro es para quitar el delimitador, en este caso / y el segundo parámetro lo que se quiere convertir en tabla.
		printTable '/' "$(cat util.table)"
#Cerramos el color
		echo -ne "${endColour}"
#Representamos en azul la cantidad total que se está moviendo.
		echo -ne "${blueColour}"
		printTable '/' "$(cat utilAmount.table)"
		echo -ne "${endColour}"
#Hacemos un exit 0 y dejamos todo como estaba:
		rm util* 2>/dev/null
		tput cnorm;
		exit 0
	else
		rm util* 2>/dev/null
	fi

#Borramos los archivos temporales que hemos creado:
	rm util* 2>/dev/null
#Se devuelve el cursor.
	tput cnorm
}

# Función que inspecciona una transacción dada, mostrará la entrada total de dinero, la salida total de dinero y las direcciones de entrada y de salida.
function inspectTransaction(){
	inspect_transaction_hash=$1
# Se crea un fichero temporal en el que meteremos toda la información que tendrán las tablas, empezará con el título: Entrada Total y Salida Total.

	echo "Entrada Total!Salida Total" > utilTotal.tmp

# Se valida que en el fichero siempre se meta información
	while [ "$(cat utilTotal.tmp | wc -l)" == "1" ]; do

# Cojemos los valores en bitcoins con un curl como en la función anterior:

		curl -s "${inspection_transaction_url}${inspect_transaction_hash}" | html2text | grep -E "Total entradas|Total de salida" -A 1 | grep -v -E "Total entradas|Total de salida"| xargs | tr ' ' '!' | sed 's/!BTC/ BTC/g' >> utilTotal.tmp

	done
# Representamos en tabla:
	echo -ne "${greenColour}"
	printTable '!' "$(cat utilTotal.tmp)"
	echo -ne "${endColour}"
	
# Representamos ahora una tabla en la que se muestran las direcciones de entrada con las que se envia la transacción

	echo "Dirección (Entradas)!Valor" > utilEntradas.tmp

    while [ "$(cat utilEntradas.tmp | wc -l)" == "1" ]; do

		curl -s  "${inspection_transaction_url}${inspect_transaction_hash}" | html2text | grep "Entradas" -A 500 | grep "Salidas" -B 500 | grep "Direcci" -A 3 | grep -v -E "Direcci|Valor|--" | awk 'NR%2{printf "%s ", $0;next;}1' | awk '{print $1 "!" $2 " " $3}' >> utilEntradas.tmp

	done

# Representamos la tabla:

    echo -ne "${turquoiseColour}"
    printTable '!' "$(cat utilEntradas.tmp)"
    echo -ne "${endColour}"

# Ahora hacemos lo mismo pero con las direcciones de salida

    echo "Dirección (Entradas)!Valor" > utilSalidas.tmp

    while [ "$(cat utilSalidas.tmp | wc -l)" == "1" ]; do

        curl -s  "${inspection_transaction_url}${inspect_transaction_hash}" | html2text | grep "Salidas" -A 500 | grep "Direcci" -A 3 | grep -v -E "Direcci|Valor|--" | awk 'NR%2{printf "%s ", $0;next;}1' | awk '{print $1 "!" $2 " " $3}' >> utilSalidas.tmp

    done

# Representamos la tabla:
     
    echo -ne "${turquoiseColour}"
    printTable '!' "$(cat utilSalidas.tmp)"
    echo -ne "${endColour}"

	rm util* 2>/dev/null
	tput cnorm
}
# Creamos la función inspectAddress que inspeccionará una Wallet que se indique, se listará: transacciones realizadas, cantidad total recibida de dinero, cantidad total enviada de dinero y el saldo actual de la cuenta.

function inspectAddress(){

	wallet=$1
	echo "Transacciones realizadas!Cantidad total recibida (BTC)!Cantidad total enviada (BTC)!Saldo Total de la cuenta" >> utilWallet.tmp
	
	curl -s "${inspection_address_url}${wallet}" | html2text | grep -E "Transacciones|Total Recibidas|Cantidad total enviada|Saldo final" -A 1 | head -n -2 | grep -v -E "Transacciones|Total Recibidas|Cantidad total enviada|Saldo final" | xargs | tr ' ' '!' | sed 's/!BTC/ BTC/g' >> utilWallet.tmp

# Representamos la tabla:

    echo -ne "${turquoiseColour}"
    printTable '!' "$(cat utilWallet.tmp)"
    echo -ne "${endColour}"

# Se elimina el fichero temporal

	rm util* 2>/dev/null

# Vamos a ir a la página cointelegraph que te da el valor del bitcoin a tiempo real en bitcoins, haremos al curl y grepearemos por Last Price que indica el último precio

	bit_value=$(curl -s "${bitcoin_value_url}" | html2text | grep "Last Price" | head -n 1 | awk 'NF{print $NF}' | tr -d ',')

# Ahora lo que vamos a representar es el valor en dolares haciendo la conversión con el valor a tiempo real en el programa. Para ello, se hará un curl de lo mismo, pero por separado, por un lado filtraremos solo por Transacciones y por otro por Total Recibida, Cantidad total enviada y Saldo final.

	curl -s "${inspection_address_url}${wallet}" | html2text | grep "Transacciones" -A 1 | head -n -2 | grep -v -E "Transacciones|\--" > utilWallet.tmp
	curl -s "${inspection_address_url}${wallet}" | html2text | grep -E "Total Recibidas|Cantidad total enviada|Saldo final" -A 1 | grep -v -E "Total Recibidas|Cantidad total enviada|Saldo final|\--" > utilBitcoinDollars.tmp

# Nos recorremos todos los valores que se van a cambiar a dolares.

	cat utilBitcoinDollars.tmp | while read value; do
# El valor hacemos que este en formato decimal, además representamos el valor con el dolar delante:
		echo "\$$(printf "%'.d\n" $(echo "$(echo $value | awk '{print $1}')*$bit_value" | bc) 2>/dev/null)" >> utilWallet.tmp
	done

# Si una tiene 0 Bitcoins, entonces la vamos a eliminar creando una variable llamada line_null, para eso filtramos por lo que empiece por $ y acabe por dolar (para indicar que acabe es con $ casualmente y cogemos la línea que va delante de los dos puntos (:).

	line_null=$(cat utilWallet.tmp | grep "^\$$" | awk 'print $1' FS=":")

# Si no hay una línea vacia entonces line_null estaría vacio.

    rm util* 2>/dev/null
    tput cnorm

}

# Creación de menu con getops, para ser user friendly: e será para exploración,
# Variable para distinguir desde fuera cuando se tiene que ir a que sitio.
parameter_counter=0;
while getopts "e:n:h:i:a:" arg; do
	case $arg in
# Guarda el parámetro -e en la variable exploration_mode.
		e) exploration_mode=$OPTARG; let parameter_counter+=1;; # Se suma 1 a parameter_counter.
# Indicar el numero de transacciones a monstrar:
		n) number_output=$OPTARG; let parameter_counter+=1;;
# Llama al identificador de la transacción:
		i) inspect_transaction=$OPTARG; let parameter_counter+=1;;
# Llama al identificar de una Wallet:
		a) inspect_address=$OPTARG; let parameter_counter+=1;;
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
# Si el usuario no indica el valor de n, se indica un valor por defecto, que será 100.
		if [ ! "$number_output" ]; then
			number_output=100
# Si se introduce unconfirmed_transactions se llama a la función unconfirmedTransactions
			unconfirmedTransactions $number_output
		else
			unconfirmedTransactions $number_output
		fi
	elif [ "$(echo $exploration_mode)" == "inspect_transactions" ]; then 
		inspectTransaction $inspect_transaction
	elif [ "$(echo $exploration_mode)" == "inspect_address" ]; then
		inspectAddress $inspect_address
	fi
fi
