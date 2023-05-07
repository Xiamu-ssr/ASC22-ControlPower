#!/bin/bash

server=$1
hostfile="hostfile.txt"

if [[ $server == "all" ]]; then
    parallel-ssh -h $hostfile -i -t 0 "echo off | sudo tee /sys/devices/system/cpu/smt/control"
else
    echo "use all not single ip"
fi