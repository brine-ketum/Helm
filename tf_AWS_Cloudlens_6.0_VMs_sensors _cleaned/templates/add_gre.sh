# Start NTOP docker and connect it to cloudlens0 interface
#docker run --name ntop_engine --net=host -t -p 3000:3000 -d lucaderi/ntopng-docker ntopnp -i cloudlens0
#MY_IP=`hostname -I`
MY_IP=`/sbin/ifconfig eth0 | grep 'inet addr' | cut -d: -f2 | awk '{print $1}'`
echo $MY_IP >> /tmp/p.txt
ip link add gre2 type gretap local $MY_IP remote ${riverbed_ip} dev eth0 ttl 255 key 1
ip link set gre2 up
echo "GRE forwarding Installed $MY_IP to remote ${riverbed_ip} " >> /tmp/p.txt
