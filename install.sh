#!/bin/bash
yum -y install httpd
systemctl start httpd.service
echo "<html><h1>Hello from mlabouardy ^^</h2></html>" > /var/www/html/index.html
