#!/bin/bash

set -e

GROUP_NAME="climbicus-${ENV}"

# Get ip address currently present in the security group.
old_ip=$(aws ec2 describe-security-groups --group-names $GROUP_NAME --query "SecurityGroups[*].IpPermissions[*].IpRanges[*].CidrIp" | jq --raw-output '.[][][]' | grep -v '0.0.0.0/0' | tail -1)

# Remove the rules with the present address.
aws ec2 revoke-security-group-ingress --group-name $GROUP_NAME --protocol tcp --port 22 --cidr $old_ip
aws ec2 revoke-security-group-ingress --group-name $GROUP_NAME --protocol tcp --port 5432 --cidr $old_ip

if [ "$ENV" == "prod" ];then
  flask_server_ip="0.0.0.0/0"
else
  flask_server_ip=$old_ip
fi
aws ec2 revoke-security-group-ingress --group-name $GROUP_NAME --protocol tcp --port 5000 --cidr $flask_server_ip

# Add the rules back in with the new ip address.
export CIDR_IP=$(curl https://ipinfo.io/ip)
aws ec2 authorize-security-group-ingress --group-name $GROUP_NAME --ip-permissions $(cat climbicus_${ENV}_security_rules.json | envsubst | jq -c .)

