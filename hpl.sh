#!/bin/bash

#cmd="$1"

# Get the list of hosts from the hosts.txt file
hosts_file="hostfile.txt"
# 打开功率调节
cat "$hosts_file" | xargs -P 10 -I {} ssh -o ConnectTimeout=5 {} "echo "shiyucheng" | sudo -S nvidia-smi -pm 1"
cat "$hosts_file" | xargs -P 10 -I {} ssh -o ConnectTimeout=5 {} "echo "shiyucheng" | sudo -S nvidia-smi -ac 1512,1080"
sudo nvidia-smi -ac 1512,1080
cat "$hosts_file" | xargs -P 10 -I {} ssh -o ConnectTimeout=5 {} "echo "shiyucheng" | sudo -S cpupower -c all frequency-set -g performance"
#parallel-ssh -h hosts.txt -i -t 0 "echo "shiyucheng" | sudo -S nvidia-smi -pm 1"
#parallel-ssh -h hosts.txt -i -t 0 "echo "shiyucheng" | sudo -S nvidia-smi -ac 1512,1080"
#parallel-ssh -h hosts.txt -i -t 0 "echo "shiyucheng" | sudo -S cpupower -c all frequency-set -g performance"
# 启动程序并将输出重定向到文件
bash run2 > output.txt &

# 初始化变量
flag=0

# 等待程序输出特定信息，然后执行其他程序
while :
do
    tail -n 1 output.txt
    if grep -q "Optimization..." output.txt
    then
        
        if [ $flag -eq 0 ]
        then
            echo "任务运行至GPU，开始执行调节功率程序"
                #parallel-ssh -h hosts.txt -i -t 0 "sudo nvidia-smi -ac 1512,1215"
            #parallel-ssh -h hosts.txt -i -t 0 "sudo nvidia-smi -ac 1512,1215"
            #parallel-ssh -h hosts.txt -i -t 0 "sudo sudo cpupower -c all frequency-set -u 1540096"  
            sudo nvidia-smi -ac 1512,1305
            cat "$hosts_file" | xargs -P 10 -I {} ssh -o ConnectTimeout=5 {} "echo "shiyucheng" | sudo -S nvidia-smi -ac 1512,1305"
            #sudo nvidia-smi -ac 1512,1020
            cat "$hosts_file" | xargs -P 10 -I {} ssh -o ConnectTimeout=5 {} "echo "shiyucheng" | sudo -S cpupower -c all frequency-set -u 30000020"
            # 设置标记
            flag=1
        fi
    fi
    
    # 判断程序是否结束
    if ! pgrep -f "bash run2" > /dev/null
    then
        break
    fi
    
    sleep 0.1
done

 echo "脚本执行完毕，关闭功率调节"
#关闭功率调节
cat "$hosts_file" | xargs -P 10 -I {} ssh -o ConnectTimeout=5 {} "echo "shiyucheng" | sudo -S nvidia-smi -pm 0"
#parallel-ssh -h hosts.txt -i -t 0 "sudo nvidia-smi -pm 0"
# 程序执行结束，暂停一段时间后结束脚本