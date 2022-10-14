#!/bin/bash
set -o errexit
set -o pipefail
set -u

#######################################
# Ensure that a value is non-empty
# Arguments:
#   The description of the value
#   The value
# Returns:
#   None
#######################################
check_arg() {
  if [[ -z "$2" ]]; then
    echo "Required: $1"
    echo
    display_usage
    exit 1
  fi
}

endpoint=''
local_port=''
namespace="symdb"
remote_port=''

display_usage() {
  cat <<EOM
    ##### tunnel #####
    SSH tunnel via AWS Session Manager Port Forwarding.

    Looks up the EC2 instance to use for tunneling by searching for an instance
    that is named "\${namespace}-bastion".

    More info: https://blog.symops.com/2022/10/04/jit-ec2-with-sym/
    Required arguments:
        -e | --endpoint         The endpoint to tunnel requests to
        -l | --local-port       The local port for tunnel requests
instance
        -r | --remote-port      The remote port the endpoint is listening on

    Optional arguments:
        -n | --namespace        The namespace to use for identifying the bastion
        -h | --help             Show this message

    Requirements:
        aws:        AWS Command Line Interface
EOM
  exit 2
}

while [[ $# -gt 0 ]]; do
  key="$1"

  case ${key} in
    -e|--endpoint)
      endpoint=$2
      shift
      ;;
    -l|--local-port)
      local_port=$2
      shift
      ;;
    -n|--namespace)
      namespace=$2
      shift
      ;;
    -r|--remote-port)
      remote_port=$2
      shift
      ;;
    -h|--help)
      display_usage
      exit 0
      ;;
    *)
      display_usage
      exit 1
      ;;
  esac
  shift
done

check_arg '-e or --endpoint' "${endpoint}"
check_arg '-l or --local-port' "${local_port}"
check_arg '-r or --remote-port' "${remote_port}"

bastion_name="${namespace}-bastion"

# Find an EC2 instance named \${namespace}-bastion
bastion_id=$(aws ec2 describe-instances \
  --filter Name=tag:Name,Values="${bastion_name}" Name=instance-state-name,Values=running \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text)
if [[ -z "${bastion_id}" || "None" = "${bastion_id}" ]]; then
  echo "Unable to find bastion instance: ${bastion_name}"
  exit 1
fi

aws ssm start-session \
  --target "${bastion_id}" \
  --document-name "AWS-StartPortForwardingSessionToRemoteHost" \
  --parameters '{"host":["'"${endpoint}"'"],"portNumber":["'"${remote_port}"'"],"localPortNumber":["'"${local_port}"'"]}'
