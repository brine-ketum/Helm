sudo sed -i 's/#$nrconf{restart} = '"'"'i'"'"';/$nrconf{restart} = '"'"'a'"'"';/g' /etc/needrestart/needrestart.conf

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get install -y ca-certificates curl gnupg lsb-release
sudo apt-get update -y || true

sudo apt-get install -y \
	docker-ce docker-ce-cli containerd.io \
	lshw \
	git \
	make \
	gcc

sudo systemctl start docker || true
sudo systemctl enable docker.service || true

sudo groupadd -f docker
sudo usermod -aG docker $USER
