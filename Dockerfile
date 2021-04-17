FROM ubuntu:20.04
RUN apt-get update && apt-get -y install automake build-essential vim-tiny && ln -s /etc/alternatives/vi /usr/bin/vim
WORKDIR /root
ADD forkbomb.c .
RUN gcc -O3 -Wall -Wextra -pedantic forkbomb.c -o forkbomb
