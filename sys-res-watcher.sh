#! /bin/bash

# Default package name. Can set this to your frequently tested app.
app_package=""

#app_pid="$(pidof ${app_package})"
# ls /proc/${app_pid}/fd > /dev/null 2>&1


THREAD_RANK_MAX=8
FD_RANK_MAX=5

# memory limits of device.
#dalvik_heap_max="$(getprop dalvik.vm.heapsize)"
#native_heap_max="$(cat /proc/meminfo | grep "MemTotal" | awk '{printf "%dm\n", $2/1024}')"


function rank_thread() {
    echo "[ Thread Ranking ]"

    # Enter target dir.
    cd /proc/${app_pid}/task > /dev/null 2>&1

    thread_count="$(cat */comm | wc -l)"
    echo "===> Total thread count is $thread_count. Top ${THREAD_RANK_MAX} are as follows:"
    printf "%-8s %-10s\n" "Count" "Name"
    cat */comm | sort | uniq -c | sort -nr | awk -v rank_max="$THREAD_RANK_MAX" 'BEGIN{sum_rank=0} {sum_rank+=1; if (sum_rank <= rank_max) printf "%-8s %-10s\n", $1, $2}'
}

function rank_fd() {
    echo "\n[ FD Ranking ]"

    # Make sure app is running while enter target dir.
    cd /proc/${app_pid}/fd > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        fd_count="$(ls -l | wc -l)"

        echo "===> Total fd count is $fd_count. Type ranking are as follows:"
        printf "%-8s %-10s\n" "Count" "Type"
        ls -l | awk -F' |:' '{printf "%-10s\n", $11}' | sort | uniq -cd | sort -nr | awk -v rank_max="$FD_RANK_MAX" 'BEGIN{sum_rank=0} {sum_rank+=1; if (sum_rank <= rank_max) printf "%-8s %-10s\n", $1, $2}'
    else
        echo "===> No permission to read fd info. Make sure your current shell env is rooted, or your app is debuggable and execute 'run-as ${app_package}'."
    fi
}

function mem_info() {
    echo "\n[ Memory Info ]"
    echo "===> Memory info is as follows:"

    # Make sure the meminfo service is available.
    dumpsys -l | grep "meminfo" > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        # Has permission to dumpsys meminfo.
        printf "%-15s %-15s %-15s %-15s %-15s %-15s\n" "Total(MB)" "JavaHeap(MB)" "NativeHeap(MB)" "AppContext" "Activities" "ViewRootImpls" 
        dumpsys meminfo -s ${app_package} | egrep "Heap|TOTAL|ViewRootImpl|AppContexts" | xargs | awk '{printf "%-15d %-15d %-15d %-15s %-15s %-15s\n", $8/1024, $3/1024, $6/1024, $18, $20, $16}'
    else
        # No permission, so just calculate the total Pss of process.
        printf "%-15s\n" "Total(MB)"
        cat /proc/${app_pid}/smaps | awk '/^Pss/ && $2 != "0" {a+=$2} END{print int(a/1024)}'
    fi
}

function start_monitor() {
    while true; do
        app_pid="$(pidof ${app_package})"
        if [ $? -eq 0 ]; then
            rank_thread
            rank_fd
            mem_info
        else
            echo "===> Youku App is not running!"
        fi

        sleep 3
        
        clear
    done
}


function print_help() {
    echo "Usage: sh $0 <[Option]|[app-package-name]>"
    echo " Monitor thread, file descriptor and memory of target app."
    echo " Options are:"
    echo " -h --help           Display this information."
    exit 1
}

# Read command input params, and do the right thing.
if [ $# -eq 0 ] && [ -n "${app_package}" ]; then
    start_monitor
elif [ $# -eq 1 ]; then
    if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
        print_help
    else
        app_package="$1"
        start_monitor
    fi
else
    print_help
fi
