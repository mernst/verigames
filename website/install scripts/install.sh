#!/bin/sh

#Two systems to log in to
#ec2-50-16-16-173.compute-1.amazonaws.com is the beta VM
#ec2-107-21-183-34.compute-1.amazonaws.com is the live site

#aaron can get you a name and password on them
#if you log in to the beta VM and change to the root, there is a script at ~/ssh.topcoder to auto login in to the live site,
#else you have to deal with the ppk stuff. Get a private key from aaron or craig.


#The game is not in the repositiory, as it's a large collection (too large, half of a release build could be tossed) of stuff, 
#mostly binary that will change every release. Upload by hand?

#to install the game, upload to /root/minisite3/public/game, and test at:
# https://trafficjam.verigames.com/game/PipeJam3.html

# If you change the path, update /root/minisite3/views/theme-3/homepage/PublicHomepage.jade, changing the link in the PLAY NOW button
#for the homepage, and somewhere else I haven't yet found for the other buttons

#navigate to the /root/minisite3 directory and create a repo directory
#cd /root/minisite3
#mkdir uwverigames

#run mercurial to get this file first, um, yeah, I guess if you are reading this, you already have it. :)
#but that comment stays, so it can be somewhere, along with this one, which doesn't need to be somewhere, but exists anyway.
#hg clone https://dada.cs.washington.edu/hgweb/verigames/ uwverigames
#or you could update:
#cd uwverigames
#hg pull -u https://dada.cs.washington.edu/hgweb/verigames/

#Question - any way to clone one file? or update one file? Probably, I just haven't figured it out yet...
#hg pull -u "https://dada.cs.washington.edu/hgweb/verigames/website/install scripts/install.sh"  ??
#my mistake to put a space in that path...

#The next comment is important, though...

#run this script!
#sh "uwverigames/PipeJam/website/install scripts/install.sh"

#well, maybe not. You probably knew that too.

#next we install ant, but it's already installed
# yum -y install ant
#and we probably don't need it, anyway...

#now we are getting somewhere!
#install php (Python's already installed)
yum -y install php
#check to  has php-fpm installed, so might need to do
#yum -y install php-fpm
#and start it? Doesn't hurt to do, even if it's already running
sudo /usr/sbin/php-fpm restart
#check to make sure port 9000 is being used (hopefully by php-fpm)
#  netstat -nap | grep LISTEN | grep 9000

#you will need to update the etc/nginx/conf.d/default.conf file to enable php by uncommenting the lines
# under the pass the PHP scripts to FastCGI
#and reload config files for nginx
#kill -HUP `cat /var/run/nginx.pid`
#OR restart nginx
#sudo /etc/init.d/nginx restart

#until we figure out why nginx doesn't like php, install Apache
#sudo yum install httpd mod_ssl
#and start it
#sudo /usr/sbin/apachectl start

#install java jdk
yum install java-1.7.0-openjdk-devel -y

#install dot
cp "uwverigames/website/install scripts/graphviz-rhel.repo" /etc/yum.repos.d/graphviz-rhel.repo
yum -y install 'graphviz*'

#compile java parts
cd uwverigames/ProxyServer
javac -cp lib/commons-codec-1.6.jar:lib/commons-logging-1.1.1.jar:lib/fluent-hc-4.2.3.jar:lib/httpclient-4.2.3.jar:lib/httpclient-cache-4.2.3.jar:lib/httpcore-4.2.2.jar:lib/httpcore-4.2.3.jar:lib/httpcore-ab-4.2.3.jar:lib/httpcore-nio-4.2.3.jar:lib/httpmime-4.2.3.jar:lib/mongo-2.10.1.jar src/*.java
cd src
jar  cfm ../ProxyServer.jar ../manifest.mf *.class
cd ..

#go back to the base dir 
cd ../..

#copy upload stuff to apache website location
cp -r uwverigames/website/* /var/www/html/
#if we get nginx working, this is the ticket:
#mkdir /var/www/html/upload
#cp -r uwverigames/website/* /root/minisite3/public/upload


#run the proxy server
java -jar /root/minisite3/uwverigames/ProxyServer/ProxyServer.jar

