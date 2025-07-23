#!/bin/sh

# Write 10 minutes of data
fio --filename=/dev/bcache0 --name=4k_randwrite --ioengine=libaio  --direct=1 --rw=randwrite --bs=4k --iodepth=16 --numjobs=1 --runtime=600 --group_reporting

iostat -x -m -t 30 > /run/iostat.txt &

DIRTY_FILE="/sys/block/bcache0/bcache/dirty_data"
LOG_FILE="/run/dirty_log.txt"

echo "$(date '+%F %T') start monitoring." > "$LOG_FILE"
echo "The initial value of dirty_data:" >> "$LOG_FILE" 
cat "$DIRTY_FILE" >> "$LOG_FILE"

# Trigger full-speed write-back
echo 0 > /sys/block/bcache0/bcache/writeback_percent

while true; do
    VAL=$(cat "$DIRTY_FILE")

    if [ "$VAL" == "0.0k" ]; then
        echo "$(date '+%F %T') dirty_data is 0. Exit monitoring." >> "$LOG_FILE"
        break
    fi

    sleep 1
done
