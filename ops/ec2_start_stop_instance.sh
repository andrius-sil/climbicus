#!/bin/bash

set -e

COMMAND=$1
INSTANCE_NAME="climbicus-${ENV}"

instance_id=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${INSTANCE_NAME}" --output text --query "Reservations[*].Instances[*].InstanceId")

if [ "$COMMAND" == "start" ]; then
  aws ec2 start-instances --instance-ids $instance_id
elif [ "$COMMAND" == "stop" ]; then
  aws ec2 stop-instances --instance-ids $instance_id
fi

