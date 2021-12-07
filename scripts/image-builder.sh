#!/bin/bash
##################################################
##      Environment Variables Definition        ##
##################################################

rg_name=<your_resource_group_name>           # Resource group name
location=<Azure_region>                      # Main Azure Datacenter location
replicated_location=<addition_azure_region>  # Additional region to replicate the image to
image_gallery=<your_image_gallery_name>      # Azure Compute Image Gallery nameame of the image definition to be created 
image_def_name=<your_image_name>             # Name of the image definition
image_metadata=<image_dist_metadata>         # Name for the image distribution metadata reference
subscription_id=<your_subscription_id>       # Subscription ID of the RG you will use
publisher=<image_publisher>                  # Name of the company or person that will publish the image
sku=<sku_for_the_image>                      # Define a SKU for your image
offer=<name_of_your_offer>                   # Image offer


####################################################
##            Provider registration               ##
####################################################

if [ $(az provider show -n Microsoft.VirtualMachineImages -o json | grep "Registered" | wc -l) -ne 1 ]; then
 echo "Registering provider Microsoft.VirtualMachineImages"
 az provider register -n Microsoft.VirtualMachineImages
else 
 echo "Provider Microsoft.VirtualMachineImages already registered"
fi

if [ $(az provider show -n Microsoft.KeyVault -o json | grep "Registered" | wc -l) -ne 1 ]; then
 echo "Registering provider Microsoft.KeyVault"
 az provider register -n Microsoft.KeyVault
else 
 echo "Provider Microsoft.KeyVault already registered"
fi

if [ $(az provider show -n Microsoft.Compute -o json | grep "Registered" | wc -l) -ne 1 ]; then
 echo "Registering provider Microsoft.Compute"
 az provider register -n Microsoft.Compute
else 
 echo "Provider Microsoft.Compute already registered"
fi

if [ $(az provider show -n Microsoft.Storage -o json | grep "Registered" | wc -l) -ne 1 ]; then
 echo "Registering provider Microsoft.Storage"
 az provider register -n Microsoft.Storage
else 
 echo "Provider Microsoft.Storage already registered"
fi

if [ $(az provider show -n Microsoft.Network -o json | grep "Registered" | wc -l) -ne 1 ]; then
 echo "Registering provider Microsoft.Network"
 az provider register -n Microsoft.Network
else 
 echo "Provider Microsoft.Network already registered"
fi

####################################################
##             Resource Group                     ##
####################################################

echo "Creating Resource Group $rg_name in $location"
az group create -n $rg_name -l $location

####################################################
##             Identity and RBAC                  ##
####################################################

identity_name=imagebuilderuser$(date +'%s')

echo "Creating a user-identity to inject the image into the Azure Compute Gallery"

az identity create -g $rg_name -n $identity_name

identity_name_id=$(az identity show -g $rg_name -n $identity_name --query clientId -o tsv)
identity_uri=/subscriptions/$subscription_id/resourcegroups/$rg_name/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$identity_name

curl https://raw.githubusercontent.com/Azure/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleImageCreation.json -o aib_role_image.json

role_name="AzureImageBuilderImageDef"

sed -i -e "s/<subscriptionID>/$subscription_id/g" aib_role_image.json
sed -i -e "s/<rgName>/$rg_name/g" aib_role_image.json
sed -i -e "s/Azure Image Builder Service Image Creation Role/$role_name/g" aib_role_image.json

echo "Creating an Azure role definition to distribute the image to the Azure Compute Gallery"

az role definition create --role-definition ./aib_role_image.json
rm ./aib_role_image.json

sleep 30
# grant role definition to the user assigned 

echo "Granting role definition to the user assigned identity"
az role assignment create \
    --assignee $identity_name_id \
    --role $role_name \
    --scope /subscriptions/$subscription_id/resourceGroups/$rg_name


####################################################
##       Image Definition and Gallery             ##
####################################################

echo "Creating Azure Compute Gallery"
az sig create \
    -g $rg_name \
    --gallery-name $image_gallery


echo "Creating $image_def_name image definition"
az sig image-definition create \
   -g $rg_name \
   --gallery-name $image_gallery \
   --gallery-image-definition $image_def_name \
   --publisher $publisher \
   --offer $offer \
   --sku $sku \
   --os-type Linux

####################################################
##             Template Configuration             ##
####################################################

curl https://raw.githubusercontent.com/lanicolas/wordpress_imagebuilder/main/templates/wordpress_template.json -o wordpress_template.json

sed -i -e "s/<subscriptionID>/$subscription_id/g" wordpress_template.json
sed -i -e "s/<rgName>/$rg_name/g" wordpress_template.json
sed -i -e "s/<imageDefName>/$image_def_name/g" wordpress_template.json
sed -i -e "s/<sharedImageGalName>/$image_gallery/g" wordpress_template.json
sed -i -e "s/<region1>/$location/g" wordpress_template.json
sed -i -e "s/<region2>/$replicated_location/g" wordpress_template.json
sed -i -e "s/<runOutputName>/$image_metadata/g" wordpress_template.json
sed -i -e "s%<imgBuilderId>%$identity_uri%g" wordpress_template.json

az resource create \
    --resource-group $rg_name \
    --properties @wordpress_template.json \
    --is-full-object \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    -n wordpressimage

az resource invoke-action \
     --resource-group $rg_name \
     --resource-type  Microsoft.VirtualMachineImages/imageTemplates \
     -n wordpressimage \
     --action Run 

