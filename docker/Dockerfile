FROM node:lts
 
# Build-time arguments
ARG DOCKER_GID
ARG UID_0
ARG UID_1
ARG UID_2
 
SHELL ["/bin/bash", "-c"]
 
# Tooling
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      lftp \
      rsync \
      ca-certificates \
      sshpass \
      mdbtools \
      expect \
      gosu \
 && rm -rf /var/lib/apt/lists/*
 
# lftp: auto-accept host keys AND use legacy ssh algorithms for old GE hhm
RUN printf '%s\n' \
  'set sftp:auto-confirm yes' \
  'set sftp:connect-program "ssh -a -x -oKexAlgorithms=+diffie-hellman-group1-sha1 -oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedAlgorithms=+ssh-rsa"' \
  > /etc/lftp.conf
 
# Create docker group
RUN groupadd -g ${DOCKER_GID} docker
 
# Create users
RUN useradd -u ${UID_0} -g docker -m -d /home/svc -s /bin/bash svc
RUN useradd -u ${UID_1} -g docker -m -d /home/jonathan-pope -s /bin/bash jonathan-pope
RUN useradd -u ${UID_2} -g docker -m -d /home/matt-teixeira -s /bin/bash matt-teixeira
 
# ----------------------------------------------------------
# TO ADD ANOTHER USER:
# 1) Add ARG UID_X at the top
# 2) Add: RUN useradd -u ${UID_X} -g docker -m -d /home/newuser -s /bin/bash newuser
# 3) Pass --build-arg UID_X=$(id -u newuser) in build command
# ----------------------------------------------------------
 
# Cooperative umask for all shells
RUN printf 'umask ${UMASK:-0002}\n' > /etc/profile.d/umask.sh \
  && chmod 644 /etc/profile.d/umask.sh \
  && printf '\n# cooperative umask for all users\numask ${UMASK:-0002}\n' >> /etc/bash.bashrc
 
ENV BASH_ENV=/etc/profile.d/umask.sh

# Baked-in entrypoint (replaces the host-mounted /opt/resources/entrypoint.sh).
# Keeps the same RUN_USER + gosu-drop semantics, but no longer depends on
# /opt/resources being bind-mounted into the container.
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 0755 /usr/local/bin/entrypoint.sh

WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]