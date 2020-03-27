function love.load()
	--f = io.popen ([[neofetch --stdout | sed "s/_/ /g ; s/love/nepfetch-clone/g"]])
	f = io.popen ([[
		eval $(cat /etc/os-release)
		while IFS=':k '  read -r key val _; do
			case $key in
				MemTotal)
					mem_used=$((mem_used + val))
					mem_full=$val
				;;
				Shmem)
					mem_used=$((mem_used + val))
				;;
				MemFree|Buffers|Cached|SReclaimable)
					mem_used=$((mem_used - val))
				;;
			esac
		done < /proc/meminfo
		mem_used=$(echo "$mem_used / 1048576" | bc -l | sed "s/^\./0\./g" | awk '{print substr($1,0,4)}')
		mem_full=$(echo "$mem_full / 1048576" | bc -l | sed "s/^\./0\./g" | awk '{print substr($1,0,4)}')

		getcpu () {
			cpu_file="/proc/cpuinfo"

			case $kernel_machine in
				"frv" | "hppa" | "m68k" | "openrisc" | "or"* | "powerpc" | "ppc"* | "sparc"*)
					cpu="$(awk -F':' '/^cpu\t|^CPU/ {printf $2; exit}' "$cpu_file")"
				;;

				"s390"*)
					cpu="$(awk -F'=' '/machine/ {print $4; exit}' "$cpu_file")"
				;;

				"ia64" | "m32r")
					cpu="$(awk -F':' '/model/ {print $2; exit}' "$cpu_file")"
					]] .. "[[" .. [[  -z "$cpu" ]] .. "]]" .. [[ && cpu="$(awk -F':' '/family/ {printf $2; exit}' "$cpu_file")"
				;;

				*)
					cpu="$(awk -F '\\s*: | @' \
							'/model name|Hardware|Processor|^cpu model|chip type|^cpu type/ {
							cpu=$2; if ($1 == "Hardware") exit } END { print cpu }' "$cpu_file")"
				;;
			esac

			speed_dir="/sys/devices/system/cpu/cpu0/cpufreq"

			if ]] .. "[[" .. [[ -d "$speed_dir" ]] .. "]]" .. [[; then
				# Fallback to bios_limit if $speed_type fails.
				speed="$(< "${speed_dir}/${speed_type}")" ||\
				speed="$(< "${speed_dir}/bios_limit")" ||\
				speed="$(< "${speed_dir}/scaling_max_freq")" ||\
				speed="$(< "${speed_dir}/cpuinfo_max_freq")"
				speed="$((speed / 1000))"

			else
				speed="$(awk -F ': |\\.' '/cpu MHz|^clock/ {printf $2; exit}' "$cpu_file")"
				speed="${speed/MHz}"
			fi

			cpu="${cpu//(TM)}"
			cpu="${cpu//(tm)}"
			cpu="${cpu//(R)}"
			cpu="${cpu//(r)}"
			cpu="${cpu//CPU}"
			cpu="${cpu//Processor}"
			cpu="${cpu//Dual-Core}"
			cpu="${cpu//Quad-Core}"
			cpu="${cpu//Six-Core}"
			cpu="${cpu//Eight-Core}"
			cpu="${cpu//[1-9][0-9]-Core}"
			cpu="${cpu//[0-9]-Core}"
			cpu="${cpu//, * Compute Cores}"
			cpu="${cpu//Core / }"
			cpu="${cpu//(\"AuthenticAMD\"*)}"
			cpu="${cpu//with Radeon * Graphics}"
			cpu="${cpu//, altivec supported}"
			cpu="${cpu//FPU*}"
			cpu="${cpu//Chip Revision*}"
			cpu="${cpu//Technologies, Inc}"
			cpu="${cpu//Core2/Core 2}"

			speed="${speed//]] .. "[[" .. [[:space:]] .. "]]" .. [[}"

			cpu="${cpu/AMD }"
			cpu="${cpu/Intel }"
			cpu="${cpu/Core? Duo }"
			cpu="${cpu/Qualcomm }"


			if (( speed < 1000 )); then
				cpu="$cpu ${speed}MHz"
			else
				speed="$((speed / 100))"
				speed="${speed:0:1}.${speed:1}"
				cpu="$cpu ${speed}GHz"
			fi

			# Format the output
			cpu="$cpu $deg"
			printf "CPU     ${cpu}\n"
		}

#		printf "${USER}@$(cat /etc/hostname)\n"
		printf "OS       $PRETTY_NAME\n"
		printf "Host     $(cat /sys/devices/virtual/dmi/id/product_version)\n"
		printf "Kernel   $(uname -r | sed -e 's/-.*//')\n"
		printf "Uptime   $(uptime | awk -F'( |,|:)+' '{print $6"d "$8"h "$9"m"}')\n"
		getcpu
		which pacman &> /dev/null && printf "Packages $(pacman -Qeq | wc -l) ($(pacman -Qq | wc -l))\n"
		printf "Memory   ${mem_used}G / ${mem_full}G\n"
	for i in /dev/sd??; do
		df -h | grep $i |
		awk -v disk="$i" '{print disk "  " ($3+0) "/" ($2)}' |
		sed -e 's|/dev/sd|Disk |g' 
	done
		printf "Theme    $(cat ${XDG_CONFIG_DIR:-$HOME/.config}/gtk-3.0/settings.ini | grep 'gtk-theme-name=' | sed -e "s/gtk-theme-name=//")"
	 
	]])

	l=0
	str=""
	for line in f:lines() do
		str=str .. line .. '\n'
		l=l+1
	end
	
	font=love.graphics.newFont("font.ttf",16)
	love.graphics.setFont(font)

	nep=love.graphics.newImage("nep.png")
	width=nep:getWidth()
	height=nep:getHeight()
	s=0.65

	love.window.setMode(width*s,height*s)

	m=5
	x=m
	y=(math.floor(height*s) - font:getHeight()*l) - m
end
--function love.resize(w,h)
--	if w > h then w=width/height
--	else h=height/width end
--	love.window.setMode(w,h,ot)
--end

function love.draw()
	love.graphics.draw(nep,0,0,0,s,s)

	love.graphics.setColor(0,0,0,1)
	love.graphics.print(str,x-1,y,0,1,1,1)
	love.graphics.print(str,x+1,y,0,1,1,1)
	love.graphics.print(str,x,y-1,0,1,1,1)
	love.graphics.print(str,x,y+1,0,1,1,1)

	love.graphics.setColor(1,1,1,1)
	love.graphics.print(str,x,y,0,1,1,1)
end
