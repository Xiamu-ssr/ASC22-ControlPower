#!/bin/bash
ipmitool sensor | grep FAN | awk '{split($0,a,"|"); print a[1] a[2]}'