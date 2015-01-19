# Icinga

This repository contains several plugins for the icinga monitoring system. \
The plugins were written in Ruby language and have been designed to run against Linux servers that only run a SSH deamon. These plugins are still in dev and NOT functional.


## Requirements

The plugins were developed for Ruby 1.9.3 and have been tested against the following Linux distributions:

- Ubuntu 12.04 LTS
- Ubuntu 14.04 LTS


## Installation




## Parameters

### check_cpu_by_ssh.rb

- [-H] hostname/ip address of the remote host. 
- [-u] user on the remote host.
- [-t] time period used to mesure the cpu utilization
- [-m] utilization mode (0=total; 1=user; 2=nice; 3=system).
- [-w] threshold for a warning.
- [-c] threshold for a critical.
