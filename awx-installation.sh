#!/bin/sh
# Enable required repos
subscription-manager attach --auto
setenforce 0
sudo yum install yum-utils -y
yum-config-manager --enable rhel-server-rhscl-7-rpms
subscription-manager repos --enable=rhel-7-server-optional-rpms
subscription-manager repos --enable=rhel-7-server-extras-rpms

# Download required packages
yum -y install gcc gcc-c++ wget
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum install epel-release-latest-7.noarch.rpm -y
yum install http://mirror.centos.org/centos/7/extras/x86_64/Packages/centos-release-scl-rh-2-3.el7.centos.noarch.rpm -y


#Download Private repos for AWX rabbitmq and Python
echo "[ansible-awx]
name=ansible-awx
baseurl= http://3.120.129.218/repos/awx/
skip_if_unavailable=True
gpgcheck=0
enabled=1
enabled_metadata=1" > /etc/yum.repos.d/ansible-awx.repo

echo "[rabbitmq]
name= rabbitmq
baseurl= http://3.120.129.218/repos/rabbitmq/
skip_if_unavailable=True
gpgcheck=0
enabled=1
enabled_metadata=1" > /etc/yum.repos.d/rabbitmq.repo

echo "[python-36-ansible]
name=python-36-ansible
baseurl= http://3.120.129.218/repos/python-36-ansible/
skip_if_unavailable=True
gpgcheck=0
enabled=1
enabled_metadata=1" > /etc/yum.repos.d/python_ansible.repo

yum -y install rabbitmq-server

yum install ansible-awx -y
yum -y install python-psycopg2 rh-postgresql10 memcached nginx 

#yum install rh-python36-build -y

yum install rh-python36-ansible -y
yum install rh-git29 -y
/opt/rh/rh-python36/root/usr/bin/python3.6 /opt/rh/rh-python36/root/usr/bin/pip install Django==2.2.8
/opt/rh/rh-python36/root/usr/bin/python3.6 /opt/rh/rh-python36/root/usr/bin/pip install channels==1.1.8
/opt/rh/rh-python36/root/usr/bin/python3.6 /opt/rh/rh-python36/root/usr/bin/pip install django-split-settings
/opt/rh/rh-python36/root/usr/bin/python3.6 /opt/rh/rh-python36/root/usr/bin/pip install prometheus_client
/opt/rh/rh-python36/root/usr/bin/python3.6 /opt/rh/rh-python36/root/usr/bin/pip install django-qsstats-magic
/opt/rh/rh-python36/root/usr/bin/python3.6 /opt/rh/rh-python36/root/usr/bin/pip install ansiconv
/opt/rh/rh-python36/root/usr/bin/python3.6 /opt/rh/rh-python36/root/usr/bin/pip install python3-memcached
/opt/rh/rh-python36/root/usr/bin/python3.6 /opt/rh/rh-python36/root/usr/bin/pip install schedule
/opt/rh/rh-python36/root/usr/bin/python3.6 /opt/rh/rh-python36/root/usr/bin/pip install attrs==19.2.0
/opt/rh/rh-python36/root/usr/bin/python3.6 /opt/rh/rh-python36/root/usr/bin/pip install asgi_amqp
/opt/rh/rh-python36/root/usr/bin/python3.6 /opt/rh/rh-python36/root/usr/bin/pip install uwsgi
/opt/rh/rh-python36/root/usr/bin/python3.6 /opt/rh/rh-python36/root/usr/bin/pip install django-radius
/opt/rh/rh-python36/root/usr/bin/python3.6 /opt/rh/rh-python36/root/usr/bin/pip install tacacs_plus
/opt/rh/rh-python36/root/usr/bin/python3.6 /opt/rh/rh-python36/root/usr/bin/pip install onelogin
/opt/rh/rh-python36/root/usr/bin/python3.6 /opt/rh/rh-python36/root/usr/bin/pip install python3-saml
/opt/rh/rh-python36/root/usr/bin/python3.6 /opt/rh/rh-python36/root/usr/bin/pip install gitdb
/opt/rh/rh-python36/root/usr/bin/python3.6 /opt/rh/rh-python36/root/usr/bin/pip install msgpac
yum install rh-git29 -y
yum install rh-python36-ansible -y

#Configure postgres
scl enable rh-postgresql10 "postgresql-setup initdb"
systemctl start rh-postgresql10-postgresql.service
systemctl enable rh-postgresql10-postgresql.service
systemctl start rabbitmq-server
systemctl enable rabbitmq-server
systemctl start memcached
systemctl enable memcached
scl enable rh-postgresql10 "su postgres -c \"createuser -S awx\""
scl enable rh-postgresql10 "su postgres -c \"createdb -O awx awx\""
sudo -u awx scl enable rh-python36 rh-postgresql10 rh-git29 "GIT_PYTHON_REFRESH=quiet awx-manage migrate"
echo "from django.contrib.auth.models import User; User.objects.create_superuser('admin', 'root@localhost', 'password')" | sudo -u awx scl enable rh-python36 rh-postgresql10 "GIT_PYTHON_REFRESH=quiet awx-manage shell"
sudo -u awx scl enable rh-python36 rh-postgresql10 rh-git29 "GIT_PYTHON_REFRESH=quiet awx-manage create_preload_data" # Optional Sample Configuration
sudo -u awx scl enable rh-python36 rh-postgresql10 rh-git29 "GIT_PYTHON_REFRESH=quiet awx-manage provision_instance --hostname=$(hostname)"
sudo -u awx scl enable rh-python36 rh-postgresql10 rh-git29 "GIT_PYTHON_REFRESH=quiet awx-manage register_queue --queuename=tower --hostnames=$(hostname)"
wget -O /etc/nginx/nginx.conf http://3.120.129.218/repos/nginx.conf

##Start all the required services
sudo systemctl start nginx
sudo systemctl start awx-cbreceiver
sudo systemctl start awx-dispatcher
sudo systemctl start awx-channels-worker
sudo systemctl start awx-daphne
sudo systemctl start awx-web
sudo systemctl enable nginx
sudo systemctl enable awx-cbreceiver
sudo systemctl enable awx-dispatcher
sudo systemctl enable awx-channels-worker
sudo systemctl enable awx-daphne
sudo systemctl enable awx-web
