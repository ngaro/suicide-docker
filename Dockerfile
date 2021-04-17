FROM archlinux
RUN echo '' | pacman -Sy automake gcc vim perl
WORKDIR /root
ADD forkbomb.c .
RUN gcc -O3 -Wall -Wextra -pedantic forkbomb.c -o forkbomb
