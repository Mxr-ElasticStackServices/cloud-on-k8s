#!/bin/bash 

#******************************************************************************************
#  NOTICE:  1)  This script just installs the ECK Operator code components.             ***
#               It is part2 of a two part set of scripts, to builds and deploy code.    ***
#               It assumes your code has been already built (base/all-in-one.yaml) file ***
#               This code is non-destructive, you can run it as many times as necessary ***
#           3)  Requires:
#                 - helm 3
#                 - kubectl
#******************************************************************************************
# History Block
#******************************************************************************************
# Date        Story/Task     Description
# ========    ==========     ==============================================================
# 09/24/2020  15417          Splitting the build and install into separate scripts for sc2s
#


# Variable definitions
ENV=''


######################################################
# Validation Routines
######################################################

# Check valid Regions values
validateEnv () {
    grep -F -q -x "$1" <<EOF
com_gov
commercial
govcloud
sc2s
shift
EOF
}

# Show usage info
function _usage() {
cat <<EOU

  Usage: $(basename $0) -r (commercial|govcloud|sc2s|shift)
  Ex.  :
         ./$(basename $0) -r commercial
         ./$(basename $0) -r sc2s
         ./$(basename $0) -r v3r
         ./$(basename $0) -r govcloud

EOU
}

# Process input parameters
while (("$#")); do
    if [[ "$1" == "-r" || "$1" == "--region" ]]; then
        REGION=$2
        shift
    elif [[ "$1" == "-h" || "$1" == "--help" ]]; then
        _usage
        exit 0
    else
        shift
    fi
done

# You must provide Region
if [[ -z $REGION ]]; then
  echo "One or more parameters missing."
  _usage
  exit 1;
fi

# Only allow valid Regions
validateEnv "$REGION"
if [[ $? != 0 ]]; then
  echo "Region you've specified ($REGION) is not in the list of valid regions.  See below:"
  _usage
  exit 1;
fi

echo ""
echo "*****************************************"
echo " Running an ECK Install with these parms:"
echo "   -region: $REGION"
echo "*****************************************"

##################################
# Install Elasticsearch Operator
##################################

echo ""
echo ">>>Starting helm3 upgrade process" 
kubectl config set-context --current --namespace=elastic-system
helm3 upgrade   --install elastic-operator eck-operator -f values/$REGION/values.yaml --namespace elastic-system
[ $? != 0 ] && echo "Error.  Could not list the helm3 deployments" && exit 1

# List helm3 deployment status
#echo ""
#echo ">>>Listing helm3 deployments"
#helm3 list --namespace elastic-search
#[ $? != 0 ] && echo "Error.  Could not list the helm3 deployments" && exit 1

# Deploy sample Elastic Quickstart into default namespace - to test the Operator can deploy sample code
echo ">>>Starting the deployment test"
kubectl apply -f test/quickstart.yaml --namespace default

# Check the deployment for green - you've got 10 seconds 
echo "Check the deployment status (15 seconds)"
x=5
echo "checking..." 
while [ $x -gt 0 ] 
do
    sleep 1s
    STATUS=$(kubectl -n elastic get elasticsearch -o json --namespace default | jq -r .items[].status.health)
    if [[ "$STATUS" == "green" ]]; then
        echo ">>>Quickstart deployment is Green.   Test is successful."
        break; 
    fi
    echo "$STATUS; $x - still not ready"
    x=$(( $x - 1 ))
done

# If STATUS did not turn green, error out and bail
if [[ -z $STATUS || "$STATUS" -ne "green" ]]; then
    echo "Error.  The deployment did not turn green in the time alloted, it could still be ok, but not waiting anymore"
fi

# Cleanup Quckstart deployment (success or not)
echo ">>>Cleaning up after successful deployment and test"
kubectl delete -f test/quickstart.yaml --namespace default

# Success
echo ""
echo ">>>Deployment of ECK in $REGION was successful"
echo ""
exit 0





