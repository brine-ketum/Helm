#!/bin/bash
echo PEPE | tee /tmp/pepe.txt
yum update -y
echo END | tee -a /tmp/pepe.txt

