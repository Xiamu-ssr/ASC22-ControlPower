
get_level(){
  local flag=0
  # echo "var 1=$1"
  # echo "var 2=$2"
  for i in $1; do
    if [[ $(echo "$2 > $i" | bc -l) -eq "1" ]]; then
      flag=$((flag+1))
    else
      break
    fi
  done
  echo $flag
}

cpu_temp_holder=( 70 75 80 )
cpu_temp_avg=90
cpu_temp_level=$(get_level "${cpu_temp_holder[*]}" $cpu_temp_avg)
echo $cpu_temp_level