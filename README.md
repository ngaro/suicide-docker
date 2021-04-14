# Suicide Docker

This image is **not** meant to help you. It's purpose is to be **dangerous** and **break your system**.

# Important warning:
_Only use this if you are **absolutely sure** what you are doing !<br>
If you do decice to use this, remember that things **will** break and that **YOU are the only one responsible** for this.<br>
**I will NOT take any responsiblity at all** !_

This repository uses the GPLv3 license which clearly mentions:<br> _"This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE."_<br>
See the file `LICENSE` for details.

# What this is:
Most programs I added in this image are meant to break:
* The container itself
* Other running containers
* The hostsystem
* The networkconnection
* Everything connected to the hostsystem 

The idea behind this is is to test your skills in managing containers in a safe way.<br>
You can use these programs to do so damage and try to find mothods to work around the resulting problems.<br>
If you manage this then you should be able to find a way around similar programs in your real containers.<br>

Another use might be to use this as base image to create a image with some software of which you want to test the resilience.

#Building the image
* If you have Perl and the modules `Getopt::Long` and `File::Temp`: Use `./buildimage.pl` ( See `./buildimage.pl --help` if you want to tweak the buildprocedure )
* Otherwise, tune `Dockerfile` manually and run `docker build` with your favorite options
