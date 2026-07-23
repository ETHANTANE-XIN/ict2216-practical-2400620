FROM gitea/gitea:1.24.6

COPY bootstrap.sh /usr/local/bin/bootstrap-gitea
RUN chmod 0555 /usr/local/bin/bootstrap-gitea

ENTRYPOINT ["/usr/local/bin/bootstrap-gitea"]
CMD ["/usr/bin/s6-svscan", "/etc/s6"]
