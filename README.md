# ASC22-ControlPower
脚本自动控制机器功耗

## 前置准备
### 1. 服务器之间设置好ssh免密
### 2. 安装相关工具包
cpupower```apt install linux-tools-common```

nvidia-smi
### 3. 查看cpu和gpu信息
```cpupower -c all frequency-info```
```
analyzing CPU 31:
  driver: intel_pstate
  CPUs which run at the same hardware frequency: 31
  CPUs which need to have their frequency coordinated by software: 31
  maximum transition latency:  Cannot determine or is not supported.
  hardware limits: 800 MHz - 2.10 GHz
  available cpufreq governors: performance powersave
  current policy: frequency should be within 800 MHz and 2.10 GHz.
                  The governor "performance" may decide which speed to use
                  within this range.
  current CPU frequency: Unable to call hardware
  current CPU frequency: 2.10 GHz (asserted by call to kernel)
  boost state support:
    Supported: no
    Active: no
```
```nvidia-smi -q```
```
GPU 00000000:AF:00.0
    Product Name                          : NVIDIA A100 80GB PCIe
    Temperature
        GPU Current Temp                  : 31 C
        GPU Shutdown Temp                 : 92 C
        GPU Slowdown Temp                 : 89 C
        GPU Max Operating Temp            : 85 C
        GPU Target Temperature            : N/A
        Memory Current Temp               : 46 C
        Memory Max Operating Temp         : 95 C
    Power Readings
        Power Management                  : Supported
        Power Draw                        : 65.46 W
        Power Limit                       : 300.00 W
        Default Power Limit               : 300.00 W
        Enforced Power Limit              : 300.00 W
        Min Power Limit                   : 150.00 W
        Max Power Limit                   : 300.00 W
    Clocks
        Graphics                          : 1410 MHz
        SM                                : 1410 MHz
        Memory                            : 1512 MHz
        Video                             : 1275 MHz
    Applications Clocks
        Graphics                          : 1410 MHz
        Memory                            : 1512 MHz
    Default Applications Clocks
        Graphics                          : 1410 MHz
        Memory                            : 1512 MHz
    Max Clocks
        Graphics                          : 1410 MHz
        SM                                : 1410 MHz
        Memory                            : 1512 MHz
        Video                             : 1290 MHz
```
```nvidia-smi -q -d SUPPORTED_CLOCKS```查看你gpu支持设置的频率

```nvidia-smi -pm 1 ```打开编写模式。

```nvidia-smi -ac 1512,1200```

```nvidia-smi ```验证是否修改成功

```vidia-smi -pm 0 ```把编写模式关闭。

## 脚本解释
### 函数
* get_server_info()
> #input : single server ip or name\
> #output : declare array

* up_cpu_frequency() down_cpu_frequency()
> #input : single server ip or name\
> #output : none

* up_gpu_frequency() down_gpu_frequency()
> #input : single server ip or name\
> #output : none

* fast_fan() slow_fan()
> #input : single server ip or name\
> #output : none

### 参数
```
## Main
localhost="192.168.0.131"
servers=( "192.168.0.131" )
cpu_temp_holder=80
gpu_temp_holder=80
cpu_powe_holder=1000
gpu_powe_holder=2000
```

### 流程控制
```bash
## adjust
  # cpu temp low, power ok -> up cpu freq and slow fan
  if (( $(echo "$cpu_temp_avg < $cpu_temp_holder" | bc -l) )) && (( $(echo "$cpu_powe_sum < $cpu_powe_holder" | bc -l) )); then
    for server in "${servers[@]}"; do
      up_cpu_frequency $server
      fast_fan $server
    done
  # else -> down cpu freq and fast fan
  else
    for server in "${servers[@]}"; do
      down_cpu_frequency $server
      fast_fan $server
    done
  fi
  # gpu temp low, power ok -> up gpu freq
  if (( $(echo "$gpu_temp_avg < $gpu_temp_holder" | bc -l) )) && (( $(echo "$gpu_powe_sum < $gpu_powe_holder" | bc -l) )); then
    for server in "${servers[@]}"; do
      up_gpu_frequency $server
    done
  # else -> down gpu freq
  else
    for server in "${servers[@]}"; do
      down_gpu_frequency $server
    done
  fi
```

## 使用
在localhost上bash xxx.sh

## 检验
* 检验cpu是否升降频
```
watch -n 1 cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq
```
* 检验gpu是否升降频
```
nvidia-smi -q
```
* 检验风扇是否升降速
```
watch -n 1 "ipmitool sensor | grep FAN"
```