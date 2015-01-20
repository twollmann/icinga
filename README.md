### Icinga

This repository contains several plugins for the icinga monitoring system. The plugins were written in Ruby language and have been designed to run against Linux servers that only run a sshd. Some of these plugins are still in dev and will not be functional.


#### Requirements

The plugins were developed and tested for Ruby 1.9.3. They were tested to run against the following Linux distributions:

- Ubuntu 12.04 LTS
- Ubuntu 14.04 LTS
- Centos 6

#### Installation

The installation process is quite simple. You only need to clone the git repository with the following command:

> git clone https://github.com/twollmann/icinga.git

The git repository contains a Gemfile to ensure that all required libraries are present. To install unmet dependencies you should run:

> bundle install

If you haven't already install bundler you definitly should. This can be achivied by pulling it via gem with the following command:

> gem install bundler

#### Included scripts

##### check_cpu_by_ssh.rb

###### Status

The status of this script is beta. It can be used in test env and may be used in production.

###### Parameters

- [-H] hostname/ip address of the remote host. 
- [-u] user on the remote host.
- [-t] time period used to mesure the cpu utilization
- [-m] utilization mode (0=total; 1=user; 2=nice; 3=system).
- [-w] threshold for a warning.
- [-c] threshold for a critical.
