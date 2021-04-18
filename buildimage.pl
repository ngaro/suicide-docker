#!/usr/bin/perl
# Forkbomb
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
use strict;
use warnings;

use Getopt::Long;
use File::Temp qw/tempfile/;

my $base = "ubuntu:20.04";
my $cleanup = undef;
my $file = undef;
my $help = undef;
my $imagename = undef;
my $tag;
my $nobuild = undef;
my $nowrite = undef;
my $options = "";
my $verbose = undef;
my $writeall = undef;
my $push = undef;

sub todockerfile {
	my ($fh, $line) = @_;
	print $fh "$line\n";
	print STDERR "$line\n" if(defined $verbose);
}

GetOptions( "base=s" => \$base, "cleanup" => \$cleanup, "file=s" => \$file, "help" => \$help, "imagename=s" => \$imagename, "nobuild" => \$nobuild, "nowrite"=> \$nowrite, "options=s" => \$options, "verbose" => \$verbose, "writeall" => \$writeall, "push" => \$push);

if(defined $writeall) {
	my $originalbranch = `git branch --show-current`;
	my $branches = {
		"alpine" => "alpine",
		"arch" => "archlinux",
		"centos" => "centos",
		"debian" => "debian:stable",
		"dev" => "ubuntu:20.04",
		"fedora" => "fedora:33",
		"master" => "ubuntu:20.04",
	};
	foreach(keys %$branches) {
		my $newdockerfilecmd = "git checkout $_ && ./buildimage.pl -b $branches->{$_} -f Dockerfile --nobuild -v && git commit -a -m \"Updated Dockerfile\" ; echo Not pushing && git checkout $originalbranch";
		if(defined $push) { $newdockerfilecmd=~s/echo Not pushing/git push && git push github/ ; }
		system($newdockerfilecmd);
	}
	exit;
}
if(defined $help) {
	print << 'ENDOFHELP';
Creates a dockerfile in /tmp and use this to build suicide-docker

Usage: buildimage.pl [Options]

Options:
-b | --base=image	Use base image to build. Default is "ubuntu:20.04", other supported images: debian, alpine, fedora, centos, arch (with any tag).
			Images based upon these images usually also work, others usually don't work.
-c | --cleanup		Remove the Dockerfile when done.
-f | --file=path	Use 'path' for the dockerfile, by default it's written to /tmp with a random suffix
-h | --help		Show this help and exit
-i | --imagename=name	Name for the image, default is "suicide" with the baseimage as tag (with ':' replaced by '-')
--nobuild		Create the dockerfile but don't build the image
--nowrite		Skip writing a new dockerfile, use 'Dockerfile' in the current directory or given with -f to build
-o | --options=s	Provide extra options to 'docker build'
-v | --verbose		Send info about what is happening to STDERR
-w | --write-all	Create new dockerfiles in all branches
-p | --push		Push the new commits to github and gitlab when using -w

ENDOFHELP
	exit;
}

unless(defined $nowrite) {
	my $fh;
	if(defined $file) {
		open($fh, ">$file") or die "Can't write to $file";
	} else {
		my $template = "Dockerfile.XXXX";
		($fh, $file) = tempfile($template, TMPDIR=>1) or die "Can't create $file";
	}
	print STDERR "Writing to: $file\n\n" if(defined $verbose);
	my $gpl=<<END;
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
END
	todockerfile($fh, $gpl);
	todockerfile($fh, "FROM $base");
	if($base=~/debian/i or $base=~/ubuntu/i) { todockerfile($fh, 'RUN apt-get update && apt-get -y install build-essential vim-tiny nmap thc-ipv6 stress-ng && ln -s /etc/alternatives/vi /usr/bin/vim'); }
	if($base=~/alpine/i) { todockerfile($fh, 'RUN apk update && apk add gcc e2fsprogs perl vim musl-dev nmap stress-ng make linux-headers libpcap-dev openssl-dev libnetfilter_queue-dev && cd /root && wget https://github.com/ngaro/thc-ipv6/archive/refs/heads/dev.zip && unzip dev.zip && rm dev.zip && cd thc-ipv6-dev && make && make install'); }
	if($base=~/centos/i or $base=~/fedora/i) { todockerfile($fh, 'RUN yum install -y gcc libnetfilter_queue-devel openssl-devel libpcap-devel make vim e2fsprogs nmap unzip libaio-devel libattr-devel libbsd-devel libgcrypt-devel Judy-devel keyutils-libs-devel lksctp-tools-devel libatomic-static zlib-devel glibc-static && cd /root && curl -L -o dev.zip https://github.com/ngaro/thc-ipv6/archive/refs/heads/dev.zip && unzip dev.zip && rm dev.zip && cd /root/thc-ipv6-dev && make && make install && cd /root && curl -L -o master.zip https://github.com/ColinIanKing/stress-ng/archive/refs/heads/master.zip && unzip master.zip && rm master.zip && cd /root/stress-ng-master && make && make install');}
	if($base=~/arch/i) { todockerfile($fh,"RUN pacman --noconfirm -Sy make gcc vim perl nmap unzip libnetfilter_queue && cd /root && curl -L -o dev.zip https://github.com/ngaro/thc-ipv6/archive/refs/heads/dev.zip && unzip dev.zip && rm dev.zip && cd /root/thc-ipv6-dev && make && make install && cd /root && curl -L -o master.zip https://github.com/ColinIanKing/stress-ng/archive/refs/heads/master.zip && unzip master.zip && rm master.zip && cd /root/stress-ng-master && PEDANTIC=1 make && make install");}
	todockerfile($fh, "WORKDIR /root");
	todockerfile($fh, "ADD forkbomb.c .");
	todockerfile($fh, "RUN gcc -O3 -Wall -Wextra -pedantic forkbomb.c -o forkbomb");
	print STDERR "\nDone writing, closing $file\n" if(defined $verbose);
	close $fh;
	print "The generated Dockerfile is now available at: $file\n" if(defined $verbose);
}
unless(defined $nobuild) {
	$file="./Dockerfile" unless(defined $file);
	unless(defined $imagename) {
		$tag = $base; $tag=~s/:/-/g;
		$imagename="suicide:$tag";
	}
	my $buildcmd = "docker build -f $file -t $imagename $options .";
	print "Building with: $buildcmd\n" if(defined $verbose);
	die "Build failed" unless(system($buildcmd) == 0);
}
if(defined $cleanup) {
	unlink $file or die "Can't remove $file"; 
	print "The dockerfile at $file is now removed\n" if(defined $verbose);
}
