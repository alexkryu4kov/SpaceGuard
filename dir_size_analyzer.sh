#!/bin/bash

directory="/"
recursive=false

exclude_list="/proc /sys /dev /mnt /tmp"

while [[ $# -gt 0 ]]; do
	case $1 in
		--sort)
			sort_option=$2
			shift
			;;
		--min-size)
			min_size=$2
			shift
			;;
		--recursive)
			recursive=true
			;;
		--directory)
			directory=$2
			shift
			;;
		*)
			echo "Unknown option: $1"
			exit 1
			;;
	esac
	shift
done

directories=$(find "$directory" -type d \( -path "$directory$exclude_list" -prune \) -o -print)

if [ -n "$sort_option" ]; then
	directories=$(echo "$directories" | sort -k2,2$([[ $sort_option == "desc" ]] && echo "r"))
fi

if [ -n "$min_size" ]; then
	directories=$(echo "$directories" | while read dir; do
		size=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')
		[[ "$size" > "$min_size" ]] && echo "$dir $size"
	done)
fi

echo "$directories"

echo "[Directory] [Size]"
for dir in $directories; do
	if [ -r "$dir" ]; then
		size=$(du -sh$([[ $recursive == true ]] && echo " -r") "$dir" 2>/dev/null | awk '{print $1}')
		echo "$dir $size"
	fi
done
