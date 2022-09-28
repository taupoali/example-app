#!/bin/bash

if [ -z "$APPLICATION_NAME" ]
  then
    echo "No argument supplied - require application name"
    exit 1
fi

echo "$APPLICATION_NAME-RDSCreds"
echo AWSCURRENT

aws secretsmanager get-secret-value --secret-id $APPLICATION_NAME-RDSCreds --version-stage AWSCURRENT --region eu-west-1  --query SecretString --output text

### SECRETS MANAGER
DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id $APPLICATION_NAME-RDSCreds --version-stage AWSCURRENT --region eu-west-1  --query SecretString --output text | jq .password)
DB_USERNAME=$(aws secretsmanager get-secret-value --secret-id $APPLICATION_NAME-RDSCreds --version-stage AWSCURRENT --region eu-west-1  --query SecretString --output text | jq -r .username)

### SSM PARAMETER STORE from CF
DB_HOSTNAME=$(aws ssm get-parameter --region eu-west-1  --name $APPLICATION_NAME-DB_HOSTNAME | jq -r '.Parameter.Value')

### SSM PARAMETER STORE Created Manually 
CONFIG_SQS_QUEUE=$(aws ssm get-parameter --region eu-west-1  --name $APPLICATION_NAME-CONFIG_SQS_QUEUE | jq '.Parameter.Value')
SES_KEY=$(aws ssm get-parameter --region eu-west-1  --name $APPLICATION_NAME-SES_KEY | jq '.Parameter.Value')
SES_SECRET=$(aws ssm get-parameter --region eu-west-1  --name $APPLICATION_NAME-SES_SECRET | jq '.Parameter.Value')
SES_SECRET_CLEANED=$(echo $SES_SECRET|sed -e 's/[\/&]/\\&/g')


## FILLING UP THE TEMPLATE
sed -ie "s/|DB_USERNAME|/$DB_USERNAME/g" .env.template
sed -ie "s/|DB_PASSWORD|/$DB_PASSWORD/g" .env.template
sed -ie "s/|DB_HOSTNAME|/$DB_HOSTNAME/g" .env.template
sed -ie "s/|CONFIG_SQS_QUEUE|/$CONFIG_SQS_QUEUE/g" .env.template
sed -ie "s/|SES_KEY|/$SES_KEY/g" .env.template
sed -ie "s/|SES_SECRET|/$SES_SECRET_CLEANED/g" .env.template


cp .env.template .env
sudo -u apache /usr/local/bin/composer update -n 
sudo -u apache /usr/local/bin/composer install -n
sudo -u apache php artisan config:clear && php artisan view:clear && php artisan route:clear && php artisan cache:clear

