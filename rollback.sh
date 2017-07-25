#!/bin/sh

#stop if a exit hits a non zero
set -e

echo ""
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Roll Back Blue Green"
echo "https://github.com/lshannon/pcf-bluegreen-script"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""

if [ "$#" -ne 2 ]; then
	    echo "Usage: rollback.sh 'PCF Domain' 'Application Name'";
	    echo "Hint: rollback.sh 'cfapps.io' 'spring-music'";
	    echo "Program terminating ...";
	    exit 1;
fi

# Set Up Required Variables
DOMAIN=$1
ORIGINAL_APP=$2
OLD_PREFIX="previous"
OLD_APP="$2-$OLD_PREFIX"

echo "Goal:"
echo "----------------------------"
echo "Restore $OLD_APP to the route for $ORIGINAL_APP"
echo ""
echo "Steps To Execute:"
echo "----------------------------"
echo "1. Check for $OLD_APP"
echo "2. Switch over traffic from $ORIGINAL_APP to $OLD_APP"
echo "3. Rename $ORIGINAL_APP to be $OLD_APP"
echo "4. Clean up (scale down, stop, unmap)"
echo ""
echo "1. Check for $ORIGINAL_APP"
echo "---------------------------------------------------"
OUTPUT="$(cf events $OLD_APP)"
if [[ $OUTPUT == *"App $OLD_APP not found"* ]]; then
  echo "The is not a recognized version to roll back too"
	echo "Program Terminating..."
	exit 1;
else
	echo "$OLD_APP exists. Proceeding with the Rollback..."
fi
echo ""

# start directing traffic to the new app instance
echo "2. Switch over traffic from $ORIGINAL_APP to $OLD_APP"
echo "-----------------------------------------------------"
echo "cf map-route $ORIGINAL_APP $DOMAIN -n $OLD_APP"
cf map-route $ORIGINAL_APP $DOMAIN -n $OLD_APP
echo ""

# Re
echo "3. Rename $ORIGINAL_APP to $OLD_APP"
echo "-----------------------------------------------------"
echo "Rename $ORIGINAL_APP to $OLD_APP-temp"
echo "cf rename $ORIGINAL_APP $OLD_APP-temp"
cf rename $ORIGINAL_APP $OLD_APP
echo ""

# Rename the application
echo "Rename $OLD_APP to $ORIGINAL_APP"
echo "cf rename $ORIGINAL_APP $OLD_APP"
cf rename $ORIGINAL_APP $OLD_APP
echo ""

# Rename the application
echo "Rename $OLD_APP-temp to $OLD_APP"
echo "cf rename $OLD_APP-temp $OLD_APP"
cf rename $OLD_APP-temp $OLD_APP
echo ""

# scale down the proi app instances
echo "4. Clean Up (delete temp routes)"
echo "--------------------------------"
echo "Order of operations:"
echo "a. Scale Down"
echo "b. Unmap"
echo "c. Stop"
echo ""
echo "a. Scale Down"
echo "-------------"
echo "cf scale $ORIGINAL_APP -i 1"
cf scale $ORIGINAL_APP -i 1
echo ""

# stop taking traffic on the current prod instance
echo "b. Unmap $ORIGINAL_APP"
echo "----------------------"
echo "cf unmap-route $ORIGINAL_APP $DOMAIN -n $ORIGINAL_APP"
cf unmap-route $ORIGINAL_APP $DOMAIN -n $ORIGINAL_APP
echo ""

# decommission the old app
echo "c. cf stop $ORIGINAL_APP"
echo "------------------------"
cf stop $ORIGINAL_APP
echo ""

echo "Rename $ORIGINAL_APP to $OLD_APP"
echo "cf rename $ORIGINAL_APP $OLD_APP"
cf rename $ORIGINAL_APP $OLD_APP
echo ""
