FROM hexpm/elixir:1.16-erlang-26.2.5.16-ubuntu-noble-20251013

VOLUME /usr/src/smppex

WORKDIR  /usr/src/smppex

RUN apt update && apt install -y vim inotify-tools
RUN apt install -y build-essential curl iputils-ping libcurl4-openssl-dev libssl-dev
RUN apt install -y libpcre3-dev ca-certificates gnupg

CMD ["bash"]