# pcf-bluegreen-script
A shell script for doing Blue/Green deployments to PCF

## Usage

Running the example in the route of this project directory looks something like this.

To deploy the 'green' application.

```shell

./blue-green-deploy.sh cfapps.io blue-green-html-test green-app

```

To deploy the 'blue' application.

```shell

./blue-green-deploy.sh cfapps.io blue-green-html-test blue-app

```
