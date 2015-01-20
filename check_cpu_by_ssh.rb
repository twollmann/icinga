#!/usr/bin/env ruby
#
# @file         check_cpu_by_ssh.rb
# @author       Wollmann, Tobias <t.wollmann@bull.de>
# @date         01/20/2014
# @version      0.5

# Required libraries
require 'net/ssh'
require 'optparse'
require 'English'

# Methode to open keyfile-based SSH connection
def open_ssh_key(hostname, username, keyfile)
  return Net::SSH.start(hostname, username, keys: keyfile)
rescue
  print "Failed to connect via ssh: #{$ERROR_INFO}\n"
  exit 3
end

def open_ssh_password(hostname, username, password)
  return Net::SSH.start(hostname, username, password: password)
rescue
  print "Failed to connect via ssh: #{$ERROR_INFO}\n"
  exit 3
end

# Method to print the utilization
def print_utilization(utilization, exitcode)
  case exitcode
  when 0
    print "CPU OK - Utilization: #{utilization.round(1)}%%;"
  when 1
    print "CPU WARNING - Utilization: #{utilization.round(1)}%%;"
  when 2
    print "CPU CRITICAL - Utilization: #{utilization.round(1)}%%;"
  when 3
    print "CPU UNKNOWN\n"
  end
end

# Method to print the performance data
def print_perf_data(type, utilization, warning, critical)
  print "\\| #{type} usage=#{utilization.round(1)}%%;"
  print "#{warning.round(1)};"
  print "#{critical.round(1)};"
  print '0.0;'
  print "100.0\n"
end

# Method to generate the error code
def generate_error_code(utilization, warning, critical)
  if utilization < 0 || utilization > 100
    return 3
  elsif utilization < warning
    return 0
  elsif utilization < critical
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
  period:   5,
  mode:     0,
  warn:     90,
  crit:     95
}

# Declaration of command line help.
usage = {
  host:     'Hostname or ip address of the remote host.',
  user:     'Username of the monitoring user on the remote host.',
  period:   'Time period to mesure the CPU utilization within',
  mode:     'Specifies the monitoring mode.',
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
  opts.on('-t', '--time-period period', usage[:period]) do |period|
    options[:period] =  period.to_i
  end
  opts.on('-m', '--mode mode', usage[:mode]) do |mode|
    options[:mode] =  mode.to_i
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
    if options[:keyfile] != ''
      connection = open_ssh_key(
        options[:hostname],
        options[:username],
        options[:keyfile]
      )
    else
      connection = open_ssh_password(
        options[:hostname],
        options[:username],
        '1188null'
      )
    end
    cpu_info_1 = connection.exec!("cat /proc/stat | grep -i '^cpu  '").split
    sleep(options[:period])
    cpu_info_2 = connection.exec!("cat /proc/stat | grep -i '^cpu  '").split
  end

  # Calculate the CPU utilization
  cpu_user   = cpu_info_2.at(1).to_i - cpu_info_1.at(1).to_i
  cpu_nice   = cpu_info_2.at(2).to_i - cpu_info_1.at(2).to_i
  cpu_system = cpu_info_2.at(3).to_i - cpu_info_1.at(3).to_i
  cpu_idle   = cpu_info_2.at(4).to_i - cpu_info_1.at(4).to_i
  cpu_time   = cpu_user + cpu_nice + cpu_system + cpu_idle

  # Generate performance data output regarding the selected monitoring mode.
  case options[:mode]
  when 0
    # Total CPU utilization
    perf_total = (100.to_f / cpu_time.to_f) * (cpu_user + cpu_nice + cpu_system)
    errorcode = generate_error_code(perf_total, options[:warn], options[:crit])
    print_utilization(perf_total, errorcode)
    print_perf_data('Total', perf_total, options[:warn], options[:crit])
  when 1
    # CPU utilization of user processes
    perf_user   = (100.to_f / cpu_time.to_f) * cpu_user.to_f
    errorcode = generate_error_code(perf_user, options[:warn], options[:crit])
    print_utilization(perf_user, errorcode)
    print_perf_data('User', perf_user, options[:warn], options[:crit])
  when 2
    # CPU utilization of nice processes
    perf_nice   = (100.to_f / cpu_time.to_f) * cpu_nice.to_f
    errorcode = generate_error_code(perf_nice, options[:warn], options[:crit])
    print_utilization(perf_nice, errorcode)
    print_perf_data('Nice', perf_nice, options[:warn], options[:crit])
  when 3
    # CPU utilization of system processes
    perf_system = (100.to_f / cpu_time.to_f) * cpu_system.to_f
    errorcode = generate_error_code(perf_system, options[:warn], options[:crit])
    print_utilization(perf_system, errorcode)
    print_perf_data('System', perf_system, options[:warn], options[:crit])
  end
  exit errorcode
end
