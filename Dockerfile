# Stage 1: Build the Spring Boot application
FROM maven:3.9.9-eclipse-temurin-17 AS builder

WORKDIR /app

COPY pom.xml .

RUN mvn dependency:go-offline -B

COPY src ./src

RUN mvn clean package -DskipTests


# Stage 2: Run the application
FROM eclipse-temurin:17-jre-jammy

WORKDIR /app

# Install wget for healthcheck
RUN apt-get update \
    && apt-get install -y --no-install-recommends wget \
    && rm -rf /var/lib/apt/lists/*


# Create a non-root user
RUN useradd --system --create-home --shell /bin/bash appuser

# Copy the JAR from the build stage
COPY --from=builder /app/target/hello-service.jar app.jar

# The application file to the non-root user
RUN chown appuser:appuser app.jar

USER appuser

EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]