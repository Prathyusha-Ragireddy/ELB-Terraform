#!/bin/bash
yum install -y httpd
service httpd start
chkonfig httpd on
echo "<html><h1>Hello World!!</h2></html>" > /var/www/html/index.html
