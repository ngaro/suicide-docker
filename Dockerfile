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

FROM centos
RUN yum install -y gcc libnetfilter_queue-devel openssl-devel libpcap-devel make vim e2fsprogs nmap unzip libaio-devel libattr-devel libbsd-devel libgcrypt-devel Judy-devel keyutils-libs-devel lksctp-tools-devel libatomic-static zlib-devel glibc-static && cd /root && curl -L -o dev.zip https://github.com/ngaro/thc-ipv6/archive/refs/heads/dev.zip && unzip dev.zip && rm dev.zip && cd /root/thc-ipv6-dev && make && make install && cd /root && curl -L -o master.zip https://github.com/ColinIanKing/stress-ng/archive/refs/heads/master.zip && unzip master.zip && rm master.zip && cd /root/stress-ng-master && make && make install
WORKDIR /root
ADD forkbomb.c .
RUN gcc -O3 -Wall -Wextra -pedantic forkbomb.c -o forkbomb
