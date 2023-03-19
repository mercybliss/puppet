#!/usr/bin/env ruby

# Check if the script is running as root
if Process.uid != 0
  puts "Please run this script as root or with sudo."
  exit 1
end

# Update the system
puts "Updating the system..."
`dnf update -y`

# Install OpenJDK 11
puts "Installing OpenJDK 11..."
`dnf install -y java-11-openjdk`

# Verify the installation
java_version_output = `java -version 2>&1`
puts "Java version output: #{java_version_output}"

if java_version_output.include?("11.")
  puts "OpenJDK 11 installation completed successfully."
else
  puts "An error occurred during OpenJDK 11 installation."
end
