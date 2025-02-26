#!/bin/bash
echo PEPE | tee /tmp/pepe.txt
yum update -y
yum -y install docker
service docker start
systemctl enable docker
# Set insecure registries to pull the sensor image
echo "{\"insecure-registries\":[\"${clms_ip}\"]}" | sudo tee /etc/docker/daemon.json
#echo "#!/bin/sh"
echo "{\"insecure-registries\":[\"${clms_ip}\"]}" | sudo tee -a /tmp/pepe.txt
#
echo Restarting Docker service | sudo tee -a /tmp/pepe.txt
sudo service docker restart
echo Docker service restarted | sudo tee -a /tmp/pepe.txt

echo Start Cloudlens Docker service and register to correct project 
sudo docker run -v /lib/modules:/lib/modules -v /var/log:/var/log/cloudlens -v /:/host -v /var/run/docker.sock:/var/run/docker.sock --privileged --name cloudlens-agent -d --restart=on-failure --net=host --log-opt max-size=50m --log-opt max-file=3 ${clms_ip}/sensor --accept_eula yes --project_key ${cl_project_key} --server ${clms_ip} --ssl_verify no --custom_tags ${custom_tags}
echo  "sudo docker run -v /lib/modules:/lib/modules -v /var/log:/var/log/cloudlens -v /:/host -v /var/run/docker.sock:/var/run/docker.sock --privileged --name cloudlens-agent -d --restart=on-failure --net=host --log-opt max-size=50m --log-opt max-file=3 ${clms_ip}/sensor --accept_eula yes --project_key ${cl_project_key} --server ${clms_ip} --ssl_verify no --custom_tags ${custom_tags} " | tee -a /tmp/pepe.txt
echo END | tee -a /tmp/pepe.txt

