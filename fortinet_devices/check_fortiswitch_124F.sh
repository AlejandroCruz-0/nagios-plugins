#!/bin/bash
#Author: Alejandro Cruz


while getopts 'H:C:T:w:c:h' OPT; do

        case $OPT in

        H) host=$OPTARG;;
        C) community=$OPTARG;;
        T) type_of_check=$OPTARG;;
        w) warning=$OPTARG;;
        c) critical=$OPTARG;;
        h) hpl="yes";;
        *) unknow="yes";;
     esac
     done

HELP="
        Bash script to check cpu and memory of  Fortninet device model fortiswitch 124F
        Sintaxis: check_fortiswitch_124F.sh -H <ip> -C <comunidad> -T <tipo check cpu o mem> -w <umbral warning> -c <umbral critico>
"
if [ "$hlp" = "yes" -o $# -lt 1 ]; then
        echo "$HELP"
        exit 0
fi



# OID list https://mibbrowser.online/mibdb_search.php?mib=FORTINET-FORTISWITCH-MIB

#OID for CPU
fsSysCpuUsage="1.3.6.1.4.1.12356.106.4.1.2"
#OID for memory usage in KB
fsSysMemUsage="1.3.6.1.4.1.12356.106.4.1.3"
#OID for total memory capacity in KB
fsSysMemCapacity="1.3.6.1.4.1.12356.106.4.1.4"


function cpu_check () {
        cpu_usage=$(snmpwalk -Oqv -v 2c -c $community $host $fsSysCpuUsage 2>/dev/null)
        if [[ $? -ne 0 ]];then
                echo "Error in obtaining data"
                exit 1
        fi

        #validar que argumentos existan
        if [[ -z $warning ]] || [[ -z $critical ]];then
                echo "Missing warning and critical arguments"
                exit 1

        fi
        warning=$(echo $warning | sed 's/%//g')
        critical=$(echo $critical | sed 's/%//g')

        if [[ $cpu_usage -ge $critical  ]];then
                echo "CRITICAL: CPU USAGE IS $cpu_usage%|'cpu'=$cpu_usage%;$warning;$critical"
                exit 2
        elif [[ $cpu_usage -ge $warning ]];then
                echo "WARNING: CPU USAGE IS $cpu_usage%|'cpu'=$cpu_usage%;$warning;$critical"
                exit 1

        else
                echo "OK: CPU USAGE IS $cpu_usage%|'cpu'=$cpu_usage%;$warning;$critical"
                exit 0
        fi

}

function mem_check (){

        mem_usage=$(snmpwalk -Oqv -v 2c -c $community $host $fsSysMemUsage 2>/dev/null)
        mem_capacity=$(snmpwalk -Oqv -v 2c -c $community $host $fsSysMemCapacity 2>/dev/null)
        #echo "$mem_usage"
        #echo "$mem_capacity"

        if [[ $? -ne 0 ]];then
                echo "Error in obtaining data"
                exit 1
        fi

        mem_usage_in_percentage=$(echo "scale=4;$mem_usage/$mem_capacity*100" | bc | cut -d . -f 1)

        #validar que argumentos de umbrales existan
        if [[ -z $warning ]] || [[ -z $critical ]];then
                echo "Missing warning and critical arguments"
                exit 1

        fi
        warning=$(echo $warning | sed 's/%//g')
        critical=$(echo $critical | sed 's/%//g')

        if [[ $mem_usage_in_percentage -ge $critical  ]];then
                echo "CRITICAL: MEM USAGE IS $mem_usage_in_percentage%|'memory'=$mem_usage_in_percentage%;$warning;$critical"
                exit 2
        elif [[ $mem_usage_in_percentage -ge $warning ]];then
                echo "WARNING: MEM USAGE IS $mem_usage_in_percentage%|'memory'=$mem_usage_in_percentage%;$warning;$critical"
                exit 1

        else
                echo "OK: MEM USAGE IS $mem_usage_in_percentage%|'memory'=$mem_usage_in_percentage%;$warning;$critical"
                exit 0
        fi
}

if [ "$hlp" = "yes" -o $# -lt 5 ]; then
        echo "$HELP"
        exit 0
elif [[ $type_of_check == "cpu" ]];then
  cpu_check
elif [[ $type_of_check == "mem" ]];then
  mem_check
else
        echo "Wrong options"
fi


