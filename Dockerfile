
FROM tomcat:11.0-jdk21-temurin

RUN rm -rf /usr/local/tomcat/webapps/*

COPY target/MyWebApp-0.0.1.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080
