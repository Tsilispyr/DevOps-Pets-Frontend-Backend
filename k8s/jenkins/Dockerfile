FROM jenkins/jenkins:lts
USER root
RUN apt-get update && apt-get install -y git docker.io ansible curl

# Grant Jenkins access to Docker socket
# Create a docker group with the same GID as the host's docker.sock
# and add the jenkins user to it.
RUN DOCKER_SOCKET_GID=$(stat -c '%g' /var/run/docker.sock) && \
    groupadd -g $DOCKER_SOCKET_GID docker || true && \
    usermod -aG docker jenkins

RUN git config --global --add safe.directory '*'
RUN curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && rm kubectl
USER jenkins
