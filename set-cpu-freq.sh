#!/bin/bash

server=$1
num=$2

if [[ $server == "all" ]]; then
    parallel-ssh -h $hostfile -i -t 0 "cpupower -c all frequency-set -u $num > /dev/null"
else
    ssh root@$server "cpupower -c all frequency-set -u $num > /dev/null"
fi