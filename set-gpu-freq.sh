#!/bin/bash

server=$1
num=$2
hostfile="hostfile.txt"

if [[ $server == "all" ]]; then
    parallel-ssh -h $hostfile -i -t 0 "nvidia-smi -ac 1512,$num > /dev/null"
else
    ssh root@$server "nvidia-smi -ac 1512,$num > /dev/null"
fi