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
PORTAL_HOSTNAME=$(aws ssm get-parameter --region eu-west-1  --name $APPLICATION_NAME-PORTAL_HOSTNAME | jq -r '.Parameter.Value')
PORTAL_MODE=$(aws ssm get-parameter --region eu-west-1  --name $APPLICATION_NAME-PORTAL_MODE | jq -r '.Parameter.Value')

### SSM PARAMETER STORE Created Manually 
CONFIG_SQS_QUEUE=$(aws ssm get-parameter --region eu-west-1  --name $APPLICATION_NAME-CONFIG_SQS_QUEUE | jq '.Parameter.Value')
BILLING_SQS_QUEUE=$(aws ssm get-parameter --region eu-west-1  --name $APPLICATION_NAME-BILLING_SQS_QUEUE | jq '.Parameter.Value')
JIRA_USERNAME=$(aws ssm get-parameter --region eu-west-1  --name $APPLICATION_NAME-JIRA_USERNAME | jq '.Parameter.Value')
JIRA_PASSWORD=$(aws ssm get-parameter --region eu-west-1  --name $APPLICATION_NAME-JIRA_PASSWORD | jq '.Parameter.Value')
JIRA_TOKEN=$(aws ssm get-parameter --region eu-west-1  --name $APPLICATION_NAME-JIRA_TOKEN | jq '.Parameter.Value')
ASSEMBLA_API_KEY=$(aws ssm get-parameter --region eu-west-1  --name $APPLICATION_NAME-ASSEMBLA_API_KEY | jq '.Parameter.Value')
ASSEMBLA_SECRET=$(aws ssm get-parameter --region eu-west-1  --name $APPLICATION_NAME-ASSEMBLA_SECRET | jq '.Parameter.Value')
SES_KEY=$(aws ssm get-parameter --region eu-west-1  --name $APPLICATION_NAME-SES_KEY | jq '.Parameter.Value')
SES_SECRET=$(aws ssm get-parameter --region eu-west-1  --name $APPLICATION_NAME-SES_SECRET | jq '.Parameter.Value')
SES_SECRET_CLEANED=$(echo $SES_SECRET|sed -e 's/[\/&]/\\&/g')



## FILLING UP THE TEMPLATE
sed -ie "s/|DB_USERNAME|/$DB_USERNAME/g" /var/www/altostratus/.env.template
sed -ie "s/|DB_PASSWORD|/$DB_PASSWORD/g" /var/www/altostratus/.env.template
sed -ie "s/|DB_HOSTNAME|/$DB_HOSTNAME/g" /var/www/altostratus/.env.template
sed -ie "s/|MEMCACHE_HOSTNAME|/$MEMCACHE_HOSTNAME/g" /var/www/altostratus/.env.template
sed -ie "s/|PORTAL_MODE|/$PORTAL_MODE/g" /var/www/altostratus/.env.template
sed -ie "s/|PORTAL_HOSTNAME|/$PORTAL_HOSTNAME/g" /var/www/altostratus/.env.template
sed -ie "s/|CONFIG_SQS_QUEUE|/$CONFIG_SQS_QUEUE/g" /var/www/altostratus/.env.template
sed -ie "s/|BILLING_SQS_QUEUE|/$BILLING_SQS_QUEUE/g" /var/www/altostratus/.env.template
sed -ie "s/|JIRA_USERNAME|/$JIRA_USERNAME/g" /var/www/altostratus/.env.template
sed -ie "s/|JIRA_PASSWORD|/$JIRA_PASSWORD/g" /var/www/altostratus/.env.template
sed -ie "s/|JIRA_TOKEN|/$JIRA_TOKEN/g" /var/www/altostratus/.env.template
sed -ie "s/|SES_KEY|/$SES_KEY/g" /var/www/altostratus/.env.template
sed -ie "s/|SES_SECRET|/$SES_SECRET_CLEANED/g" /var/www/altostratus/.env.template
sed -ie "s/|TOKENETLCLOUDFORMATIONPRICING|/$TOKENETLCLOUDFORMATIONPRICING/g" /var/www/altostratus/.env.template
sed -ie "s/|TOKEN_CLOUDWATCH_ALARMS|/$TOKEN_CLOUDWATCH_ALARMS/g" /var/www/altostratus/.env.template
sed -ie "s/|TOKEN_READ_ONLY_ACCESS|/$TOKEN_READ_ONLY_ACCESS/g" /var/www/altostratus/.env.template
sed -ie "s/|TOKEN_MARKETPLACE_ACCESS|/$TOKEN_MARKETPLACE_ACCESS/g" /var/www/altostratus/.env.template



sudo chown -Rf apache:apache /var/www/altostratus/
cp /var/www/altostratus/.env.template /var/www/altostratus/.env
mkdir -p /usr/share/httpd/.cache/
mkdir -p /usr/share/httpd/.config/
mkdir -p /var/www/altostratus/storage/framework/data
sudo chown apache:apache /usr/share/httpd/.cache
sudo chown apache:apache /usr/share/httpd/.config
cd /var/www/altostratus/
sudo -u apache /usr/local/bin/composer update -n 
sudo -u apache /usr/local/bin/composer install -n
sudo chown -Rf apache:apache /var/www/altostratus/
sudo -u apache php artisan config:clear && php artisan view:clear && php artisan route:clear && php artisan cache:clear

