

log "...::: opsworks::apache2 :::..."

 #set data bag variables
app = search("aws_opsworks_app", "shortname:webapp").first
node.default['deploy']['webapp']['environment']['site_address'] = "#{app['environment']['site_address']}"
node.default['deploy']['webapp']['environment']['ssl_certificate'] = "#{app['ssl_configuration']['certificate']}"
node.default['deploy']['webapp']['ssl_certificate_ca'] = "#{app['ssl_configuration']['chain']}"
node.default['deploy']['webapp']['ssl_certificate']= "#{app['ssl_configuration']['certificate']}"
node.default['deploy']['webapp']['ssl_certificate_key'] = "#{app['ssl_configuration']['private_key']}"

instance = search("aws_opsworks_instance").first
#node.default['hostname'] = "#{instance['hostname']}"

# Install Apache2
package 'apache2'

# Install php
#include_recipe "opsworks::php72-install"

#- Configure Apache timeout
#- Install modules, extra utils
%w(aspell-en sendmail zip unzip curl).each do |pkg|
    package pkg do
        action :install
    end
end

# Enable the rewrite mod
execute 'a2enmod rewrite' do
    not_if 'a2query -m rewrite'
    notifies :reload, 'service[apache2]', :delayed
end

#- Setup the virtual host details including Tomcat ProxyPass directives if appropriate
template "#{node['apache']['conf']}/#{node['apache']['sites-avail']}/apache-default.conf" do
    source "apache-default.conf.erb"
    owner 'root'
    group 'root'
    mode '0644'
    variables ({
        ssl_support: node['deploy']['webapp']['ssl_support'],
        lbr_ssl_enabled: node['lbr']['ssl']['enabled'],
        site_address: node['deploy']['webapp']['environment']['site_address'],
        apache_doc_root: node['apache']['doc-root']
    })
    notifies :reload, 'service[apache2]', :delayed
end

#log "....:::: SSL Support: #{node['deploy']['webapp']['ssl_support']} ::::...."
#log "....:::: lbr_ssl_enabled: #{node['lbr']['ssl']['enabled']} ::::...."
#log "....:::: site_address: #{app['environment']['site_address']} ::::...."
#log "....:::: apache_doc_root: #{node['apache']['doc-root']} ::::...."


#- Configure keepalive.html for LBR Check
template "#{node['apache']['doc-root']}/keepalive.html" do
    source "keepalive.html.erb"
    mode '0644'
    notifies :reload, 'service[apache2]', :delayed
end

# Enable our virtual host
execute 'a2ensite apache-default.conf' do
    not_if 'a2query -s apache-default'
    action :run
    notifies :reload, 'service[apache2]', :delayed
end

# Disable the default
execute 'a2dissite 000-default.conf' do
    action :run
end

# Setup SSL Mod for either LBR terminated or locally terminated
if node['deploy']['webapp']['ssl_support'] == true or node['lbr']['ssl']['enabled'] == true

    # Enable the ssl mod
    execute 'a2enmod ssl' do
        not_if 'a2query -m ssl'
        notifies :reload, 'service[apache2]', :delayed
    end
end

# Check for SSL enabled and then act accordingly
if node['deploy']['webapp']['ssl_support'] == true
    # Upload the certificate based
    if node['deploy']['webapp']['environment']['ssl_certificate'] != ""
            bash 'Save SSL PEMs' do
                user "root"
                code <<-EOH
                echo -e "#{node['deploy']['webapp']['ssl_certificate']}" > /etc/ssl/certs/#{node['deploy']['webapp']['environment']['site_address']}-crt.pem;
                echo -e "#{node['deploy']['webapp']['ssl_certificate_key']}" > /etc/ssl/private/#{node['deploy']['webapp']['environment']['site_address']}-key.pem;
                EOH
                not_if {  ::File.exists?("/etc/ssl/certs/#{node['deploy']['webapp']['environment']['site_address']}-crt.pem") || ::File.exists?("/etc/ssl/certs/#{node['deploy']['webapp']['environment']['site_address']}-key.pem") }
            end
            if defined? node['deploy']['webapp']['ssl_certificate_ca'] && node['deploy']['webapp']['ssl_certificate_ca'] !=""
                execute 'set ssl_chain' do
                    command "echo \"#{node['deploy']['webapp']['ssl_certificate_ca']}\" > /etc/ssl/certs/#{node['deploy']['webapp']['environment']['site_address']}-chain.pem";
                    not_if {  ::File.exists?("/etc/ssl/certs/#{node['deploy']['webapp']['environment']['site_address']}-chain.pem") }
                end
            end

                #- Disable SSLv3
        ruby_block "Apache2 configurations - SSL" do
            block do
                node.set['regex-protocol'] = "       SSLProtocol all"
                node.set['regex-cipher'] = "        SSLCipherSuite HIGH:MEDIUM:!aNULL:!MD5"
                node.set['regex-cipher-order'] = "        #SSLHonorCipherOrder on"
                fe = Chef::Util::FileEdit.new("/etc/apache2/mods-enabled/ssl.conf")
                fe.search_file_replace(/#{node.set['regex-protocol']}/, "       SSLProtocol All -SSLv2 -SSLv3")
                fe.search_file_replace(/#{node.set['regex-cipher']}/, "        SSLCipherSuite HIGH:!aNULL:!MD5:!RC4")
                fe.search_file_replace(/#{node.set['regex-cipher-order']}/, "        SSLHonorCipherOrder on")
                fe.write_file
            end
        end

        template "#{node['apache']['conf']}/#{node['apache']['sites-avail']}/apache-ssl.conf" do
            source 'apache-ssl.conf.erb'
            mode '0644'
            owner 'root'
            group 'root'
            notifies :reload, 'service[apache2]', :delayed
            variables ({
                ssl_support: node['deploy']['webapp']['ssl_support'],
                lbr_ssl_enabled: node['lbr']['ssl']['enabled'],
                site_address: node['deploy']['webapp']['environment']['site_address'],
                apache_doc_root: node['apache']['doc-root']
            })
        end

        # Disable the default
        execute 'a2dissite default-ssl.conf' do
            action :run
        end

        # Enable our SSL config
        execute 'a2ensite apache-ssl.conf' do
            not_if 'a2query -s apache-ssl'
            notifies :reload, 'service[apache2]', :delayed
        end
    end
end

# Restart apache2 to enable these settings
service 'apache2' do
    action :restart
end
