# Learnings
## Things I've learned putting the environment together (as of 02.09.21)

- [Github Codespaces](https://github.com/features/codespaces)
- [Private Endpoint with Terraform](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint)
- [RBAC for Cosmos DB Data plane](https://docs.microsoft.com/en-us/azure/cosmos-db/how-to-setup-rbac)
    - Portal does not support data plane RBAC yet
    - Terraform does not support data plane RBAC yet
    - Data plane RBAC supported through AZ Cli, Powershell and ARM
    - Disable local auth only through ARM
- [Azure Functions Event Hub trigger with Managed Identity](https://docs.microsoft.com/en-us/azure/azure-functions/functions-bindings-event-hubs#event-hubs-extension-5x-and-higher) and [Github sample](https://github.com/Azure/azure-sdk-for-net/tree/Microsoft.Azure.WebJobs.Extensions.EventHubs_5.0.0-beta.7/sdk/eventhub/Microsoft.Azure.WebJobs.Extensions.EventHubs)
- Github Actions
    - App Service specific action
    - Triggering on specific path changes
    - building a specific path project
    - Terraform idiosynchracies with authentication
- [Azure Functions Binding Expressions](https://docs.microsoft.com/en-us/azure/azure-functions/functions-bindings-expressions-patterns#binding-expressions---app-settings)
- Github az cli action runs in a container so using that to get environment variables to pass to other actions won't work.  Using Keyvault actions works and is easier to configure. [Always check Github Actions for Azure](https://docs.microsoft.com/en-us/azure/developer/github/github-actions)
