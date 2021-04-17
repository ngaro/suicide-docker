FROM alpine
RUN apk update && apk add autoconf automake gcc e2fsprogs perl vim musl-dev
WORKDIR /root
ADD forkbomb.c .
RUN gcc -O3 -Wall -Wextra -pedantic forkbomb.c -o forkbomb
