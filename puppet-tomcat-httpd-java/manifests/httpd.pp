class puppet-tomcat-httpd-java::httpd {
  package { 'httpd':
    ensure => installed,
    name   => 'httpd',
  }

  service { 'httpd':
    ensure    => running,
    enable    => true,
    subscribe => Package['httpd'],
  }
}
