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

#sudo apt-get update
#sudo apt-get upgrade
sudo apt-get install systemd-services -y

### [install nginx] ############################################################################################################
sudo apt-get install nginx -y

sudo cp $SRC_DIR/nginx/nginx.conf /etc/nginx/nginx.conf
# https://wiki.jenkins-ci.org/display/JENKINS/Running+Jenkins+behind+Nginx
sudo cp -Rf $SRC_DIR/nginx/jenkins /etc/nginx/sites-enabled

#https://confluence.atlassian.com/jirakb/integrating-jira-with-nginx-426115340.html
sudo cp -Rf $SRC_DIR/nginx/jira /etc/nginx/sites-enabled

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

sudo mkdir -p /var/log/nginx/jenkins
sudo mkdir -p /var/log/nginx/jira

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

cd /opt/download
sudo wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.39.tar.gz
sudo tar xvfz ./mysql-connector-java-5.1.39.tar.gz
sudo cp ./mysql-connector-java-5.1.39/mysql-connector-java-5.1.39-bin.jar /opt/atlassian/jira/lib/

#sudo /etc/init.d/jira stop
#sudo rm /opt/atlassian/jira/work/catalina.pid
#sudo /etc/init.d/jira start

#tail -f /opt/atlassian/jira/catalina.out
#sudo chown -Rf jira1:root /opt/atlassian/jira

#sudo ufw enable
#sudo ufw allow "Nginx Full"
#sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT
#sudo iptables -I INPUT -p tcp --dport 8080 -j ACCEPT
#sudo iptables -I INPUT -p tcp --dport 8000 -j ACCEPT
#sudo service iptables save
#sudo service iptables restart

exit 0

# install jira with other way
cd /home/ubuntu
mkdir jira
cd jira
wget http://www.atlassian.com/software/jira/downloads/binary/atlassian-jira-6.1.5-x64.bin
chmod +x atlassian-jira-6.1.5-x64.bin
./atlassian-jira-6.1.5-x64.bin

sudo add-apt-repository ppa:openjdk-r/ppa  
sudo apt-get update   
sudo apt-get install openjdk-7-jdk -y
#sudo apt-get install openjdk-8-jdk
  
sudo apt-get install maven -y

cd /home/ubuntu/atlassian/jira/bin
./start-jira.sh
#stop-jira.sh

# remove
#rm -rf /home/ubuntu/atlassian


/home/ubuntu/atlassian/jira/jre//bin/java -Djava.util.logging.config.file=/home/ubuntu/atlassian/jira/conf/logging.properties -XX:MaxPermSize=384m -Xms384m -Xmx768m -Djava.awt.headless=true -Datlassian.standalone=JIRA -Dorg.apache.jasper.runtime.BodyContentImpl.LIMIT_BUFFER=true -Dmail.mime.decodeparameters=true -Dorg.dom4j.factory=com.atlassian.core.xml.InterningDocumentFactory -XX:+PrintGCDateStamps -XX:-OmitStackTraceInFastThrow -Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager -Djava.endorsed.dirs=/home/ubuntu/atlassian/jira/endorsed -classpath /home/ubuntu/atlassian/jira/bin/bootstrap.jar:/home/ubuntu/atlassian/jira/bin/tomcat-juli.jar -Dcatalina.base=/home/ubuntu/atlassian/jira -Dcatalina.home=/home/ubuntu/atlassian/jira -Djava.io.tmpdir=/home/ubuntu/atlassian/jira/temp org.apache.catalina.startup.Bootstrap start

