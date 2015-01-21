#!/usr/bin/env ruby

# @file         check_mem_by_ssh.rb
# @author       Wollmann, Tobias <t.wollmann@bull.de>
# @date         01/21/2014
# @version      0.2
# @param H      Hostname or ip address of the remot host.
# @param u      Username that will be used torun the command on the remote host.
# @param w      Optional parameter to set the warning threshold in percentage.
#               Default value is 90.
# @param c      Optional parameter to set the critical threshold in percentage.
#               Default value is 95.

# Required libraries
require 'net/ssh'
require 'optparse'
require 'English'

# Methode to open keyfile-based SSH connection
def open_ssh_connection(hostname, username, keyfile, password)
  if keyfile != ''
    return Net::SSH.start(hostname, username, keys: keyfile)
  else
    return Net::SSH.start(hostname, username, password: password)
  end
rescue
  print "Failed to connect via ssh: #{$ERROR_INFO}\n"
  exit 3
end

# Method to print the utilization
def print_utilization(exitcode, perf_curr, pct_free)
  case exitcode
  when 0
    print "Memory OK - free memory: #{perf_curr}MB (#{pct_free}%);"
  when 1
    print "Memory WARNING - free memory: #{perf_curr}MB (#{pct_free}%);"
  when 2
    print "Memory CRITICAL - free memory: #{perf_curr}MB (#{pct_free}%);"
  when 3
    print "Memory UNKNOWN\n"
  end
end

# Method to print the performance data
def print_perf_data(perf_curr, warning, critical, perf_min, perf_max)
  print "\\| Memory usage=#{perf_curr}MB;"
  print "#{warning};"
  print "#{critical};"
  print "#{perf_min};"
  print "#{perf_max}\n"
end

# Method to generate the error code
def generate_error_code(pct_free, warning, critical)
  if pct_free < 0 || pct_free > 100
    return 3
  elsif pct_free < warning
    return 0
  elsif pct_free < critical
    return 1
  else
    return 2
  end
end

# Main

# Declaration of command line parameters.
options = {
  hostname: '',
  username: '',
  keyfile:  '',
  password: '',
  warn:     90,
  crit:     95
}

# Declaration of command line help.
usage = {
  host:     'Hostname or ip address of the remote host.',
  user:     'Username of the monitoring user on the remote host.',
  keyfile:  'Specifie location of the pricate key for the ssh connection',
  password: 'Specifie password for the ssh connection',
  warning:  'Specifies the warning threshold.',
  critical: 'Specifies the critical threshold.'
}

# Parse cli parameters
OptionParser.new do |opts|
  opts.banner = 'Nagios plugin to gather cpu utilization of a remote host.'
  opts.on('-H', '--host host', usage[:host]) do |host|
    options[:hostname] = host
  end
  opts.on('-u', '--user user', usage[:user]) do |user|
    options[:username] = user
  end
  opts.on('-k', '--keyfile keyfile', usage[:keyfile]) do |key|
    options[:keyfile] =  key
  end
  opts.on('-p', '--password password', usage[:password]) do |pass|
    options[:password] =  pass
  end
  opts.on('-w', '--warning warning', usage[:warning]) do |warn|
    options[:warn] =  warn.to_f
  end
  opts.on('-c', '--critical critical', usage[:critical]) do |crit|
    options[:crit] =  crit.to_f
  end
end.parse!

# Verifies the given parameters
if options[:hostname] == '' || options[:username] == ''
  if options[:hostname] == ''
    puts 'The hostname is a neccessary parameter.'
  else
    puts 'The username is a neccessary parameter.'
  end
  exit 3
else
  # Get information about the cpu usage
  if options[:password] == '' && options[:keyfile] == ''
    puts 'You must either specifie a keyfile or a password'
    exit 3
  else
    ssh = open_ssh_connection(
      options[:hostname],
      options[:username],
      options[:keyfile],
      options[:password]
    )
  end

  # Get memory information
  memtotal = ssh.exec!("cat /proc/meminfo|grep -i '^memtotal'").split.at(1).to_i
  memfree  = ssh.exec!("cat /proc/meminfo|grep -i '^memfree'").split.at(1).to_i
  buffers  = ssh.exec!("cat /proc/meminfo|grep -i '^buffers'").split.at(1).to_i
  cached   = ssh.exec!("cat /proc/meminfo|grep -i '^cached'").split.at(1).to_i
  ssh.close

  perf_curr = (memtotal - memfree - buffers - cached) / 1024
  perf_warn = (memtotal / 100 * options[:warn]) / 1024
  perf_crit = (memtotal / 100 * options[:crit]) / 1024
  perf_min  = 0
  perf_max  = memtotal / 1024

  pct_free = (100.to_f / memtotal * memfree).round(1)
  pct_used = (100.to_f - pct_free).round(1)

  errorcode = generate_error_code(pct_used, options[:warn], options[:crit])
  print_utilization(errorcode, perf_curr, pct_free)
  print_perf_data(perf_curr, perf_warn, perf_crit, perf_min, perf_max)
  exit errorcode
end
