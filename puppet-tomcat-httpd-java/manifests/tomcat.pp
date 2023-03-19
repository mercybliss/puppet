class puppet-tomcat-httpd-java::tomcat {
  package { 'tomcat':
    ensure => installed,
    name   => 'tomcat',
  }

  service { 'tomcat':
    ensure    => running,
    enable    => true,
    subscribe => Package['tomcat'],
  }
}
