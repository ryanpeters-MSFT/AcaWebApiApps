$GROUP = "rg-aca-apps-internal"
$REGION = "eastus2"
$CONTAINER_ENV = "apps"
$CONTAINER_NAME_WEB = "web"
$CONTAINER_NAME_API = "api"
$VNET = "vnet"
$ACA_SUBNET = "aca"
$VMS_SUBNET = "vms"
$ACA_SUBNET_NSG = "nsg-aca"
$VMS_SUBNET_NSG = "vm-nsg"
$VM = "webserver"
$VM_USERNAME = "ryan"
$VM_IP = "vm-ip"
$VM_NIC = "vm-nic"

# create the group
az group create -n $GROUP -l $REGION

# create the VNET and subnet
az network vnet create -n $VNET -g $GROUP --address-prefixes 10.0.0.0/16
$ACA_SUBNET_ID = az network vnet subnet create -n $ACA_SUBNET --vnet-name $VNET -g $GROUP --address-prefixes 10.0.1.0/24 --delegations Microsoft.App/environments --query id -o tsv
$VM_SUBNET_ID = az network vnet subnet create -n $VMS_SUBNET --vnet-name $VNET -g $GROUP --address-prefixes 10.0.2.0/24 --query id -o tsv

# create NSGs, add rules, and assign to subnets
az network nsg create -n $VMS_SUBNET_NSG -g $GROUP
az network nsg create -n $ACA_SUBNET_NSG -g $GROUP
az network nsg rule create --nsg-name $VMS_SUBNET_NSG -n AllowSsh --destination-port-ranges 22 --priority 100 -g $GROUP
#az network nsg rule create --nsg-name $NSG_AKS -n AllowWeb --destination-port-ranges 80 443 --priority 101 -g $GROUP
az network vnet subnet update --vnet-name $VNET -n $VMS_SUBNET -g $GROUP --network-security-group $VMS_SUBNET_NSG

# create the VM (jumpbox) and IP
$VM_IP_ADDRESS = az network public-ip create -n $VM_IP -g $GROUP --allocation-method Static --query publicIp.ipAddress -o tsv
az network nic create -g $GROUP -n $VM_NIC --vnet-name $VNET --subnet $VM_SUBNET_ID --public-ip-address $VM_IP
az vm create -n $VM -g $GROUP --nics $VM_NIC --image Ubuntu2204 --authentication-type Password --admin-username $VM_USERNAME

# create the ACA environment
az containerapp env create -n $CONTAINER_ENV -g $GROUP -l $REGION `
    --infrastructure-subnet-resource-id $ACA_SUBNET_ID `
    --internal-only

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

# configure private DNS
$ENVIRONMENT_DEFAULT_DOMAIN = (az containerapp env show -n $CONTAINER_ENV -g $GROUP --query "properties.defaultDomain" -o tsv)
$ENVIRONMENT_STATIC_IP = (az containerapp env show -n $CONTAINER_ENV -g $GROUP --query "properties.staticIp" -o tsv)

# create the DNS zone
az network private-dns zone create -g $GROUP -n $ENVIRONMENT_DEFAULT_DOMAIN

# link the DNS zone to the vnet
az network private-dns link vnet create -n "$($VNET)-link" -g $GROUP `
    --virtual-network $VNET `
    --zone-name $ENVIRONMENT_DEFAULT_DOMAIN `
    -e true

# add "web" subdomain to point to static IP of load balancer
az network private-dns record-set a add-record -g $GROUP `
    --record-set-name "web" `
    --ipv4-address $ENVIRONMENT_STATIC_IP `
    --zone-name $ENVIRONMENT_DEFAULT_DOMAIN

# dumps
"SSH into VM: ssh $VM_USERNAME@$VM_IP_ADDRESS"
"On VM: curl https://$WEB_FQDN"