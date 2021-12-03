---
page_type: sample
languages: 
- azcli
products: 
- image-builder
- azure
- azure-virtual-machines
name: Create a Linux Azure Virtual Machine image using Azure Image Builder
author: lanicolas, jmservera
---

# Create a Linux Azure Virtual Machine image using Azure Image Builder #

[Azure Image Builder](https://docs.microsoft.com/en-us/azure/virtual-machines/image-builder-overview) is an Azure service that allows you to create predefined images with the required settings and software that meets your corporate standards, all of this being done in an automated approach that guarantees consistency and allows you to version version your images while managing them as code.

When building images with Azure Image Builder you will start with a Linux or Windows base image on top of which you will add your customizations as-code. The solution is based on [HashiCorp Packer](https://www.packer.io/) but being a managed service in Azure.

This service allows you to provide some contents and scripts to automate the Virtual Machine configuration and will perform all the necessary steps to generate, generalize and publish your virtual machine image.

Once you have an image ready you can publish it in the [Azure Shared Image Gallery](https://docs.microsoft.com/en-us/azure/virtual-machines/shared-image-galleries) or use it as a [managed image in VHD](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/capture-image) that you can later use as part of your automation.

The sample provides:

- A script to take care of all of the prerequisites to use Azure image builder:
  - Azure provider registrations
  - Resource Group creation
  - User-assigned identity and permissions.
  - Image definition and gallery settings
- A template used to configure the image, this file will:
  - Define the base image to use and VM profile, in this case it will use Ubuntu 18.04 on a Standard_D1_v2 VM.
  - Include the customization script and the commands to run it. In this sample the script will 
  - Image Gallery configuration

## Solution deployment variables

Edit the [script's](./scripts/image-builder-prerequisites.sh) environment variable section to match your deployment, provide inputs for the variables as follows: 

| Variable | Description | Example |
|---|---|---|
| rg_name | Resource group name | image_builder_rg |
| location | Main Azure Datacenter location | westeurope |
| replicated_location | Additional region to replicate the image to | northeurope |
| image_gallery | Azure Compute Image Gallery nameame of the image definition to be created  | ib_gallery |
| image_def_name | Name of the image definition | ib_imagedef |
| image_metadata | Name for the image distribution metadata reference | ib_premium |
| subscription_id | Subscription ID of the RG you will use | xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx |
| publisher | Name of the company or person that will publish the image | ib_publishing |
| sku | Define a SKU for your image | premium |
| offer | Image offer | ib_offer |

## Deploy sample

Follow these steps to deploy the sample:

```azurecli-interactive
az group create --name basic-web-app --location eastus
```

## Additional resources

- [Azure Shared Image Gallery CLI.](https://docs.microsoft.com/en-us/cli/azure/service-page/azure%20shared%20image%20gallery?view=azure-cli-latest)
- [Building a Linux VM image using Azure Image Builder](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/image-builder)
- [Image Builder template reference.](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/image-builder-json#properties-customize)

## Microsoft Open Source Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).

Resources:

- [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/)
- [Microsoft Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/)
- Contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with questions or concerns