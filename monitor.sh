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
  server_info["cpu_power"]=$(echo $info | grep -oE 'power[0-9]:\s[0-9]+\.[0-9]+\sW' | grep -oE '[0-9]+\.[0-9]+')
  server_info["gpu_temp"]=$(echo $info | grep -oE '[0-9]+,' | grep -oE '[0-9]+')
  server_info["gpu_power"]=$(echo $info | grep -oE ',\s[0-9]+\.[0-9]+\sW' | grep -oE '[0-9]+\.[0-9]+')
  declare -p server_info
}

## Main
localhost="192.168.0.131"
servers=( "192.168.0.131" )

while true; do
  cpu_temp_sum=0
  cpu_temp_cot=0
  cpu_powe_sum=0
  gpu_temp_sum=0
  gpu_temp_cot=0
  gpu_powe_sum=0
  
  cpu_temp_avg=0
  gpu_temp_avg=0
  power_sum=0
  # echo "============================================================"
  # echo "   Average Power Consumption and Temperature of All Servers"
  # echo "============================================================"
  printf "|%-16s|%-16s|%-16s|%-10s|%-10s|%-10s|%-10s|\n" "Server(IP)" "CPU Temp(avg)" "CPU Power(sum)" "GPU1 Temp" "GPU2 Temp" "GPU1 Power" "GPU2 Power"
  for server in "${servers[@]}"; do
    echo -n "try get server info form $server."
    eval "$(get_server_info $server)"
    echo -n "got it! and then process it"
    tput cr
    tput el
    cpu_temp_tmp=${server_info[cpu_temp]}
    cpu_powe_tmp=${server_info[cpu_power]}
    gpu_temp_tmp=(${server_info[gpu_temp]})
    gpu_powe_tmp=(${server_info[gpu_power]})
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
  clear
  printf "|%-16s|%-16s|%-16s|%-16s|%-16s|\n" "Power SUM" "CPU Power(sum)" "GPU Power(sum)" "CPU Temp(avg)" "GPU Temp(avg)"
  printf "|%-16s|%-16s|%-16s|%-16s|%-16s|\n" $power_sum $cpu_powe_sum $gpu_powe_sum $cpu_temp_avg $gpu_temp_avg
  echo ""
  sleep 0.5s
done