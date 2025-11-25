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

Note: When the deployment is subscription-level deployment, not a resource-group-level deployment. That means you should use "az deployment sub create" instead of "az deployment group create"

Bicep
Variables (var)

Only calculated inside the Bicep file.

You cannot pass them from outside.

They are meant for internal expressions.

Parameters (param)

Only these can come from outside (CLI, param file, or pipeline).

Anything you want to externalize must be a parameter.

Bicep currently does not provide a native delete or destroy command. Resource removal must be handled manually through the Azure CLI, PowerShell, or the Azure Portal. Alternatively, you can delete the resource group that contains the deployed resources, which effectively removes all resources within it.
Microsoft Reference:
https://learn.microsoft.com/en-us/answers/questions/1128202/using-bicep-to-delete-the-resources
