#
# Build Phase
#
FROM openjdk:8-jdk-alpine as build
WORKDIR /workspace/app

COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .
COPY src src

# Run maven installation in multithread
RUN ./mvnw -T 1C install -DskipTests
RUN mkdir -p target/dependency && (cd target/dependency; jar -xf ../*.jar)

#
# Running phase
#
FROM openjdk:8-jre-alpine
ENV spring.jmx.enabled=false

# Group add so app will not run in root
RUN addgroup -S docker-user && adduser -S docker-user -G docker-user

VOLUME /tmp
ARG DEPENDENCY=/workspace/app/target/dependency
COPY --from=build ${DEPENDENCY}/BOOT-INF/lib /app/lib
COPY --from=build ${DEPENDENCY}/META-INF /app/META-INF
COPY --from=build ${DEPENDENCY}/BOOT-INF/classes /app

# Use user here so any packages requiring root privileges wont fail
USER docker-user

ENTRYPOINT ["java", "-cp", "app:app/lib/*", "-Xverify:none", "hello.Application"]
