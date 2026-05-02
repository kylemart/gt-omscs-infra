FROM mstephenson6/cs6340-fall21-labs:latest

# Base image's default user is `cs6340` (non-root); apt and sshd setup need root.
USER root

# openssh-server: base image ships without an SSH daemon; CLion's remote
#   toolchain needs one.
# rsync: CLion uses it to mirror sources into the remote build dir.
RUN apt-get update && apt-get install -y openssh-server rsync && rm -rf /var/lib/apt/lists/*

# sshd needs this dir to exist at start; the package postinst usually creates
# it but /run is tmpfs and gets wiped between layers.
RUN mkdir -p /var/run/sshd

# sshd config tweaks:
# - Point AuthorizedKeysFile at a fixed path we can bind-mount.
# - Disable StrictModes so sshd doesn't reject the bind-mounted keyfile based
#   on its host-side ownership (UID won't match container's root).
RUN sed -i \
    -e 's|^#*AuthorizedKeysFile.*|AuthorizedKeysFile /etc/ssh/authorized_keys|' \
    -e 's|^#*StrictModes.*|StrictModes no|' \
    /etc/ssh/sshd_config

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
