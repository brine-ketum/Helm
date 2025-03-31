#cloud-config
package_update: true
packages:
  - docker.io
runcmd:
  - systemctl start docker
  - systemctl enable docker
