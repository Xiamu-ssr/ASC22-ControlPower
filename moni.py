#!/usr/bin/python
#encoding:utf-8
import os,time,random
from datetime import *
import datetime
import sys
from subprocess import getoutput
import matplotlib.pyplot as plt
from torch.utils.tensorboard import SummaryWriter
from pssh.clients import ParallelSSHClient
import socket

hostname = socket.gethostname()

# how to run it?
# nohup python monitor.py >> example.log 2>&1 &
# python monitor.py [n minutes]


# timeBegin = datetime.datetime.now()
hosts = [i.strip() for i in open("./hostfile").readlines()]
host_map = {k:v for k,v in zip(range(len(hosts)),hosts)}
writer = SummaryWriter(f"log",flush_secs=0)
client = ParallelSSHClient(hosts)

#获取开始时间
#class datetime.timedelta(days=0,seconds=0,microseconds=0,milliseconds=0,minutes=0,hours=0,weeks=0)
# timeBegin_str = datetime.datetime.strftime(timeBegin, '%Y-%m-%d %H:%M:%S')
# addminutes = int(sys.argv[1]);
# addtime=timeBegin + datetime.timedelta(minutes=addminutes)
# addtime_str = datetime.datetime.strftime(addtime, '%Y-%m-%d %H:%M:%S')
# print('begin time: {}'.format(timeBegin_str))
# print('monitor time: {} minutes'.format(addminutes))
# print('end time: {}'.format(addtime_str))




sleeptime=1
monitor_cmd = 'sudo ipmitool sdr'
GPU_monitor_cmd = "nvidia-smi -a | grep 'Power Draw'"

time_log = []
total_power_log = []
cpu_power_log = []
gpu_power_log = []
mem_power_log = []
fan_power_log = []

dict = {}

iter = 0
timeNow = datetime.datetime.now()
while True:
    monitor_log = client.run_command(monitor_cmd)#getoutput(monitor_cmd)
    Total_Power = 0
    CPU_Power = 0
    MEM_Power = 0
    FAN_Power = 0
    HDD_Power = 0
    GPU_Power = 0
    CPU0_Temp = 0
    CPU1_Temp = 0
    Total = 0
    print(monitor_log)
    for data in monitor_log:
        monitor = data.stdout
        host = data.host
        for item in monitor:
            if item.strip().startswith('Total_Power'):
                Total_Power = int(item[ item.find('|')+2 : item.find('Watts')-1 ])
                Total += Total_Power
            elif item.strip().startswith('CPU_Power'):
                CPU_Power = int(item[ item.find('|')+2 : item.find('Watts')-1 ])
            elif item.strip().startswith('Memory_Power'):
                MEM_Power = int(item[ item.find('|')+2 : item.find('Watts')-1 ])
            elif item.strip().startswith('FAN_Power'):
                FAN_Power = int(item[ item.find('|')+2 : item.find('Watts')-1 ])
            elif item.strip().startswith('CPU0_Temp'):
                CPU0_Temp = int(item[ item.find('|')+2 : item.find('degrees')-1 ])
            elif item.strip().startswith('CPU1_Temp'):
                CPU1_Temp = int(item[ item.find('|')+2 : item.find('degrees')-1 ])

        writer.add_scalar(f"Power{host}/Total",Total_Power,iter)
        writer.add_scalar(f"Power{host}/CPU",CPU_Power,iter)
        writer.add_scalar(f"Power{host}/Memory",MEM_Power,iter)
        writer.add_scalar(f"Power{host}/FAN",FAN_Power,iter)
        print(host,Total_Power,CPU_Power,MEM_Power,FAN_Power)

    GPU_monitor_log = client.run_command(GPU_monitor_cmd)
    for data in GPU_monitor_log:
        host = data.host
        for index,item in enumerate(data.stdout):
            GPU_Power = float(item.split(":")[1][1:-2])#int(item[ item.find('|')+2: item.find('W')-1 ])
            writer.add_scalar(f"Power{host}/GPU{index}",GPU_Power,iter)

    iter += 1
    print(".")
writer.close()