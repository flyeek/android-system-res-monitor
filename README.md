# android-system-res-monitor
An shell script to monitor key system resources for an android process, including thread, file descriptor and memory.

## Introduce
`sys-res-watcher.sh` is an shell script to monitor some key system resource info of running app. It Can be used to detect the resource leak in the process of testing your app as soon as possible. Now support the following kind of resource:
- Thread. Aggregate threads by name, and calculate the number of the same threads, then display the ranking.
- Fd(File Descriptor). Aggregate fd by type, and calculate the number of the same fd type, then display the ranking.
- Memory. Display the memory Pss info of app's process(main as default), including Total, DalvikHeap, NativeHeap and so on in different script running condition.

## Usage
