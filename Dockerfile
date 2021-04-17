FROM centos
RUN yum install -y automake gcc vim e2fsprogs
WORKDIR /root
ADD forkbomb.c .
RUN gcc -O3 -Wall -Wextra -pedantic forkbomb.c -o forkbomb
