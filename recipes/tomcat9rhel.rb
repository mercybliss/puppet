#!/usr/bin/env ruby

require 'open3'

def run_command(command)
  stdout, stderr, status = Open3.capture3(command)

  if status.success?
    puts "#{command} executed successfully."
    puts stdout
  else
    puts "Error executing #{command}."
    puts stderr
    exit 1
  end
end

puts "Installing Tomcat 9 on RHEL 8..."

# Install necessary packages
puts "Installing necessary packages..."
run_command('sudo yum -y install wget java-11-openjdk-devel')

# Download Tomcat
puts "Downloading Tomcat 9..."
run_command('wget https://downloads.apache.org/tomcat/tomcat-9/v9.0.54/bin/apache-tomcat-9.0.54.tar.gz -P /tmp')

# Extract Tomcat
puts "Extracting Tomcat 9..."
run_command('sudo tar xf /tmp/apache-tomcat-9.0.54.tar.gz -C /opt')
run_command('sudo mv /opt/apache-tomcat-9.0.54 /opt/tomcat')

# Create a system user for Tomcat
puts "Creating a system user for Tomcat..."
run_command('sudo useradd -r -m -U -d /opt/tomcat -s /bin/false tomcat')

# Change ownership and permissions
puts "Changing ownership and permissions for Tomcat..."
run_command('sudo chown -R tomcat: /opt/tomcat')
run_command('sudo sh -c "chmod +x /opt/tomcat/bin/*.sh"')

# Create a systemd service file for Tomcat
puts "Creating a systemd service file for Tomcat..."
service_file = <<-EOF
[Unit]
Description=Apache Tomcat 9
After=network.target

[Service]
User=tomcat
Group=tomcat
Type=forking
Environment=JAVA_HOME=/usr/lib/jvm/java-11-openjdk
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat
Environment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC'
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

[Install]
WantedBy=multi-user.target
EOF

File.write("/tmp/tomcat.service", service_file)
run_command("sudo mv /tmp/tomcat.service /etc/systemd/system/tomcat.service")

# Enable and start Tomcat
puts "Enabling and starting Tomcat service..."
run_command("sudo systemctl daemon-reload")
run_command("sudo systemctl enable tomcat")
run_command("sudo systemctl start tomcat")

puts "Tomcat 9 installation completed."
