# ASC22-ControlPower
控制机器功耗脚本
主要控制三个点
* cpu频率
* 风扇转速(主板上的不是gpu上的)
* gpu频率

## 前置准备
### 服务器之间设置好ssh免密
### 安装相关工具包
sensors```apt install lm-sensors```\
cpupower```apt install linux-tools-common```\
parallel-ssh```apt-get install pssh```\
fancontrol```apt install fancontrol```\
nvidia-smi
### 查看cpu和gpu信息
```cpupower -c all frequency-info```注意cpu最低最高频率\
```nvidia-smi -q```注意gpu最低最高频率\
```nvidia-smi -q -d SUPPORTED_CLOCKS```查看你gpu支持设置的频率\
```nvidia-smi -pm 1 ```打开编写模式\
```nvidia-smi -ac 1512,1200```\
```nvidia-smi ```验证是否修改成功\
```vidia-smi -pm 0 ```把编写模式关闭。

## 脚本
### auto.sh
自动监控服务器并调整
```
## Main
localhost="192.168.0.131"
servers=( "192.168.0.131" )
hostfile="hostfile.txt"
cpu_temp_holder=80
gpu_temp_holder=80
cpu_powe_holder=1000
gpu_powe_holder=2000
```
### monitor.sh
只监控不调整
### set-xxx.sh
手动调整
```bash
bash set-xxx.sh ["all"或者IP] [cpu频率或者gpu频率或者风扇转速十六进制0-100比如0x32表示50%]
```

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