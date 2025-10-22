Required Installation:
1. azcli
2. az bicep
3. vscode (Install bicep extension on vscode)
4. git

1. Login to Azure Subscription: 
command: az login --use-device-code

2. Create Azure Service Principal:
command: 
az ad sp create-for-rbac --name "jsb-devops-spn" \
  --role "Contributor" \
  --scopes "/subscriptions/$(az account show --query id -o tsv)"

3. Login with Azure Service Principal:
command: az login --service-principal -u <application-id> -p <secret-id> --tenant <tenant-id>


Bicep Commands:
az bicep build -f dev.bicep

az deployment sub create   --name test   --location eastus   --template-file ./resource-group.bicep

az deployment group create   --resource-group demo-rg   --template-file storage-account.bicep

Explanation:

--name is the deployment name.

--location is where Azure stores the deployment metadata (can be any region).

--template-file points to the generated JSON from az bicep build.


az deployment sub create \
  --name test \
  --location eastus \
  --template-file ./resource-group.json

deletion: 
az group delete --name demo-rg --yes --no-wait

az deployment sub delete --name create-rg-deployment
But note this does not delete the resources, only the deployment record.



The --location in az deployment sub create is not the location of the resources you’re creating. It’s the location where Azure stores the deployment metadata—the record of the deployment itself.

Even though your Bicep file specifies the resource group’s location (azure_resource_location = 'eastus'), Azure still needs a region to keep track of the deployment. That’s what --location is for.

It’s usually not necessary to deploy from the generated .json after a bicep build, but there are some situations where it can be useful. Here’s a breakdown:

Deploying directly from .bicep

Pros:

Simpler and cleaner—just run az deployment sub create --template-file main.bicep.

Bicep handles compiling to ARM template automatically.

Easier to maintain and update your Bicep code.

Cons:

Slightly slower at runtime because Azure CLI compiles Bicep to JSON before deployment.

Deploying from generated .json

Pros:

You have a static ARM template that you can check into source control.

Deployment doesn’t require the Bicep CLI or extension—only ARM is needed.

Useful for automation or CI/CD pipelines where you want a fixed, reproducible artifact.

Cons:

Less readable and harder to maintain because JSON is verbose.

If you change your Bicep file, you need to rebuild the JSON.

Summary:
For development and most deployments, it’s easier to deploy directly from the Bicep file. Using the .json is better for CI/CD pipelines or when you want a versioned, immutable ARM template for production.


az deployment group create \
  --resource-group demo-rg \
  --template-file dev.bicep