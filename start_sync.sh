#!/bin/bash
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
while true; do
    start_time=$(date +%s)
    /usr/bin/php $script_dir/sync_data.php
    
    end_time=$(date +%s)
    elapsed_time=$((end_time - start_time))
    if [ $elapsed_time -lt 10 ]; then
        sleep $((10 - elapsed_time))
    fi
done
