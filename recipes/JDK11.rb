# Cookbook Name:: opsworks
# Recipe:: jdk-install
# Notes:: For use strictly as a stop-gap with Oracle JDK on Ubuntu for when Oracle messes with the ability of the
#         java::oracle cookbook to function
#

log "...::: opsworks::openJDK 11-install :::..."

package 'software-properties-common'

#apt_update 'update packages' do
#   action :update
#end

package 'openjdk-11-jre-headless' do
action :install
not_if "test \`java -version | grep \"javac\" -c\` -eq 1"
end
