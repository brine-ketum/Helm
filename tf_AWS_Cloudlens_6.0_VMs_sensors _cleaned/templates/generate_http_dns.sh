sleep 40
#for i in {1..10}; do wget www.elmundo.es ; sleep 1 ; nslookup www.yahoo.com ; done
echo "Starting Traffic wget www.lequipe.fr ; sleep 1 ; nslookup www.yahoo.com" | tee /tmp/traffic.txt
for i in {1..500}; do wget www.lequipe.fr ; sleep 1 ; nslookup www.yahoo.com ; done
echo "Done. Sleeping 30" | tee -a /tmp/traffic.txt
sleep 30
echo "Starting Traffic wget www.marca.com; sleep 1 ; nslookup www.guardian.com" | tee -a /tmp/traffic.txt
for i in {1..400}; do wget www.marca.com ;sleep 1 ; nslookup www.guardian.com ; done
echo "Traffic Finished" | tee -a /tmp/traffic.txt
