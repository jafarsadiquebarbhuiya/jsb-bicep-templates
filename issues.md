Issue: az deployment group create   --resource-group demo-rg   --template-file dev.bicep   --parameters dev.parameters.json
The content for this response was already consumed
$ az deployment group list --resource-group demo-rg -o table
Name                         State      Timestamp                         Mode         ResourceGroup
---------------------------  ---------  --------------------------------  -----------  ---------------
Microsoft.AutomationAccount  Succeeded  2025-11-23T06:29:12.462186+00:00  Incremental  demo-rg
Because the earlier deployment got stuck, you need to delete the partial deployment first:

To delete a deployment name:
az deployment group delete \
  --resource-group demo-rg \
  --name <deploymentName>