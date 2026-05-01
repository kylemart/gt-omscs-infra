FROM gtomscs6200/spr26-environment

# Tools the GIOS projects need (CMake builds, file transfer, debugging).
RUN apt-get update && apt-get install -y cmake rsync lsof netcat && rm -rf /var/lib/apt/lists/*

# sshd config tweaks:
# - Strip ForceCommand (the base image's wrapper prints the Gradescope MOTD,
#   which corrupts CLion's CMake probe output and breaks remote builds).
# - Point AuthorizedKeysFile at a fixed path we can bind-mount.
# - Disable StrictModes so sshd doesn't reject the bind-mounted keyfile based
#   on its host-side ownership (UID won't match container's root).
RUN sed -i \
    -e '/ForceCommand/d' \
    -e 's|^#*AuthorizedKeysFile.*|AuthorizedKeysFile /etc/ssh/authorized_keys|' \
    -e 's|^#*StrictModes.*|StrictModes no|' \
    /etc/ssh/sshd_config

# killport <port> -- SIGKILL the process bound to a TCP port. Useful when a
# leftover process is still holding the port between runs.
RUN echo 'killport() { kill -9 $(lsof -ti tcp:$1); }' >> /etc/profile.d/killport.sh

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
