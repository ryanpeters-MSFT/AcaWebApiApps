$GROUP = "rg-aca-apps-external"
$REGION = "eastus2"
$CONTAINER_ENV = "apps"
$CONTAINER_NAME_WEB = "web"
$CONTAINER_NAME_API = "api"

# create the group
az group create -n $GROUP -l $REGION

# create the ACA environment
az containerapp env create -n $CONTAINER_ENV -g $GROUP

# create tha ACA api app
az containerapp create -n $CONTAINER_NAME_API -g $GROUP `
    --environment $CONTAINER_ENV `
    --image binarydad/webapi `
    --target-port 80 `
    --ingress 'internal'

# get the fqdn from the internal api app
$API_FQDN = az containerapp show -n $CONTAINER_NAME_API -g $GROUP --query "properties.configuration.ingress.fqdn" -o tsv

# create tha ACA web app
az containerapp create -n $CONTAINER_NAME_WEB -g $GROUP `
    --environment $CONTAINER_ENV `
    --image binarydad/website `
    --target-port 80 `
    --ingress 'external' `
    --env-vars WEBAPI_URL="https://$API_FQDN"

# get the fqdn from the internal api app
$WEB_FQDN = az containerapp show -n $CONTAINER_NAME_WEB -g $GROUP --query "properties.configuration.ingress.fqdn" -o tsv

# dumps
"Web URL: https://$WEB_FQDN"