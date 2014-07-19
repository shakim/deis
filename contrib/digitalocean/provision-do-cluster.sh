#!/usr/bin/env bash
#
# Usage: ./provision-do-cluster.sh <REGION_ID> <IMAGE_ID> <SSH_ID> <SIZE>
#

set -e

THIS_DIR=$(cd $(dirname $0); pwd) # absolute path
CONTRIB_DIR=$(dirname $THIS_DIR)

source $CONTRIB_DIR/utils.sh

# check for DO tools in $PATH
if ! which tugboat > /dev/null; then
  echo_red 'Please install the tugboat gem and ensure it is in your $PATH.'
  exit 1
fi

if [ -z "$DEIS_NUM_INSTANCES" ]; then
    DEIS_NUM_INSTANCES=3
fi

# check that the CoreOS user-data file is valid
$CONTRIB_DIR/util/check-user-data.sh

# launch the Deis cluster on DigitalOcean
i=1 ; while [[ $i -le $DEIS_NUM_INSTANCES ]] ; do \
    NAME=deis-$i
    echo_yellow "Provisioning ${NAME}..."
    tugboat create $NAME -r $1 -i $2 -p true -k $3 -s $4
    ((i = i + 1)) ; \
done

echo_green "Your Deis cluster has successfully deployed to DigitalOcean."
echo_green "Please continue to follow the instructions in the README."
