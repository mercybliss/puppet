class puppet-tomcat-httpd-java {
  include puppet-tomcat-httpd-java::java
  include puppet-tomcat-httpd-java::httpd
  include puppet-tomcat-httpd-java::tomcat
}
