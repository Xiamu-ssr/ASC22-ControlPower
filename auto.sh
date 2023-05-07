#!/bin/bash

#input : single server ip or name
#output : declare array
get_server_info(){
  server=$1
  local info=""
  if [[ "$server" == $localhost ]]; then
    info=$(sensors | grep -E 'Core|power[0-9]' ; nvidia-smi --query-gpu=temperature.gpu,power.draw --format=csv | grep -E ' W')
  else
    info=$(ssh "$server" sensors | grep -E 'Core|power[0-9]' ; nvidia-smi --query-gpu=temperature.gpu,power.draw --format=csv | grep -E ' W')
  fi
  declare -A server_info
  server_info["cpu_temp"]=$(echo $info | grep -oE ':\s[+-][0-9]+\.[0-9]+°C'  | grep -oE '[0-9]+\.[0-9]')
  server_info["cpu_power"]=$(echo $info | grep -oE 'power[0-9]:\s[0-9]+.[0-9]+\sW' | grep -oE '[0-9]+\.[0-9]+')
  server_info["gpu_temp"]=$(echo $info | grep -oE '[0-9]+,' | grep -oE '[0-9]+')
  server_info["gpu_power"]=$(echo $info | grep -oE ',\s[0-9]+.[0-9]+\sW' | grep -oE '[0-9]+\.[0-9]+')
  declare -p server_info
}

#input : cpu freq 2100000
#output : none
set_cpu_frequency(){
  parallel-ssh -h $hostfile -i -t 0 "cpupower -c all frequency-set -u $1 > /dev/null"
}

#input : gpu freq 1410
#output : none
set_gpu_frequency(){
  parallel-ssh -h $hostfile -i -t 0 "nvidia-smi -ac 1512,$1 > /dev/null"
}

#input : fan speed 0x64
#output : none
set_fan(){
  parallel-ssh -h $hostfile -i -t 0 "ipmitool raw 0x3C 0x2D 0xFF $1 > /dev/null"
}

#input : arr and a single
#output : level
get_level(){
  local flag=0
  for i in $1; do
    if [[ $(echo "$2 > $i" | bc -l) -eq "1" ]]; then
      flag=$((flag+1))
    else
      break
    fi
  done
  echo $flag
}

## Main
localhost="192.168.1.110"
servers=( "192.168.1.110")
hostfile="hostfile.txt"
# cpu temp higher -> faster fan + lower cpu freq
cpu_temp_holder=( 70 76 82 )
cpu_temp_holder_fan_speed=( "0x46" "0x50" "0x5a" "0x64" )
cpu_temp_holder_cpu_freq=( 2100000 2000000 1900000 1800000 )
# cpu power higher -> slower fan + lower cpu freq
cpu_powe_holder=( 800 900 1000 )
cpu_powe_holder_fan_speed=( "0x64" "0x5a" "0x50" "0x46" )
cpu_powe_holder_cpu_freq=( 2100000 2000000 1900000 1800000 )

# gpu temp higher -> slower gpu freq
gpu_temp_holder=( 70 75 80 )
gpu_temp_holder_gpu_freq=( 1410 1380 1290 1200 )
# gpu power higher -> slower gpu freq
gpu_powe_holder=( 1700 1850 2000 )
gpu_powe_holder_gpu_freq=( 1410 1380 1290 1200 )

while true; do
  cpu_temp_sum=0
  cpu_temp_cot=0
  cpu_temp_avg=0
  cpu_powe_sum=0

  gpu_temp_sum=0
  gpu_temp_cot=0
  gpu_temp_avg=0
  gpu_powe_sum=0
  
  power_sum=0

  printf "|%-16s|%-16s|%-16s|%-10s|%-10s|%-10s|%-10s|\n" "Server(IP)" "CPU Temp(avg)" "CPU Power(sum)" "GPU1 Temp" "GPU2 Temp" "GPU1 Power" "GPU2 Power"
  for server in "${servers[@]}"; do
    echo -n "try get server info form $server."
    eval "$(get_server_info $server)"
    echo -n "got it! and then process it"
    tput cr
    tput el
    cpu_temp_tmp=${server_info[cpu_temp]}
    cpu_powe_tmp=${server_info[cpu_power]}
    # gpu_temp_tmp=(${server_info[gpu_temp]})
    gpu_temp_tmp=( 25 26 )
    # gpu_powe_tmp=(${server_info[gpu_power]})
    gpu_powe_tmp=( 54 56)
    #计算单台服务器cpu总温度和cpu总核数
    cpu_t_sum_local=0
    cpu_t_cot_local=0
    for t in ${cpu_temp_tmp[@]}; do
      cpu_t_sum_local=$(echo "$cpu_t_sum_local + $t" | bc)
      cpu_t_cot_local=$(echo "$cpu_t_cot_local + 1" | bc)
    done
    printf "|%-16s|%-16s|%-16s|%-10s|%-10s|%-10s|%-10s|\n" $server $(echo "scale=2; $cpu_t_sum_local / $cpu_t_cot_local" | bc) $cpu_powe_tmp ${gpu_temp_tmp[0]} ${gpu_temp_tmp[1]} ${gpu_powe_tmp[0]} ${gpu_powe_tmp[1]}
    #累加到全局统计
    cpu_temp_sum=$(echo "$cpu_temp_sum + $cpu_t_sum_local" | bc)
    cpu_temp_cot=$(echo "$cpu_temp_cot + $cpu_t_cot_local" | bc)
    cpu_powe_sum=$(echo "$cpu_powe_sum + $cpu_powe_tmp" | bc)
    gpu_temp_sum=$(echo "$gpu_temp_sum + ${gpu_temp_tmp[0]} + ${gpu_temp_tmp[1]}" | bc)
    gpu_temp_cot=$(echo "$gpu_temp_cot + ${#gpu_temp_tmp[@]} " | bc)
    gpu_powe_sum=$(echo "$gpu_powe_sum + ${gpu_powe_tmp[0]} + ${gpu_powe_tmp[1]}" | bc)
  done
  cpu_temp_avg=$(echo "scale=2; $cpu_temp_sum / $cpu_temp_cot" | bc)
  gpu_temp_avg=$(echo "scale=2; $gpu_temp_sum / $gpu_temp_cot" | bc)
  power_sum=$(echo "$cpu_powe_sum + $gpu_powe_sum" | bc)
  sleep 3s
  clear
  printf "|%-16s|%-16s|%-16s|%-16s|%-16s|\n" "Power SUM" "CPU Power(sum)" "GPU Power(sum)" "CPU Temp(avg)" "GPU Temp(avg)"
  printf "|%-16s|%-16s|%-16s|%-16s|%-16s|\n" $power_sum $cpu_powe_sum $gpu_powe_sum $cpu_temp_avg $gpu_temp_avg
  echo ""
  # get level
  cpu_temp_level=$(get_level "${cpu_temp_holder[*]}" $cpu_temp_avg)
  cpu_powe_level=$(get_level "${cpu_powe_holder[*]}" $cpu_powe_sum)
  gpu_temp_level=$(get_level "${gpu_temp_holder[*]}" $gpu_temp_avg)
  gpu_powe_level=$(get_level "${gpu_powe_holder[*]}" $gpu_powe_sum)
  echo "cpu temp level$cpu_temp_level"
  echo "cpu power level$cpu_powe_level"
  echo "gpu temp level$gpu_temp_level"
  echo "gpu powe level$gpu_powe_level"

  #谁的level高按谁的策略走,不然后者会覆盖前者,=走power
  # if (( $cpu_temp_level > $cpu_powe_level )); then
  #   echo "use cpu temp strategy"
  #   set_cpu_frequency ${cpu_temp_holder_cpu_freq[$cpu_temp_level]}
  #   set_fan ${cpu_temp_holder_fan_speed[$cpu_temp_level]}
  # else
  #   echo "use cpu power strategy"
  #   set_cpu_frequency ${cpu_powe_holder_cpu_freq[$cpu_powe_level]}
  #   set_fan ${cpu_powe_holder_fan_speed[$cpu_powe_level]}
  # fi

  # if (( $gpu_temp_level > $gpu_powe_level )); then
  #   set_gpu_frequency ${gpu_temp_holder_gpu_freq[$gpu_temp_level]}
  # else
  #   set_gpu_frequency ${gpu_powe_holder_gpu_freq[$gpu_powe_level]}
  # fi
  
done
