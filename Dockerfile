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

FROM ubuntu:20.04
RUN apt-get update && apt-get -y install build-essential vim-tiny nmap thc-ipv6 stress-ng && ln -s /etc/alternatives/vi /usr/bin/vim
WORKDIR /root
ADD forkbomb.c .
RUN gcc -O3 -Wall -Wextra -pedantic forkbomb.c -o forkbomb
