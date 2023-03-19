# Puppet-Tomcat-HTTPD-Java

This repository contains Puppet configurations to automate the installation of Tomcat9, httpd, and Java 11 on RHEL OS 8.

## Usage

1. Install Puppet on the target RHEL OS 8 system.
2. Clone this repository to the `/etc/puppet/code/environments/production/modules` directory.
3. Include the `puppet-tomcat-httpd-java` class in your main manifest file, typically located at `/etc/puppet/code/environments/production/manifests/site.pp`.

