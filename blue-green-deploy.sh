#!/bin/sh

echo "++++++++++++++++++++++++++++++++++"
echo "Blue Green Deployment Starting"
echo "++++++++++++++++++++++++++++++++++"

if [ "$#" -ne 3 ]; then
	    echo "Usage: blue-green-deploy.sh 'PCF Domain' 'Existing Application Name In PCF' 'Location Of Application To Deploy'";
	    echo "Hint: blue-green-deploy.sh 'cfapps.io' 'spring-music' './green-app' ";
	    echo "Program terminating ...";
	    exit 1;
fi

# Set Up Required Variables
DOMAIN=$1
ORIGINAL_APP=$2
NEW_APP_NAME="$2-green"
NEW_APP_LOCATION="$3"
OLD_APP="$2-blue"

echo "++++++++++++++++++++++++++++++++++"
echo "Blue Green Plan"
echo "++++++++++++++++++++++++++++++++++"
echo ""
echo "At the end of this you should have 2 instances running of the new application and the currently " +
" running version in the space named $OLD_APP (it will be stopped with no route)"
echo ""
echo "Here are the steps:"
echo "-------------------"
echo "1. Check the original application is running/exists"
echo "2. Deploy The Blue Version of the application"
echo "3. Run a basic health check (ensure HTTP 200 on an endpoint)"
echo "4. Scale up the blue application"
echo "5. Switch over traffic from the current application to the blue one"
echo "6. Stop the previous application and name it appropriately (blue)"
echo "7. Clean up"
echo ""
echo "++++++++++++++++++++++++++++++++++"
echo "Applications and Domain"
echo "++++++++++++++++++++++++++++++++++"
echo "Application: $ORIGINAL_APP"
echo "Domain: $DOMAIN"
echo ""
echo "1. Check the original application is running/exists"
OUTPUT="$(cf events $ORIGINAL_APP)"
if [[ $OUTPUT == *"App $ORIGINAL_APP not found"* ]]; then
  echo "Need to do an intial CF push on $ORIGINAL_APP before doing a Blue Green Deployment"
	echo "Program Terminating..."
	exit 1;
fi
echo ""

# push the application with a manifest that binds all required services
echo "2. Deploy The Blue Version of the application"
echo ""
echo "cf push $NEW_APP_NAME -p $NEW_APP_LOCATION"
cf push $NEW_APP_NAME -p $NEW_APP_LOCATION
echo ""

# Run Tests on the newly deployed app check that it is okay
echo "3. Run a basic health check (ensure HTTP 200 on an endpoint)"
echo ""
RESPONSE=`curl -sI http://NEW_APP_NAME.$DOMAIN/health`
echo "$RESPONSE"
if [[ $RESPONSE != *"HTTP/1.1 200 OK"* ]]
then
  echo "Service Did Not Start Up - Stopping Upgrade...";
  cf delete $NEW_APP_NAME -f;
  echo "New Service Deleted"
  echo "Upgrade Stopping"
  exit 1;
fi
echo ""

# scale up the new app instance
echo "4. Scale up the green application"
echo "cf scale $NEW_APP_NAME -i 2"
cf scale $NEW_APP_NAME -i 2
echo ""

# start directing traffic to the new app instance
echo "5. Switch over traffic from the current application to the blue one"
echo "cf map-route $NEW_APP_NAME $DOMAIN -n $ORIGINAL_APP"
cf map-route $NEW_APP_NAME $DOMAIN -n $ORIGINAL_APP
echo ""

# scale down the proi app instances
echo "6. Stop the previous application and name it appropriately (in case of roll back)"
echo "Order of operations:"
echo "a. Scale Down"
echo "b. Unmap"
echo "c. Stop"
echo ""
echo "a. Scale Down"
echo "cf scale $ORIGINAL_APP -i 1"
cf scale $ORIGINAL_APP -i 1
echo ""

# stop taking traffic on the current prod instance
echo "b. Unmap"
echo "cf unmap-route javascript-ui $DOMAIN -n javascript-ui"
cf unmap-route $ORIGINAL_APP $DOMAIN -n $ORIGINAL_APP
echo ""

# decommission the old app
echo "c. Stop"
echo "cf stop $ORIGINAL_APP"
cf stop $ORIGINAL_APP
echo ""

echo "7. Clean up"
echo ""

# delete any version of the old app that might be lying around still
echo "Delete any old back up versions of the application"
echo "cf delete $OLD_APP -f"
cf delete $OLD_APP -f

echo "Rename the old service to a name that reflects it new status"
echo "cf rename javascript-service javascript-service-old"
cf rename $ORIGINAL_APP $ORIGINAL_APP-old
echo ""

# clean up the temp route
echo "Remove the temp route"
echo "cf unmap-route $NEW_APP_NAME $DOMAIN -n $NEW_APP_NAME"
cf unmap-route $NEW_APP_NAME $DOMAIN -n $NEW_APP_NAME
echo ""

# rename the app
echo "Rename the app"
echo "cf rename $NEW_APP_NAME $ORIGINAL_APP"
cf rename $NEW_APP_NAME $ORIGINAL_APP
