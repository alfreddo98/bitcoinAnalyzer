btcAnalyzer
======
Es una herramienta hecha en Bash para inspeccionar transacciones en el servicio de exploración de bloques de Bitcoin, toda la información se saca a tiempo real de la página web blockchain.com.

El programa se ha realizado para el aprender a usar y crear programas en bash. Se ha seguido los pasos del siguiente vídeo de S4vitar (Scripting en bash intermedio): https://www.youtube.com/watch?v=_OpD54Q9hZc&ab_channel=s4vitar

**Requisitos previos**

Antes de ejecutar la herramienta, es necesario instalar las siguientes utilidades a nivel de sistema:

```bash
apt install html2text bc -y
apt install bc -y
```
html2text, permite leer de forma legible los resultados al hacer curl, mientras que bc sirve para bipear una operación realizada a nivel de sistema (Yo no la tenia instalada por defecto en Kali Linux)

**Cómo ejecutar la aplicación**
Existen tres modos de exploración, los cuales son: unconfirmed_transactions (muestra las últimas transacciones realizadas), inspect_transaction (Muestra la información relativa a una transacción que se especifique), inspect_address (Muestra la información relativa a una dirección que se especifique).

