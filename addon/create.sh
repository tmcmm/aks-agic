##!/usr/bin/env bash
set -e
. ./params.sh

## Create Resource Group for Cluster VNet
echo "Create RG for Cluster Vnet"
az group create \
  --name $AKS_VNET_RG \
  --location $AKS_LOCATION \
  --debug

## Create  VNet and Subnet
echo "Create Vnet and Subnet for AKS Cluster"
az network vnet create \
    -g $AKS_VNET_RG \
    -n $AKS_VNET \
    --address-prefix $AKS_VNET_CIDR \
    --subnet-name $AKS_SNET \
    --subnet-prefix $AKS_SNET_CIDR \
    --debug

## get subnet info
echo "Getting Subnet ID"
AKS_SNET_ID=$(az network vnet subnet show \
  --resource-group $AKS_VNET_RG \
  --vnet-name $AKS_VNET \
  --name $AKS_SNET \
  --query id -o tsv)

### AppGtw Client subnet Creation
echo "Create AppGtw Subnet"
az network vnet subnet create \
  -g $AKS_RG_NAME \
  --vnet-name $AKS_VNET \
  -n $APPGTW_SUBNET_NAME \
  --address-prefixes $APPGTW_SNET_CIDR \
  --debug

## get AppGtw subnet info
echo "Getting AppGtw Subnet ID"
APPGTW_SNET_ID=$(az network vnet subnet show \
  --resource-group $AKS_VNET_RG \
  --vnet-name $AKS_VNET \
  --name $APPGTW_SUBNET_NAME \
  --query id -o tsv)

### create aks cluster
echo "Creating AKS Cluster RG"
az group create \
  --name $AKS_RG_NAME \
  --location $AKS_LOCATION \
  --tags env=lab \
  --debug

echo "Creating AKS Cluster"
if [[ $HAS_AZURE_MONITOR -eq 1 && $HAS_AUTO_SCALER -eq 1 && $HAS_MANAGED_IDENTITY -eq 1 && $HAS_NETWORK_POLICY -eq 1 ]]; then
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  echo "Creating AKS with Monitor Enabled, AutoScaler, Managed Idenity and Network Policy = Azure"
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  az aks create \
  --resource-group $AKS_RG_NAME \
  --name $AKS_CLUSTER_NAME \
  --node-count $AKS_NODE_SYS_COUNT \
  --node-vm-size $AKS_NODE_SYS_SIZE \
  --location $AKS_LOCATION \
  --load-balancer-sku standard \
  --vnet-subnet-id $AKS_SNET_ID \
  --vm-set-type $AKS_VMSET_TYPE \
  --kubernetes-version $AKS_VERSION \
  --network-plugin $AKS_CNI_PLUGIN \
  --service-cidr $AKS_CLUSTER_SRV_CIDR \
  --dns-service-ip $AKS_CLUSTER_DNS \
  --docker-bridge-address $AKS_CLUSTER_DOCKER_BRIDGE \
  --api-server-authorized-ip-ranges $MY_HOME_PUBLIC_IP"/32" \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --enable-addons monitoring \
  --network-policy azure \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 3 \
  --enable-managed-identity \
  --nodepool-name sysnpool \
  --nodepool-tags "env=syspool" \
  --enable-addons ingress-appgw \
  --appgw-name $APPGTW_SUBNET_NAME \
  --appgw-subnet-id  $APPGTW_SNET_ID \
  --yes \
  --debug 
elif [[ $HAS_AZURE_MONITOR -eq 1 && $HAS_AUTO_SCALER -eq 1 && $HAS_MANAGED_IDENTITY -eq 1 && $HAS_NETWORK_POLICY -eq 0 ]]; then
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  echo "Creating AKS with Monitor Enabled, AutoScaler, Managed Idenity"
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  az aks create \
  --resource-group $AKS_RG_NAME \
  --name $AKS_CLUSTER_NAME \
  --node-count $AKS_NODE_SYS_COUNT \
  --node-vm-size $AKS_NODE_SYS_SIZE \
  --location $AKS_LOCATION \
  --load-balancer-sku standard \
  --vnet-subnet-id $AKS_SNET_ID \
  --vm-set-type $AKS_VMSET_TYPE \
  --kubernetes-version $AKS_VERSION \
  --network-plugin $AKS_CNI_PLUGIN \
  --service-cidr $AKS_CLUSTER_SRV_CIDR \
  --dns-service-ip $AKS_CLUSTER_DNS \
  --docker-bridge-address $AKS_CLUSTER_DOCKER_BRIDGE \
  --api-server-authorized-ip-ranges $MY_HOME_PUBLIC_IP"/32" \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --enable-addons monitoring \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 3 \
  --enable-managed-identity \
  --nodepool-name sysnpool \
  --nodepool-tags "env=syspool" \
  --enable-addons ingress-appgw \
  --appgw-name $APPGTW_SUBNET_NAME \
  --appgw-subnet-id  $APPGTW_SNET_ID \
  --yes \
  --debug
elif [[ $HAS_AZURE_MONITOR -eq 1 && $HAS_AUTO_SCALER -eq 1 && $HAS_MANAGED_IDENTITY -eq 0 && $HAS_NETWORK_POLICY -eq 0 ]]; then
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  echo "Creating AKS with Monitor Enabled, AutoScaler"
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  az aks create \
  --resource-group $AKS_RG_NAME \
  --name $AKS_CLUSTER_NAME \
  --service-principal $SP \
  --client-secret $SPPASS \
  --node-count $AKS_NODE_SYS_COUNT \
  --node-vm-size $AKS_NODE_SYS_SIZE \
  --location $AKS_LOCATION \
  --load-balancer-sku standard \
  --vnet-subnet-id $AKS_SNET_ID \
  --vm-set-type $AKS_VMSET_TYPE \
  --kubernetes-version $AKS_VERSION \
  --network-plugin $AKS_CNI_PLUGIN \
  --service-cidr $AKS_CLUSTER_SRV_CIDR \
  --dns-service-ip $AKS_CLUSTER_DNS \
  --docker-bridge-address $AKS_CLUSTER_DOCKER_BRIDGE \
  --api-server-authorized-ip-ranges $MY_HOME_PUBLIC_IP"/32" \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --enable-addons monitoring \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 3 \
  --nodepool-name sysnpool \
  --nodepool-tags "env=syspool" \
  --enable-addons ingress-appgw \
  --appgw-name $APPGTW_SUBNET_NAME \
  --appgw-subnet-id  $APPGTW_SNET_ID \
  --debug
elif [[ $HAS_AZURE_MONITOR -eq 1 && $HAS_AUTO_SCALER -eq 0 && $HAS_MANAGED_IDENTITY -eq 0 && $HAS_NETWORK_POLICY -eq 0 ]]; then
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  echo "Creating AKS"
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  az aks create \
  --resource-group $AKS_RG_NAME \
  --name $AKS_CLUSTER_NAME \
  --service-principal $SP \
  --client-secret $SPPASS \
  --node-count $AKS_NODE_SYS_COUNT \
  --node-vm-size $AKS_NODE_SYS_SIZE \
  --location $AKS_LOCATION \
  --load-balancer-sku standard \
  --vnet-subnet-id $AKS_SNET_ID \
  --vm-set-type $AKS_VMSET_TYPE \
  --kubernetes-version $AKS_VERSION \
  --network-plugin $AKS_CNI_PLUGIN \
  --service-cidr $AKS_CLUSTER_SRV_CIDR \
  --dns-service-ip $AKS_CLUSTER_DNS \
  --docker-bridge-address $AKS_CLUSTER_DOCKER_BRIDGE \
  --api-server-authorized-ip-ranges $MY_HOME_PUBLIC_IP"/32" \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --enable-addons monitoring \
  --nodepool-name sysnpool \
  --nodepool-tags "env=syspool" \
  --enable-addons ingress-appgw \
  --appgw-name $APPGTW_SUBNET_NAME \
  --appgw-subnet-id  $APPGTW_SNET_ID \
  --debug
elif [[ $HAS_AZURE_MONITOR -eq 0 && $HAS_AUTO_SCALER -eq 0 && $HAS_MANAGED_IDENTITY -eq 1 && $HAS_NETWORK_POLICY -eq 0 ]]; then
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  echo "Creating AKS with Managed Identity"
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  az aks create \
  --resource-group $AKS_RG_NAME \
  --name $AKS_CLUSTER_NAME \
  --node-count $AKS_NODE_SYS_COUNT \
  --node-vm-size $AKS_NODE_SYS_SIZE \
  --location $AKS_LOCATION \
  --load-balancer-sku standard \
  --vnet-subnet-id "/subscriptions/10dfa491-ff80-4d70-a4ee-9aeb49b8c00e/resourceGroups/rg-aks-agic/providers/Microsoft.Network/virtualNetworks/main-vnet-aks-agic/subnets/aks-snet-agic" \
  --vm-set-type $AKS_VMSET_TYPE \
  --kubernetes-version $AKS_VERSION \
  --network-plugin $AKS_CNI_PLUGIN \
  --service-cidr $AKS_CLUSTER_SRV_CIDR \
  --dns-service-ip $AKS_CLUSTER_DNS \
  --docker-bridge-address $AKS_CLUSTER_DOCKER_BRIDGE \
  --api-server-authorized-ip-ranges $MY_HOME_PUBLIC_IP"/32" \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --enable-addons monitoring \
  --enable-managed-identity \
  --nodepool-name sysnpool \
  --nodepool-tags "env=syspool" \
  --enable-addons ingress-appgw \
  --appgw-name $APPGTW_SUBNET_NAME \
  --appgw-subnet-id  $APPGTW_SNET_ID \
  --yes \
  --debug
elif [[ $HAS_AZURE_MONITOR -eq 0 && $HAS_AUTO_SCALER -eq 0 && $HAS_MANAGED_IDENTITY -eq 1 && $HAS_NETWORK_POLICY -eq 1 ]]; then
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  echo "Creating AKS with Managed Identityi and Network Policy = Azure" 
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  az aks create \
  --resource-group $AKS_RG_NAME \
  --name $AKS_CLUSTER_NAME \
  --node-count $AKS_NODE_SYS_COUNT \
  --node-vm-size $AKS_NODE_SYS_SIZE \
  --location $AKS_LOCATION \
  --load-balancer-sku standard \
  --vnet-subnet-id $AKS_SNET_ID \
  --vm-set-type $AKS_VMSET_TYPE \
  --kubernetes-version $AKS_VERSION \
  --network-plugin $AKS_CNI_PLUGIN \
  --service-cidr $AKS_CLUSTER_SRV_CIDR \
  --dns-service-ip $AKS_CLUSTER_DNS \
  --docker-bridge-address $AKS_CLUSTER_DOCKER_BRIDGE \
  --api-server-authorized-ip-ranges $MY_HOME_PUBLIC_IP"/32" \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --enable-addons monitoring \
  --enable-managed-identity \
  --network-policy azure \
  --nodepool-name sysnpool \
  --nodepool-tags "env=syspool" \
  --enable-addons ingress-appgw \
  --appgw-name $APPGTW_SUBNET_NAME \
  --appgw-subnet-id  $APPGTW_SNET_ID \
  --yes \
  --debug
elif [[ $HAS_AZURE_MONITOR -eq 1 && $HAS_AUTO_SCALER -eq 0 && $HAS_MANAGED_IDENTITY -eq 0 && $HAS_NETWORK_POLICY -eq 0 ]]; then
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  echo "Creating AKS with Monitor" 
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  az aks create \
  --resource-group $AKS_RG_NAME \
  --name $AKS_CLUSTER_NAME \
  --service-principal $SP \
  --client-secret $SPPASS \
  --node-count $AKS_NODE_SYS_COUNT \
  --node-vm-size $AKS_NODE_SYS_SIZE \
  --location $AKS_LOCATION \
  --load-balancer-sku standard \
  --vnet-subnet-id $AKS_SNET_ID \
  --vm-set-type $AKS_VMSET_TYPE \
  --kubernetes-version $AKS_VERSION \
  --network-plugin $AKS_CNI_PLUGIN \
  --service-cidr $AKS_CLUSTER_SRV_CIDR \
  --dns-service-ip $AKS_CLUSTER_DNS \
  --docker-bridge-address $AKS_CLUSTER_DOCKER_BRIDGE \
  --api-server-authorized-ip-ranges $MY_HOME_PUBLIC_IP"/32" \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --enable-addons monitoring \
  --nodepool-name sysnpool \
  --enable-addons ingress-appgw \
  --appgw-name $APPGTW_SUBNET_NAME \
  --appgw-subnet-id  $APPGTW_SNET_ID \
  --nodepool-tags "env=syspool" \
  --debug
else
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  echo "Creating AKS without Monitor"
  echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
  az aks create \
  --resource-group $AKS_RG_NAME \
  --name $AKS_CLUSTER_NAME \
  --service-principal $SP \
  --client-secret $SPPASS \
  --node-count $AKS_NODE_SYS_COUNT \
  --node-vm-size $AKS_NODE_SYS_SIZE \
  --location $AKS_LOCATION \
  --load-balancer-sku standard \
  --vnet-subnet-id "/subscriptions/10dfa491-ff80-4d70-a4ee-9aeb49b8c00e/resourceGroups/rg-aks-agic/providers/Microsoft.Network/virtualNetworks/main-vnet-aks-agic/subnets/aks-snet-agic" \
  --vm-set-type $AKS_VMSET_TYPE \
  --kubernetes-version $AKS_VERSION \
  --network-plugin $AKS_CNI_PLUGIN \
  --service-cidr $AKS_CLUSTER_SRV_CIDR \
  --dns-service-ip $AKS_CLUSTER_DNS \
  --docker-bridge-address $AKS_CLUSTER_DOCKER_BRIDGE \
  --api-server-authorized-ip-ranges $MY_HOME_PUBLIC_IP"/32" \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --nodepool-name sysnpool \
  --nodepool-tags "env=syspool" \
  --enable-addons ingress-appgw \
  --appgw-name $APPGTW_SUBNET_NAME \
  --appgw-subnet-id "/subscriptions/10dfa491-ff80-4d70-a4ee-9aeb49b8c00e/resourceGroups/rg-aks-agic/providers/Microsoft.Network/virtualNetworks/main-vnet-aks-agic/subnets/appgtw-agic" \
  --debug
fi

## Add User nodepooll
echo 'Add Node pool type User'
az aks nodepool add \
  -g $AKS_RG_NAME \
  -n usernpool \
  --cluster-name $AKS_CLUSTER_NAME \
  --node-osdisk-type Ephemeral \
  --node-osdisk-size $AKS_NODE_USR_DISK_SIZE \
  --kubernetes-version $AKS_VERSION \
  --tags "env=userpool" \
  --mode User \
  --node-count $AKS_NODE_USR_COUNT \
  --node-vm-size $AKS_NODE_USR_SIZE \
  --debug

### Create RG for VM
### Skip if RG already been Created
echo "Create RG if required"
if [ $(az group list -o table | awk '{print $1}' | grep "^$AKS_RG_NAME" | wc -l) -eq 1 ]; then echo "RG Already there! Continue"; else  az group create --location $AKS_LOCATION --name $AKS_RG_NAME; fi

### VM SSS Client subnet Creation
echo "Create VM Subnet"
az network vnet subnet create \
  -g $AKS_RG_NAME \
  --vnet-name $AKS_VNET \
  -n $JUMP_VM_SUBNET_NAME \
  --address-prefixes $JUMP_VM_SNET_CIDR \
  --debug


### VM NSG Create
echo "Create NSG"
az network nsg create \
  -g $AKS_RG_NAME \
  -n $JUMP_VM_NSG_NAME \
  --debug

## Public IP Create
echo "Create Public IP"
az network public-ip create --name $JUMP_VM_PUBLIC_IP_NAME --resource-group $AKS_RG_NAME --debug


## VM Nic Create
echo "Create VM Nic"
az network nic create \
  -g $AKS_RG_NAME \
  --vnet-name $AKS_VNET \
  --subnet $JUMP_VM_SUBNET_NAME \
  -n $JUMP_VM_NIC_NAME \
  --network-security-group $JUMP_VM_NSG_NAME \
  --debug 

## Attache Public IP to VM NIC
echo "Attach Public IP to VM NIC"
az network nic ip-config update \
  --name $JUMP_VM_DEFAULT_IP_CONFIG \
  --nic-name $JUMP_VM_NIC_NAME \
  --resource-group $AKS_RG_NAME \
  --public-ip-address $JUMP_VM_PUBLIC_IP_NAME \
  --debug

## Update NSG in VM Subnet
echo "Update NSG in VM Subnet"
az network vnet subnet update \
  --resource-group $AKS_RG_NAME \
  --name $JUMP_VM_SUBNET_NAME \
  --vnet-name $AKS_VNET \
  --network-security-group $JUMP_VM_NSG_NAME \
  --debug

### Create VM
echo "Create VM"
az vm create \
  --resource-group $AKS_RG_NAME \
  --authentication-type $JUMP_VM_AUTH_TYPE \
  --name $JUMP_VM_NAME \
  --computer-name $JUMP_VM_INTERNAL_NAME \
  --image $JUMP_VM_IMAGE \
  --size $JUMP_VM_SIZE \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --ssh-key-values $ADMIN_USERNAME_SSH_KEYS_PUB \
  --storage-sku $JUMP_VM_STORAGE_SKU \
  --os-disk-size-gb $JUMP_VM_OS_DISK_SIZE \
  --os-disk-name $JUMP_VM_OS_DISK_NAME \
  --nics $JUMP_VM_NIC_NAME \
  --tags $JUMP_VM_TAGS \
  --debug

echo "Sleeping 45s - Allow time for Public IP"
sleep 45

### Output Public IP of VM
VM_PUBLIC_IP=$(az network public-ip list -g $AKS_RG_NAME --query "{ip:[].ipAddress}" -o json | jq -r ".ip | @csv")
VM_PUBLIC_IP_PARSED=$(echo $VM_PUBLIC_IP | sed 's/"//g')

### Allow SSH from my Home
echo "Update VM NSG to allow SSH"
az network nsg rule create \
  --nsg-name $JUMP_VM_NSG_NAME \
  --resource-group $AKS_RG_NAME \
  --name ssh_allow \
  --priority 100 \
  --source-address-prefixes $MY_HOME_PUBLIC_IP \
  --source-port-ranges '*' \
  --destination-address-prefixes $JUMP_VM_PRIV_IP \
  --destination-port-ranges 22 \
  --access Allow \
  --protocol Tcp \
  --description "Allow from MY ISP IP"

### Input Key Fingerprint
echo "Input Key Fingerprint" 
ssh-keygen -F $VM_PUBLIC_IP_PARSED >/dev/null | ssh-keyscan -H $VM_PUBLIC_IP_PARSED >> ~/.ssh/known_hosts

echo "Sleeping 45s"
sleep 45

### Copy to VM AKS SSH Priv Key
echo "Copy to VM priv Key of AKS Cluster"
scp  -o 'StrictHostKeyChecking no' -i $SSH_PRIV_KEY $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP_PARSED:/home/$GENERIC_ADMIN_USERNAME/id_rsa

### Set Correct Permissions on Priv Key
echo "Set good Permissions on AKS Priv Key"
ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP_PARSED "chmod 700 /home/$GENERIC_ADMIN_USERNAME/id_rsa"


if [[ $HAS_ACR -eq 1 ]]; then
## Attach AKS to ACR
echo "Attacing AKS to ACR"
az aks update \
  -g $AKS_RG_NAME \
  -n $AKS_CLUSTER_NAME \
  --attach-acr $ACR_NAME \
  --debug
fi

### Get Credentials
echo "Getting Cluster Credentials"
az aks get-credentials --resource-group $AKS_RG_NAME --name $AKS_CLUSTER_NAME --overwrite-existing
echo "Public IP of the VM"
echo $VM_PUBLIC_IP_PARSED

## Deploy AGIC sample
#kubectl apply -f sample-deployment.yaml
kubectl apply -f https://raw.githubusercontent.com/Azure/application-gateway-kubernetes-ingress/master/docs/examples/aspnetapp.yaml

### Create the SSH into Node Helper file
echo "Process SSH into Node into SSH VM"
AKS_1ST_NODE_IP=$(kubectl get nodes -o=wide | awk 'FNR == 2 {print $6}')
AKS_STRING_TO_DO_SSH='ssh -o ServerAliveInterval=180 -o ServerAliveCountMax=2 -i id_rsa'
ssh -i $SSH_PRIV_KEY $GENERIC_ADMIN_USERNAME@$VM_PUBLIC_IP_PARSED echo "$AKS_STRING_TO_DO_SSH $GENERIC_ADMIN_USERNAME@$AKS_1ST_NODE_IP >> gtno.sh"




