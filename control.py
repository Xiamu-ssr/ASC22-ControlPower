import os
_help = "help:\ncpu fanauto fan gpu help\ncpu:set cpu freq\nfanauto:fan auto\n\
                fan:set fan speed\ngpu:set gpu freq"
while True:
    line = input(">>>")
    try:
        try:
            cmd,server,arg = line.split()
        except:
            cmd,server = line.split()
            arg = -1
        if cmd == 'cpu':
            os.system(f"bash set-cpu-freq.sh {server} {arg}")
        elif cmd == 'fanauto':
            os.system(f"bash set-fan-auto.sh {server} {arg}")
        elif cmd == 'fan':
            arg = hex(int(arg))
            os.system(f"bash set-fan-speed.sh {server} {arg}")
        elif cmd == 'gpu':
            os.system(f"bash set-gpu-freq.sh {server} {arg}")
        elif cmd == 'help':
            print(_help)
    except Exception as e:
        print(_help)