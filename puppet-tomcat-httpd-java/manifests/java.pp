class puppet-tomcat-httpd-java::java {
  package { 'java-11-openjdk':
    ensure => installed,
    name   => 'java-11-openjdk',
  }
}
