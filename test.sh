
get_level(){
  echo $1
  echo $2
  flag=0
  for i in $1; do
    if [[ $2 > $i ]];then
      flag=$((flag+1))
    else
      break
    fi
  done
  echo $flag
  return 0
}

cpu_temp_holder=( 70 75 80 )
cpu_temp_avg=74
cpu_temp_level=$(get_level "${cpu_temp_holder[*]}" $cpu_temp_avg)
echo $cpu_temp_level