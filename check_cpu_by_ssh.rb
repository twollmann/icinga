#!/usr/bin/env ruby
#
# @file         check_cpu_by_ssh.rb
# @author       Wollmann, Tobias <t.wollmann@bull.de>
# @date         01/19/2014
# @version      0.2
#

require 'net/ssh'
require 'optparse'

# Method to generate the performance data and exit the script
def printPerfData (utilization, warning, critical, type)
  # 
  if utilization < warning && utilization < critical
    print "CPU OK - #{type} utilization: #{utilization.round(2)}\n"
    exit 0
  elsif utilization >= warning && utilization < critical
    print "CPU WARNING - #{type} utilization: #{utilization.round(2)}\n"
    exit 1
  elsif utilization > warning && utilization >= critical
    print "CPU CRITICAL - #{type} utilization: #{utilization.round(2)}\n"
    exit 2
  else
    print "CPU UNKNOWN\n"
    exit 3
  end
end

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
    options[:delay] =  delay.to_i
  end
  opts.on("-m", "--mode mode", "Specifies the monitoring mode.") do |mode|
    options[:mode] =  mode.to_i
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
delay      = options[:delay]
mode       = options[:mode]
warning    = options[:warning]
critical   = options[:critical]

# Verifies the given parameters
if hostname == nil
  puts "The hostname is a neccessary parameter."
  exit 3
elsif username == nil
  puts "The username is a neccessary parameter."
  exit 3
elsif delay == nil
  delay = 2
elsif mode == nil
  mode = 0
end

# Get information about the cpu usage
begin
  connection = Net::SSH.start(hostname, username)
  cpu_info_1 = connection.exec!("cat /proc/stat | grep -i '^cpu  '").split
  sleep(delay)
  cpu_info_2 = connection.exec!("cat /proc/stat | grep -i '^cpu  '").split
rescue
  print "CPU UNKNOWN - #{$!}\n"
  exit 3
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
cpu_time   = cpu_user + cpu_nice + cpu_system + cpu_idle

# Generate performance data output regarding the selected monitoring mode.
if mode == 0
  # Total CPU utilization
  perf_total = (100.to_f / cpu_time.to_f) * (cpu_user + cpu_nice + cpu_system)
  printPerfData(perf_total, warning, critical, "Total")
elsif mode == 1
  # Cpu utilization of user processes
  perf_user   = (100.to_f / cpu_time.to_f) * cpu_user.to_f
  printPerfData(perf_user, warning, critical, "User")
elsif mode == 2
  # CPU utilization of nice processes
  perf_nice   = (100.to_f / cpu_time.to_f) * cpu_nice.to_f
  printPerfData(perf_nice, warning, critical, "Nice")
elsif mode == 3
  # CPU utilization of system processes
  perf_system = (100.to_f / cpu_time.to_f) * cpu_system.to_f
  printPerfData(perf_system, warning, critical, "System")
end
