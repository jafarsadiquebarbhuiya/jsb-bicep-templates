Required Installation:
1. azcli
2. az bicep
3. vscode 
a. Install the "Bicep" extension in VS Code to enable IntelliSense and syntax highlighting.
b. Install the "Azure Resources" extension in VS Code to sign in and manage your Azure subscription directly
c. For authentication, open the Command Palette using Shift + Ctrl + P, then select “Azure: Sign In” to connect VS Code to Azure account. 

4. git

1. Login to Azure Subscription: 
command: az login --use-device-code

2. Create Azure Service Principal:
command: 
az ad sp create-for-rbac --name "jsb-devops-spn" \
  --role "Contributor" \
  --scopes "/subscriptions/$(az account show --query id -o tsv)"
Note: 
Copy the output and save the app details now. The secret key cannot be recovered if lost.

3. Login with Azure Service Principal:
command: az login --service-principal -u application-id -p secret-id --tenant tenant-id

Bicep Build Command:
az bicep build -f dev.bicep

Note: When the deployment is subscription-level deployment, not a resource-group-level deployment. That means you should use "az deployment sub create" instead of "az deployment group create"
Command to create resource group: 
az deployment sub create   --name test   --location eastus   --template-file ./resource-group.json

Explanation:

--name is the deployment name.

--location is where Azure stores the deployment metadata (can be any region).

--template-file points to the JSON template generated from the Bicep file using az bicep build.

Note: After compiling a Bicep file, Azure generates a corresponding JSON template that the CLI uses for deployment.

Command to create storage-account:

az deployment group create   --resource-group demo-rg   --template-file storage-account.json
az deployment group create deploys resources at the resource group level.

--resource-group demo-rg specifies the target resource group where the resources will be created.

--template-file storage-account.json points to the ARM or Bicep-generated JSON template that defines the resources (for example, a storage account) to deploy.

Some conceptual notes:
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

module deployment command: 
az deployment group create \
  --resource-group demo-rg \
  --template-file dev.json

Bicep currently does not provide a native delete or destroy command. Resource removal must be handled manually through the Azure CLI, PowerShell, or the Azure Portal. Alternatively, you can delete the resource group that contains the deployed resources, which effectively removes all resources within it.
Microsoft Reference:  
https://learn.microsoft.com/en-us/answers/questions/1128202/using-bicep-to-delete-the-resources?utm_source=chatgpt.com