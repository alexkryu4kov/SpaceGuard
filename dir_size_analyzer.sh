#!/bin/bash

directory="/"
recursive=false

directories_to_check=(/home /var/tmp /var/cache /var/log)

exclude_list=(/proc /sys /run /dev /mnt /tmp)

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

convert_to_mb() {
    size=$1
    num=$(echo $size | sed 's/[A-Za-z]//g') # Extract number
    unit=$(echo $size | sed 's/[0-9.]//g') # Extract unit

    case $unit in
        K|k) num=$(echo "$num / 1024" | bc -l) ;;
        G|g) num=$(echo "$num * 1024" | bc -l) ;;
        T|t) num=$(echo "$num * 1048576" | bc -l) ;;
        *) ;; # Assume MB if no unit
    esac

    echo "$num"
}

calculate_size() {
    dir=$1

    # Check if the directory exists
    if [ ! -d "$dir" ]; then
        echo "Directory does not exist: $dir"
        return 1
    fi

    # Run du without suppressing error messages
    size=$(du -sh "$dir" | awk '{print $1}')

    size_in_mb=$(convert_to_mb "$size")
    size_in_mb=$(printf "%.0f" "$size_in_mb")

    if [ -z "$size" ]; then
        echo "Failed to calculate size for: $dir"
    elif [ "$size_in_mb" -gt 500 ]; then 
        echo "$dir $size"
    fi
}

process_directory() {
    local dir=$1
    calculate_size "$dir"
    for subdir in "$dir"/*; do
        if [ -d "$subdir" ]; then
            calculate_size "$subdir"
        fi
    done
}

display_progress() {
    current=$1
    total=$2
    percent=$(( 100 * current / total ))
    echo -ne "Processing: $current/$total directories (${percent}%)\\r"
}

is_blacklisted() {
    local dir=$1
    for blacklisted_dir in "${blacklist[@]}"; do
        if [ "$dir" == "$blacklisted_dir" ]; then
            return 0 # found in blacklist
        fi
    done
    return 1 # not found in blacklist
}

total_dirs=${#directories_to_check[@]}
current_dir=0

for dir in "${directories_to_check[@]}"; do
   current_dir=$((current_dir + 1))
   display_progress $current_dir $total_dirs
   if [ -d "$dir" ] && ! is_blacklisted "$dir"; then
	process_directory "$dir"
   else
	echo "Skipped blacklisted directory: $dir"
   fi
done
