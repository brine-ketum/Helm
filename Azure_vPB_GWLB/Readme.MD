# Example Setup
# https://learn.microsoft.com/en-us/azure/load-balancer/quickstart-load-balancer-standard-public-cli

# get Azure locations
# az account list-locations -o table

# create resource group
az group create --name CloudLensGwLB-rg --location northeurope

# create vnet
az network vnet create --resource-group CloudLensGwLB-rg --name VNet --address-prefixes 10.1.0.0/16

# add subnets to vnet
az network vnet subnet create --resource-group CloudLensGwLB-rg --name ConsumerBackendNet --vnet-name VNet --address-prefixes 10.1.0.0/24
az network vnet subnet create --resource-group CloudLensGwLB-rg --name ProviderBackendNet --vnet-name VNet --address-prefixes 10.1.1.0/24
az network vnet subnet create --resource-group CloudLensGwLB-rg --name CLManagementNet --vnet-name VNet --address-prefixes 10.1.2.0/24
az network vnet subnet create --resource-group CloudLensGwLB-rg --name CLToolNet --vnet-name VNet --address-prefixes 10.1.3.0/24

# create a LB public IP address
az network public-ip create --resource-group CloudLensGwLB-rg --name PublicIP --sku Standard --zone 1 2 3

# create the standard load balancer
az network lb create --resource-group CloudLensGwLB-rg --name LoadBalancer --sku Standard --public-ip-address PublicIP --frontend-ip-name FrontEnd --backend-pool-name BackEndPool

# Create the health probe
az network lb probe create --resource-group CloudLensGwLB-rg --lb-name LoadBalancer --name HealthProbe --protocol tcp --port 80

# Create the load balancer rule
az network lb rule create --resource-group CloudLensGwLB-rg --lb-name LoadBalancer --name HTTPRule --protocol tcp --frontend-port 80 --backend-port 80 --frontend-ip-name FrontEnd --backend-pool-name BackEndPool --probe-name HealthProbe --disable-outbound-snat true --idle-timeout 15 --enable-tcp-reset true

# create a network security rule
az network nsg create --resource-group CloudLensGwLB-rg --name NSG

# Create a network security group rule
az network nsg rule create --resource-group CloudLensGwLB-rg --nsg-name NSG --name NSGRuleHTTP --protocol 'TCP' --direction inbound --source-address-prefix '*' --source-port-range '*' --destination-address-prefix '*' --destination-port-range 80 --access allow --priority 200
az network nsg rule create --resource-group CloudLensGwLB-rg --nsg-name NSG --name NSGRuleSSH --protocol 'TCP' --direction inbound --source-address-prefix '*' --source-port-range '*' --destination-address-prefix '*' --destination-port-range 22 --access allow --priority 201

# Create outbound NAT GW public IP address 
az network public-ip create --resource-group CloudLensGwLB-rg --name NATgatewayIP --sku Standard --zone 1 2 3
# Create outbound NAT GW
az network nat gateway create --resource-group CloudLensGwLB-rg --name NATgateway --public-ip-addresses NATgatewayIP --idle-timeout 10
# Associate outbound NAT gateway with subnet 
az network vnet subnet update --resource-group CloudLensGwLB-rg --vnet-name VNet --name ConsumerBackendNet --nat-gateway NATgateway

#### Create backend servers ####

# Create network interfaces for the virtual machines
az network nic create --resource-group CloudLensGwLB-rg --name NicVM1 --vnet-name VNet --subnet ConsumerBackendNet --network-security-group NSG
az network nic create --resource-group CloudLensGwLB-rg --name NicVM2 --vnet-name VNet --subnet ConsumerBackendNet --network-security-group NSG

# Create virtual machines
az vm create --resource-group CloudLensGwLB-rg --name WebServer1 --nics NicVM1 --image ubuntu2204 --admin-username azureuser --admin-password Keysight123456 --custom-data cloud-init-install-pkgs --zone 1 --no-wait 
az vm create --resource-group CloudLensGwLB-rg --name WebServer2 --nics NicVM2 --image ubuntu2204 --admin-username azureuser --admin-password Keysight123456 --custom-data cloud-init-install-pkgs --zone 1 --no-wait 

# Create LB ssh NAT rule
az network lb inbound-nat-rule create --resource-group CloudLensGwLB-rg --lb-name LoadBalancer --name SSHWebServer1 --protocol Tcp --frontend-port 60001 --backend-port 22
az network nic ip-config inbound-nat-rule add --resource-group CloudLensGwLB-rg --nic-name NicVM1 --ip-config-name ipconfig1 --inbound-nat-rule SSHWebServer1 --lb-name LoadBalancer
az network lb inbound-nat-rule create --resource-group CloudLensGwLB-rg --lb-name LoadBalancer --name SSHWebServer2 --protocol Tcp --frontend-port 60002 --backend-port 22
az network nic ip-config inbound-nat-rule add --resource-group CloudLensGwLB-rg --nic-name NicVM2 --ip-config-name ipconfig1 --inbound-nat-rule SSHWebServer2 --lb-name LoadBalancer

# Add virtual machines to load balancer backend pool
az network nic ip-config address-pool add --address-pool BackendPool --ip-config-name ipconfig1 --nic-name NicVM1 --resource-group CloudLensGwLB-rg --lb-name LoadBalancer
az network nic ip-config address-pool add --address-pool BackendPool --ip-config-name ipconfig1 --nic-name NicVM2 --resource-group CloudLensGwLB-rg --lb-name LoadBalancer

# Webbrowser Test http://<MyPublicIP>

# Create Gateway Load Balancer
az network lb create --resource-group CloudLensGwLB-rg --name GWLoadBalancer --sku Gateway --vnet-name VNet --subnet ProviderBackendNet --backend-pool-name BackendPool --frontend-ip-name FrontEnd

# Create External Tunnel Interface
az network lb address-pool tunnel-interface add --address-pool BackEndPool --identifier '901' --lb-name GWLoadBalancer --protocol VXLAN --resource-group CloudLensGwLB-rg --type External --port '10801'

# Create Health Probe
az network lb probe create --resource-group CloudLensGwLB-rg --lb-name GWLoadBalancer --name HealthProbe --protocol Tcp --port 80 --interval '5'

# Create the GWLB rule
az network lb rule create --resource-group CloudLensGwLB-rg --lb-name GWLoadBalancer --name LBRule --protocol all --frontend-port 0 --backend-port 0 --frontend-ip-name FrontEnd --backend-pool-name BackEndPool --probe-name HealthProbe

# Create Tool VM
az vm create --resource-group CloudLensGwLB-rg --name Tool --vnet-name VNet --subnet CLToolNet --image ubuntu2204 --admin-username azureuser --admin-password Keysight123456 --zone 1 --no-wait

# deploy vPB
az network nsg create --resource-group CloudLensGwLB-rg --name vPB-NSG
az network nsg rule create --resource-group CloudLensGwLB-rg --nsg-name vPB-NSG --name myNSGRule-AllowAll --protocol '*' --direction inbound --source-address-prefix '0.0.0.0/0' --source-port-range '*' --destination-address-prefix '0.0.0.0/0' --destination-port-range '*' --access allow --priority 100
az network nsg rule create --resource-group CloudLensGwLB-rg --nsg-name vPB-NSG --name myNSGRule-AllowAll-TCP-Out --protocol 'TCP' --direction outbound --source-address-prefix '0.0.0.0/0' --source-port-range '*' --destination-address-prefix '0.0.0.0/0' --destination-port-range '*' --access allow --priority 100

az network public-ip create --resource-group CloudLensGwLB-rg --name vPB-PublicIP --version IPv4 --sku Standard --zone 1 2 3

az network nic create --resource-group CloudLensGwLB-rg --name vPBNic1 --vnet-name VNet --subnet CLManagementNet --network-security-group vPB-NSG --public-ip-address vPB-PublicIP
az network nic create --resource-group CloudLensGwLB-rg --name vPBNic2 --vnet-name VNet --subnet ProviderBackendNet --network-security-group vPB-NSG --accelerated-networking true
az network nic create --resource-group CloudLensGwLB-rg --name vPBNic3 --vnet-name VNet --subnet CLToolNet --network-security-group vPB-NSG --accelerated-networking true

az vm create --resource-group CloudLensGwLB-rg --name vPB --zone 1 --size Standard_D8_v5  --image Canonical:ubuntu-24_04-lts:server:latest --admin-username vpb --admin-password 'Keysight!123456' --os-disk-size 30 --public-ip-sku Standard --nics vPBNic1 vPBNic2 vPBNic3 --custom-data cloud-init-install-vPB

# Add vPB eth1 to GWLB backend pool
az network nic ip-config address-pool add --address-pool BackendPool --ip-config-name ipconfig1 --nic-name vPBNic2 --resource-group CloudLensGwLB-rg --lb-name GWLoadBalancer

# cleanup environement
# az group delete --name CloudLensGwLB-rg

# ssh inside vPB VM command "ssh admin@localhost -p 2222" password "ixia"

# Execute commands according to AppNote

# Notes:

# ssh to webserver
# ssh azureuser@<MyPublicIP> -p 60001 (WebServer1)
# ssh azureuser@<MyPublicIP> -p 60002 (WebServer2)

# Chain Standard LB to Gateway LB (Cli not working for any reason. Used Azure portal to chain Standard LB to Gateway LB)
# feid=$(az network lb frontend-ip show --resource-group CloudLensGwLB-rg --lb-name GWLoadBalancer --name FrontEnd --query id --output tsv)
# az network lb frontend-ip update --resource-group CloudLensGwLB-rg --lb-name LoadBalancer --name FrontEnd --public-ip-address PublicIP --gateway-lb $feid


#Set Subscription : az account set --subscription "7176addb-4797-4821-80b9-3fd540bf42a3"


Web Server VMs
WebServer1
Username: azureuser
Password: Keysight123456
WebServer2
Username: azureuser
Password: Keysight123456
Tool VM
Username: azureuser
Password: Keysight123456

📌 Step-by-Step Flow with vPB Inspection
1️⃣ Client Sends an HTTP Request

A user enters http://<loadbalancer_ip> in their browser or runs curl http://<loadbalancer_ip>.
The request is sent over the internet to the Azure Standard Load Balancer (LB).
2️⃣ Load Balancer Receives the Request

The Load Balancer frontend (FrontEnd) listens on port 80 and accepts the request.
The Load Balancer Rule (HTTPRule) is configured to route traffic to the Gateway Load Balancer (GWLB) for inspection before reaching the backend web servers.
3️⃣ Traffic is Forwarded to the Gateway Load Balancer (GWLB)

Instead of sending traffic directly to WebServer1 or WebServer2, the Standard Load Balancer redirects traffic to GWLB.
GWLB encapsulates the HTTP request using VXLAN tunnel (port 10801) and forwards it to the vPB VM for inspection.
4️⃣ vPB VM Inspects the Traffic

The vPB VM (Virtual Packet Broker) receives the encapsulated request and analyzes the traffic.
Possible actions inside vPB:
✅ Allow the request and forward it to the web servers.
❌ Drop/block the request if it's suspicious (e.g., potential attack).
📊 Log/monitor the request for analytics or security audits.
5️⃣ vPB Sends the Inspected Traffic Back to GWLB

If the traffic is approved, the vPB VM encapsulates it again using VXLAN (port 10802) and sends it back to GWLB.
GWLB removes the VXLAN encapsulation and forwards the request to the Standard Load Balancer.
6️⃣ Standard Load Balancer Routes Traffic to Web Servers

The Load Balancer selects a healthy web server (WebServer1 or WebServer2) from the backend pool (BackEndPool).
The selected web server receives the clean, inspected request on port 80.
7️⃣ Web Server Processes the Request

The web server (NGINX, Apache, or any other application) processes the HTTP request and generates an HTTP response.
8️⃣ Response is Sent Back Through GWLB & vPB

The web server response must also pass through vPB for inspection before leaving the Azure environment.
The response is encapsulated in VXLAN (port 10801), sent to vPB, inspected, and returned via VXLAN (port 10802) to GWLB.
9️⃣ User Receives the Web Page

After successful inspection, the response is sent back to the client, and the browser renders the web page.


2️⃣ Response Path (Reverse Flow):
✅ Web Server → vPB → GWLB → Load Balancer → Client

After the web server processes the HTTP request, it does NOT respond directly to the client.
Instead, the web server sends the HTTP response BACK to vPB via GWLB for inspection.
GWLB encapsulates the response in VXLAN (port 10802) and forwards it to vPB.
vPB inspects the response (e.g., checking for anomalies, logging).
vPB sends the response back through GWLB.
GWLB decapsulates the VXLAN and forwards the clean response to the Standard Load Balancer.
The Load Balancer finally sends the HTTP response back to the original client.



901	External	Encapsulates inbound traffic (requests) to vPB
902	Internal	Encapsulates outbound traffic (responses) from vPB

# Commands

vxlan-forwarding vxlan1 local-interface eth2 remote-ip 10.1.1.4 vni 901 udp-port 10801

vxlan-forwarding vxlan2 local-interface eth2 remote-ip 10.1.1.4 vni 902 udp-port 10802

vxlan-forwarding vxlan3 local-interface eth1 remote-ip 48.214.104.20 vni 42 udp-port 4789

CloudLensVPB#interface eth1
CloudLensVPB-eth21#ingress-filter vxlan no-strip port 10801
CloudLensVPB-eth2#ingress-filter vxlan no-strip port 10802




match precedence 1 ingress-port eth2 processing-filter encap-type VXLAN vxlan-udp-port 10801 encap-action DECAP egress-port vxlan2 vxlan3 

match precedence 2 ingress-port eth2 processing-filter encap-type VXLAN vxlan-udp-port 10802 encap-action DECAP egress-port vxlan1 vxlan3

vxlan-forwarding vxlan3 local-interface eth2_br remote-ip 10.1.3.5 vni 42 udp-port 4789


vpb@vPB:~$ ssh admin@localhost -p 2222
(admin@localhost) vPB CLI Password: 
Last login: Wed Mar 19 17:26:51 2025 from 127.0.0.1
CloudLensVPB#
CloudLensVPB#
CloudLensVPB#show running
          ^ invalid input
CloudLensVPB#show running-config 
# Ixia Virtual Packet Broker Configuration
#
version 3.9.0-42
system uuid 530d25d2-b6d6-4d66-b9e8-53a9558cfc19
system name CloudLensVPB
no system description
no system location
no enable-rest-api
no drop-duplicate-packets
license server 52.225.226.104 type advanced
interface eth0
 description Management
 ip host-managed
 mtu 1500
end
interface eth1
 no description
 ip 10.1.1.5/24
 mtu 1500
 ingress-mode ip
 no shutdown
 no grat-arp
 no ip-fragmentation
 no ip-reassembly
 no mpls outgoing label
 arp
 icmp
 ingress-filter vxlan port 10801 no-strip
 ingress-filter vxlan port 10802 no-strip
 load-balancer-probe port 80
end
interface eth2
 no description
 ip 10.1.3.4/24
 mtu 1500
 ingress-mode ip
 no shutdown
 no grat-arp
 no ip-fragmentation
 no ip-reassembly
 no mpls outgoing label
 arp
 icmp
 no load-balancer-probe
end
no mpls-strip
no vlan-strip
no fabricpath-strip
no vxlan-strip
no pppoe-strip
no gre-strip
no geneve-strip
no gtp-strip
logging syslog debugging
logging facility local0
no logging host
no snmp-server enable
snmp-server community-string 3075546a366273366a4959305a394c7a797450744e4f2b6838335858595a5436414141414271775378566363672b6f63342f73416930686f6e4b343d
snmp-server version v2c
no snmp-trap enable
no snmp-trap hostip
snmp-trap hostport 162
cloudlens-sensor
 no manager
 tag default
 no enable
 autoupdate
end
vxlan-forwarding vxlan3 local-interface eth2 remote-ip 10.1.3.4 vni 42 udp-port 4789
vxlan-forwarding vxlan1 local-interface eth1 remote-ip 10.1.1.4 vni 901 udp-port 10801
vxlan-forwarding vxlan2 local-interface eth1 remote-ip 10.1.1.4 vni 902 udp-port 10802
match precedence 1 anyprocessing-filter encap-type VXLAN vxlan-udp-port 10801 encap-action DECAP egress-mode all ingress-port eth1 egress-port vxlan2 vxlan3
match precedence 2 anyprocessing-filter encap-type VXLAN vxlan-udp-port 10802 encap-action DECAP egress-mode all ingress-port eth1 egress-port vxlan1 vxlan3



match precedence 1 ingress-port eth1 processing-filter encap-type VXLAN vxlan-udp-port 10801 encap-action DECAP egress-port vxlan2 vxlan3 