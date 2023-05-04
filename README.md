# ASC22-ControlPower
控制机器功耗脚本
主要控制三个点
* cpu频率
* 风扇转速(主板上的不是gpu上的)
* gpu频率

## 前置准备
### 服务器之间设置好ssh免密
### 安装相关工具包
sensors\
cpupower\
parallel-ssh\
fancontrol\
nvidia-smi\
```apt install lm-sensors linux-tools-common pssh fancontrol```
### 查看cpu和gpu信息
```cpupower -c all frequency-info```
注意cpu最低最高频率\
```nvidia-smi -q```
注意gpu最低最高频率\
```nvidia-smi -q -d SUPPORTED_CLOCKS```
查看你gpu支持设置的频率\
```nvidia-smi -pm 1 ```
打开编写模式\
```nvidia-smi -ac 1512,1200```\
```nvidia-smi ```
验证是否修改成功\
```vidia-smi -pm 0 ```
把编写模式关闭。

## 脚本
### auto.sh
自动监控服务器并调整
```bash
# cpu temp higher -> faster fan + lower cpu freq
cpu_temp_holder=( 70 75 80 )
cpu_temp_holder_fan_speed=( "0x46" "0x50" "0x5a" "0x64" )
cpu_temp_holder_cpu_freq=( 2100000 2000000 1900000 1800000 )
# cpu power higher -> slower fan + lower cpu freq
cpu_powe_holder=( 800 900 1000 )
cpu_powe_holder_fan_speed=( "0x64" "0x5a" "0x50" "0x46" )
cpu_powe_holder_cpu_freq=( 2100000 2000000 1900000 1800000 )

# gpu temp higher -> slower gpu freq
gpu_temp_holder=( 70 74 78 )
gpu_temp_holder_gpu_freq=( 1410 1380 1290 1200 )
# gpu power higher -> slower gpu freq
gpu_powe_holder=( 1700 1850 2000 )
gpu_powe_holder_gpu_freq=( 1410 1380 1290 1200 )
```
当cpu温度小于70时,level=0,cpu频率设置为2100000（最高）,风扇设置为70%\
当cpu温度70-75时,level=1,cpu频率2000000,风扇80%
以此类推\
但是cpu温度过高和cpu+mem....一起的power过高时,调整策略都是cpu频率和风扇,防止一方覆盖另一方的策略导致一方策略无效\
```bash
if [ $cpu_temp_level -gt $cpu_powe_level ]; then
    set_cpu_frequency ${cpu_temp_holder_cpu_freq[$cpu_temp_level]}
    set_fan ${cpu_temp_holder_fan_speed[$cpu_temp_level]}
  else
    set_cpu_frequency ${cpu_powe_holder_cpu_freq[$cpu_powe_level]}
    set_fan ${cpu_powe_holder_fan_speed[$cpu_powe_level]}
  fi
```
谁的level高走谁的策略,gpu也是如此
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