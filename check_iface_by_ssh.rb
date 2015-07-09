# for i in bytes packets errors dropped; \
# do \
# cat /sys/class/net/eth0/statistics/tx_$i; \
# cat /sys/class/net/eth0/statistics/rx_$i; \
# done | sed ':a;N;$!ba;s/\n/;/g'
