#!/usr/bin/perl
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

sub todockerfile {
	my ($fh, $line) = @_;
	print $fh "$line\n";
	print STDERR "$line\n" if(defined $verbose);
}

GetOptions( "base=s" => \$base, "cleanup" => \$cleanup, "file=s" => \$file, "help" => \$help, "imagename=s" => \$imagename, "nobuild" => \$nobuild, "nowrite"=> \$nowrite, "options=s" => \$options, "verbose" => \$verbose );

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
--nowrite		Skip writing a new dockerfile, use 'Dockerfile' in the current directory or given with --dockerfile to build
-o | --options=s	Provide extra options to 'docker build'
-v | --verbose		Send info about what is happening to STDERR

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
	todockerfile($fh, "FROM $base");
	if($base=~/debian/i or $base=~/ubuntu/i) { todockerfile($fh, 'RUN apt-get update && apt-get -y install automake build-essential vim-tiny && ln -s /etc/alternatives/vi /usr/bin/vim'); }
	if($base=~/alpine/i) { todockerfile($fh, 'RUN apk update && apk add autoconf automake gcc e2fsprogs perl vim'); }
	if($base=~/centos/i or $base=~/fedora/i) { todockerfile($fh, 'RUN yum install -y automake gcc vim e2fsprogs'); }
	if($base=~/arch/i) { todockerfile($fh,"RUN echo '' | pacman -Sy automake gcc vim perl"); }
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
