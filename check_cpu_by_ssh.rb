#!/usr/bin/env ruby
#
# @file         check_cpu_by_ssh.rb
# @author       Wollmann, Tobias <t.wollmann@bull.de>
# @date         01/19/2014
# @version      0.2
#

require 'net/ssh'
require 'optparse'

#
# Main
#

# Initialize command line parameter hash and set defaults
options = {:hostname=>nil, :username=>nil, :warning=>90, :critical=>95}
optparse = OptionParser.new do |opts|
  opts.banner = "Nagios plugin to gather filesystem information of a remote host."
  opts.on("-H", "--hostname hostname", "Hostname or IP-address of the remote system.") do |host|
    options[:hostname] = host
  end
  opts.on("-u", "--username username", "Username of the monitoring account on the Server.") do |user|
    options[:username] = user
  end
  opts.on("-d", "--delay delay", "Delay betwen two checks.") do |delay|
    options[:delay] =  delay
  end
  opts.on("-w", "--warning warning", "Warning threshold.") do |warn|
    options[:warning] =  warn
  end
  opts.on("-c", "--critical critical", "Critical threshold.") do |crit|
    options[:critical] =  crit
  end
end.parse!

# Get the command line parameters and assign it to variables
hostname   = options[:hostname]
username   = options[:username]
warning    = options[:warning]
critical   = options[:critical]

if hostname == nil
  puts "The hostname is a neccessary parameter."
  exit 3
elsif username == nil
  puts "The username is a neccessary parameter."
  exit 3
elsif delay == nil
  delay = 2
end

# Get information about the cpu usage
cpu_info_1 = Net::SSH.start(hostname, username) do |ssh|
  ssh.exec!("cat /proc/stat | grep -i '^cpu  '").split
end

sleep(delay.sec)

cpu_info_2 = Net::SSH.start(hostname, username) do |ssh|
  ssh.exec!("cat /proc/stat | grep -i '^cpu  '").split
end

# - user: normal processes executing in user mode
# - nice: niced processes executing in user mode
# - system: processes executing in kernel mode
# - idle: twiddling thumbs

# Calculate the CPU utilization
cpu_user   = cpu_info_2.at(1).to_i - cpu_info_1.at(1).to_i
cpu_nice   = cpu_info_2.at(2).to_i - cpu_info_1.at(2).to_i
cpu_system = cpu_info_2.at(3).to_i - cpu_info_1.at(3).to_i
cpu_idle   = cpu_info_2.at(4).to_i - cpu_info_1.at(4).to_i

cpu_total  = cpu_user + cpu_nice + cpu_system + cpu_idle

puts cpu_total.to_s

puts cpu_user.to_s
puts cpu_nice.to_s
puts cpu_system.to_s
puts cpu_idle.to_s
