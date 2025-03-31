#cloud-config
package_update: true
packages:
  - docker.io
  - tcpdump
runcmd:
  - systemctl start docker
  - systemctl enable docker
