#!/bin/bash

server=$1
num=$2
hostfile="hostfile.txt"

if [[ $server == "all" ]]; then
    if [[ $num == "powersave" ]]; then
        echo "powersave"
        parallel-ssh -h $hostfile -i -t 0 "cpupower -c all frequency-set -g powersave > /dev/null"
    elif [[ $num == "performance" ]]; then 
        echo "performance"
        parallel-ssh -h $hostfile -i -t 0 "cpupower -c all frequency-set -g performance > /dev/null"
    else
        echo $num
        parallel-ssh -h $hostfile -i -t 0 "cpupower -c all frequency-set -u $num > /dev/null"
    fi
else
    ssh root@$server "cpupower -c all frequency-set -u $num > /dev/null"
fi
