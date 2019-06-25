#!/bin/bash
yum install -y httpd
service httpd start
chkonfig httpd on
serverip=`/sbin/ifconfig eth0 | grep "inet" | awk '{print $2}' | awk 'NR==1' | cut -d':' -f2`
echo "<html><h1>Hello from mlabouardy ^^</h1> <h2> Server IPAddress serving you is $serverip </h2> <</html>" > /var/www/html/index.html

