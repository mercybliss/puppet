#!/usr/bin/env ruby

require 'open3'

def run_command(command)
  puts "Executing: #{command}"
  stdout, stderr, status = Open3.capture3(command)
  if status.success?
    puts stdout
  else
    puts "Error executing command: #{command}"
    puts stderr
    exit 1
  end
end

# Check if running as root
if Process.uid != 0
  puts "This script must be run as root!"
  exit 1
end

# Check if the OS is RHEL 8
os_release_file = '/etc/os-release'
unless File.exist?(os_release_file) && File.read(os_release_file).include?('Red Hat Enterprise Linux release 8')
  puts "This script is designed to work on RHEL 8 only!"
  exit 1
end

# Enable the required repositories
run_command('subscription-manager repos --enable=rhel-8-for-x86_64-appstream-rpms')
run_command('subscription-manager repos --enable=rhel-8-for-x86_64-baseos-rpms')

# Update the system
run_command('dnf update -y')

# Install Apache
run_command('dnf install -y httpd')

# Enable and start the Apache service
run_command('systemctl enable --now httpd')

puts "Apache successfully installed and started on RHEL 8!"
