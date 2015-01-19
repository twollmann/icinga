
1. Check if /tmp/traffic_$dev.txt exists. Set the history file via parameter

	If not:	set last_input and last_output to '0'

2. Catch /proc/net/dev

	=> grep the interface
	=> split input and output

3. Compare last values to current values.

	If current is higher everythings ok.

	Else: get size of an integer. Substract the last value from the size of an integer
		and add the current value to the result.
