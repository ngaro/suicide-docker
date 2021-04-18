# Suicide Docker
# Copyright (C) 2021  Nikolas Garofil
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

FROM alpine
RUN apk update && apk add gcc e2fsprogs perl vim musl-dev nmap stress-ng make linux-headers libpcap-dev openssl-dev libnetfilter_queue-dev && cd /root && wget https://github.com/ngaro/thc-ipv6/archive/refs/heads/dev.zip && unzip dev.zip && rm dev.zip && cd thc-ipv6-dev && make && make install
WORKDIR /root
ADD forkbomb.c .
RUN gcc -O3 -Wall -Wextra -pedantic forkbomb.c -o forkbomb
