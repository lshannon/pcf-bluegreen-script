# pcf-bluegreen-script
A shell script for doing Blue/Green deployments to PCF

## Usage

To run the script the following arguements need to be passed in:

1. PCF base domain
2. Name of the application (need to already be running)
3. Directory where the new deployment is located

### New Deployment Directory

The new directory needs to contain:

1. Deployable artifact
2. manifest.yml

#### Manifest.yml Requirements

The manifest.yml must specifiy:

1. At least 2+ instances, otherwise clients will get a 404 during the deployment
2. The buildpack to be used, ensure the target PCF contains the required buildpack

## Demo

Running the example in the route of this project directory looks something like this.

To deploy the 'green' application.

```shell

./blue-green-deploy.sh cfapps.io blue-green-html-test green-app

```

To deploy the 'blue' application.

```shell

./blue-green-deploy.sh cfapps.io blue-green-html-test blue-app

```
