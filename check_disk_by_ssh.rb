#!/usr/bin/env ruby
#
# @file         check_disk_by_ssh.rb
# @author       Wollmann, Tobias <t.wollmann@bull.de>
# @date         18/08/2014
# @version      0.3
#

require 'net/ssh'
require 'optparse'

#
# Main
#

# Initialize command line parameter hash and set defaults
options = {:hostname=>nil, :username=>nil, :filesystem=>nil, :warning=>90, :critical=>95}
optparse = OptionParser.new do |opts|
  opts.banner = "Nagios plugin to gather filesystem information of a remote host."
  opts.on("-H", "--hostname hostname", "Hostname or IP-address of the remote system.") do |host|
    options[:hostname] = host
  end
  opts.on("-u", "--username username", "Username of the monitoring account on the Server.") do |user|
    options[:username] = user
  end
  opts.on("-f", "--filesystem filesystem", "Filesystem on the remote system.") do |fs|
    options[:filesystem] =  fs
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
filesystem = options[:filesystem]
warning    = options[:warning]
critical   = options[:critical]

if hostname == nil
  puts "The hostname is a neccessary parameter."
  exit 3
elsif username == nil
  puts "The username is a neccessary parameter."
  exit 3
elsif filesystem == nil
  puts "The filesystem is a neccessary parameter."
  exit 3
end

# Get filesystem information of the remote host
fs_info = Net::SSH.start(hostname, username) do |ssh|
  ssh.exec!("stat -f -c '%s %b %f %c %d' " + filesystem).split
end

# Get the filesystem information and store it to variables
block_size   = fs_info.at(0).to_f
blocks_total = fs_info.at(1).to_f
blocks_free  = fs_info.at(2).to_f
inodes_total = fs_info.at(3).to_f
inodes_free  = fs_info.at(4).to_f

space_total = blocks_total * block_size / (1024 * 1024)
space_free  = blocks_free * block_size / (1024 * 1024)

# Calculate performance data for disk space
p_curr = space_total - space_free
p_warn = (space_total / 100) * warning.to_i
p_crit = (space_total / 100) * critical.to_i
p_min  = 0
p_max  = space_total

# Calculate performance data for inodes
i_curr = inodes_total - inodes_free
i_warn = (inodes_total / 100) * warning.to_i
i_crit = (inodes_total / 100) * critical.to_i
i_min  = 0 
i_max  = inodes_total

# Calculate used disk space and inodes
space_used          = space_total - space_free
space_used_percent  = space_used.to_f / space_total.to_f * 100
inodes_used         = inodes_total - inodes_free
inodes_used_percent = (inodes_used.to_f / inodes_total.to_f) * 100

# Calculate the exitcode
if ((p_curr < p_warn) && (i_curr < i_warn))
  print "DISK OK"
  errorcode = 0
elsif ((p_curr >= p_warn && p_curr < p_crit) || (i_curr >= i_warn && i_curr < i_crit))
  print "DISK WARNING"
  errorcode = 1
elsif ((p_curr >= p_crit && p_curr <= p_max) || (i_curr >= i_crit && i_curr <= i_max))
  print "DISK CRITICAL"
  errorcode = 2
else
  print "DISK UNKNOWN"
  errorcode = 3
end

# Status information output: "/ - Diskspace used: 9.99GB (10.0%), Inodes used: 120000 (10.0%)"
print " - #{filesystem}"
print " Diskspace used: #{space_used.round(2)} MB (#{space_used_percent.round(1)}%),"
print " Inodes used: #{inodes_used.to_i} (#{inodes_used_percent.round(1)}%);"
print "\| "

# Performance data output: "'Space /'=9.99GB;90;95;'Inodes /'=120000;90;95
# Performance data diskspace
print "'Space #{filesystem}'="
print p_curr.round(2).to_s + "MB;"
print p_warn.round(0).to_s + ";"
print p_crit.round(0).to_s + ";"
print p_min.round(0).to_s + ";"
print p_max.round(0).to_s + ";"
# Performance data inodes
print "'Inodes #{filesystem}'="
print i_curr.round(0).to_s + ";"
print i_warn.round(0).to_s + ";"
print i_crit.round(0).to_s + ";"
print i_min.round(0).to_s + ";"
print i_max.round(0).to_s + ";\n"
exit errorcode
