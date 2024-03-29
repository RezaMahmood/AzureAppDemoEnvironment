﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System.Text;
using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Producer;
using Azure.Identity;
using Newtonsoft.Json;
using Models;
using Microsoft.Extensions.Configuration;

namespace IngestAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class WeatherForecastController : ControllerBase
    {
        private readonly ILogger<WeatherForecastController> _logger;
        private string eventHubName = "";
        private string eventHubNamespace = "";


        public WeatherForecastController(ILogger<WeatherForecastController> logger, IConfiguration configuration)
        {
            _logger = logger;
            eventHubNamespace = System.Environment.GetEnvironmentVariable("eventHubNamespace");
            eventHubName = System.Environment.GetEnvironmentVariable("eventHubName");
        }

        /// <summary>
        /// Send input to EventHub using the app's managed identity or your local developer identity when using VS 2017+, VS Code or CLI: https://docs.microsoft.com/en-us/dotnet/api/overview/azure/identity-readme
        /// </summary>
        /// <param name="weatherForecast"></param>
        /// <returns></returns>
        [HttpPost]
        public async Task<ActionResult<WeatherForecast>> PostWeatherForecast(WeatherForecast weatherForecast)
        {
            await using (EventHubProducerClient producerClient = new EventHubProducerClient(eventHubNamespace, eventHubName, new DefaultAzureCredential()))
            {
                using (EventDataBatch eventBatch = await producerClient.CreateBatchAsync())
                {
                    if (!eventBatch.TryAdd(new EventData(Encoding.UTF8.GetBytes(JsonConvert.SerializeObject(weatherForecast)))))
                    {
                        _logger.LogError("Event is too large for the batch and cannot be sent");
                    }

                    try
                    {
                        await producerClient.SendAsync(eventBatch);
                        _logger.LogInformation("message sent to Event Hub");

                        return new OkResult();
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex.ToString());
                        throw;
                    }
                    finally
                    {
                        await producerClient.DisposeAsync();
                    }
                }
            }
        }
    }
}
