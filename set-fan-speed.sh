#!/bin/bash

server=$1
num=$2
hostfile="hostfile.txt"

if [[ $server == "all" ]]; then
    parallel-ssh -h $hostfile -i -t 0 "ipmitool raw 0x3C 0x2D 0xFF $num"
else
    ssh root@$server "ipmitool raw 0x3C 0x2D 0xFF $num"
fi