FROM jenkins/jenkins:lts

# Switch to root to install plugins
USER root

# Copy plugins list
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt

# Install plugins
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# Create directory for pipeline definitions
RUN mkdir -p /usr/share/jenkins/ref/jobs

# Create directory for SmartAgent and copy zip file
COPY appdsmartagent_64_linux_25.10.0.497.zip /var/jenkins_home/smartagent/appdsmartagent.zip

# Switch back to jenkins user
USER jenkins

# Expose ports
EXPOSE 8080 50000
