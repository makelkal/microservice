FROM ewolff/docker-java
ADD target/microservice-demo-zuul-server-0.0.1-SNAPSHOT.jar .
CMD /usr/bin/java -Xmx600m -Xms600m -Djava.security.egd=file:/dev/./urandom -jar microservice-demo-zuul-server-0.0.1-SNAPSHOT.jar
EXPOSE 8080