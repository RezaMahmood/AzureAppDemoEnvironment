using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Azure.Messaging.EventHubs;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Models;
using Azure.Identity;
using Microsoft.Azure.Cosmos;

namespace DataIngest
{
    public static class EventHubIngestPump
    {
        [FunctionName("EventHubIngestPump")]
        public static async Task Run(
       [EventHubTrigger("%EventHubName%", Connection = "EventHubConnection")] EventData[] events,
       ILogger log)
        {
            var exceptions = new List<Exception>();

            // instantiate cosmosdb client
            var cosmosDatabase = System.Environment.GetEnvironmentVariable("CosmosDatabaseId");
            var cosmosContainer = System.Environment.GetEnvironmentVariable("CosmosContainerId");
            var cosmosClient = new CosmosClient(System.Environment.GetEnvironmentVariable("CosmosAccountUri"), new DefaultAzureCredential());
            var container = cosmosClient.GetContainer(cosmosDatabase, cosmosContainer);

            foreach (var eventData in events)
            {
                try
                {
                    var messageBody = JsonConvert.DeserializeObject<WeatherForecast>(Encoding.UTF8.GetString(eventData.EventBody));

                    // Replace these two lines with your processing logic.
                    log.LogInformation($"C# Event Hub trigger function processed a message: {messageBody}");

                    messageBody.id = System.Guid.NewGuid().ToString();
                    //save event to cosmos
                    await container.CreateItemAsync(messageBody, new PartitionKey(messageBody.id));

                }
                catch (Exception e)
                {
                    // We need to keep processing the rest of the batch - capture this exception and continue.
                    // Also, consider capturing details of the message that failed processing so it can be processed again later.
                    exceptions.Add(e);
                }
            }

            // Once processing of the batch is complete, if any messages in the batch failed processing throw an exception so that there is a record of the failure.

            if (exceptions.Count > 1)
                throw new AggregateException(exceptions);

            if (exceptions.Count == 1)
                throw exceptions.Single();
        }
    }
}
