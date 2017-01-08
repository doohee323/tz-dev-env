#!/usr/bin/env bash

sudo su
set -x

# change hosts
echo '' >> /etc/hosts
echo '# for vm' >> /etc/hosts

export SRC_DIR=/vagrant/resources  # for vagrant

echo '' >> .bashrc
echo "alias ll='ls -al'" >> .bashrc
echo "alias l='ls -lah --color=auto'" >> .bashrc
echo "export SRC_DIR='/vagrant/resources'" >> .bashrc
echo "export PATH=$PATH:/usr/local/go/bin" >> .bashrc

sudo apt-get update
sudo apt-get upgrade
sudo apt-get install systemd-services -y

### [install nginx] ############################################################################################################
sudo apt-get install nginx -y

sudo cp $SRC_DIR/nginx/nginx.conf /etc/nginx/nginx.conf
sudo cp -Rf $SRC_DIR/nginx/default /etc/nginx/sites-enabled
# curl http://127.0.0.1:80
sudo service nginx stop
sudo nginx -s stop

### [install jenkins] ############################################################################################################
sudo addgroup jenkins
wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update
sudo apt-get install jenkins -y

# change port
sudo sed -i "s/HTTP_PORT=8080/HTTP_PORT=8000/g" /etc/default/jenkins

# run service
sudo sh /var/lib/dpkg/info/jenkins.postinst configure 1.560

# password
# http://test.com:8080
sudo tail /var/lib/jenkins/secrets/initialAdminPassword

sudo service jenkins status
#sudo service jenkins restart
#tail -f /var/log/jenkins/jenkins.log

### [install mysql] ############################################################################################################
# mysql connector
echo "mysql-server-5.6 mysql-server/root_password password passwd123" | sudo debconf-set-selections
echo "mysql-server-5.6 mysql-server/root_password_again password passwd123" | sudo debconf-set-selections
sudo apt-get install mysql-server-5.6 -y

if [ -f "/etc/mysql/my.cnf" ]
then
	sudo cp $SRC_DIR/jira/my.cnf /etc/mysql/my.cnf
else
	sudo cp $SRC_DIR/jira/my.cnf /etc/mysql/mysql.conf.d/mysqld.cnf
fi

sudo mysql -u root -ppasswd123 -e \
"CREATE DATABASE jiradb; \
CREATE USER jirauser@localhost; \
SET PASSWORD FOR jirauser@localhost= PASSWORD('passwd123'); \
GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,ALTER,INDEX on jiradb.* TO 'jirauser'@'localhost' IDENTIFIED BY 'passwd123'; \
CREATE DATABASE jiradb CHARACTER SET utf8 COLLATE utf8_bin;
FLUSH PRIVILEGES; \
"

# sudo mysql -u root -ppasswd123
# SHOW GRANTS FOR jirauser@localhost;

#sudo service mysql stop
#sudo service mysql start

### [install JIRA Software (Server) ] ##############################################################################################
# cf. http://www.s-tune.com/archives/854
sudo mkdir /opt/download
cd /opt/download
sudo wget https://www.atlassian.com/software/jira/downloads/binary/atlassian-jira-software-7.1.8-jira-7.1.8-x64.bin
sudo chmod +x ./atlassian-jira-software-7.1.8-jira-7.1.8-x64.bin
# sudo ./atlassian-jira-software-7.1.8-jira-7.1.8-x64.bin

#sudo /etc/init.d/jira stop

#sudo rm /opt/atlassian/jira/work/catalina.pid
sudo /etc/init.d/jira start

#tail -f /opt/atlassian/jira/catalina.out

cd /opt/download
sudo wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.39.tar.gz
sudo tar xvfz ./mysql-connector-java-5.1.39.tar.gz
sudo cp ./mysql-connector-java-5.1.39/mysql-connector-java-5.1.39-bin.jar /opt/atlassian/jira/lib/

exit 0

