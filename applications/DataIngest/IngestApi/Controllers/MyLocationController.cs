using System;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using System.Threading.Tasks;
using System.Net.Http;
using System.Net.Http.Headers;
using Newtonsoft.Json;
using Microsoft.Extensions.Caching.Memory;

namespace IngestApi.Controllers
{
    [Route("controller")]
    public class MyLocationController : Controller
    {
        private string maps_account_key = string.Empty;
        private string maps_client_id = string.Empty;
        private readonly ILogger<LocationController> logger;

        private MyMemoryCache memoryCache;

        public MyLocationController(ILogger<LocationController> logger, IConfiguration configuration, MyMemoryCache memoryCache)
        {
            this.logger = logger;
            maps_account_key = Environment.GetEnvironmentVariable("azuremaps_key");
            maps_client_id = Environment.GetEnvironmentVariable("azuremaps_client_id");
            this.memoryCache = memoryCache.Cache;
        }

        [HttpGet]
        [Route("/MyLocation")]
        public async Task<ActionResult> Get()
        {

            // get the client's IP location
            var remoteIpAddress = Request.HttpContext.Connection.RemoteIpAddress.ToString();

            if (!memoryCache.TryGetValue(remoteIpAddress, out string remoteLocation))
            {
                // make a call to the Azure Maps Geolocation endpoint to get the user's current location
                var maps_endpoint = string.Format("https://atlas.microsoft.com/geolocation/ip/json?api-version=1.0&ip={0}&subscription-key={1}", remoteIpAddress, maps_account_key);

                var client = new HttpClient();
                client.DefaultRequestHeaders.Add("x-ms-client-id", maps_client_id);

                var result = await client.GetAsync(maps_endpoint);

                if (!result.IsSuccessStatusCode)
                {
                    logger.LogError("Error retrieving Geolocation: " + maps_endpoint);
                    logger.LogError("Azure maps responded with: " + result.ToString());

                    return new BadRequestResult();
                }

                dynamic response = JsonConvert.DeserializeObject(await result.Content.ReadAsStringAsync());

                remoteLocation = response.countryRegion.isoCode.ToString();

                var cacheEntryOptions = new MemoryCacheEntryOptions()
                    .SetSlidingExpiration(TimeSpan.FromDays(1));

                memoryCache.Set(remoteIpAddress, remoteLocation, cacheEntryOptions);
            }

            var myLocation = new MyLocation() { Location = remoteLocation };

            return Json(myLocation, new JsonSerializerSettings { Formatting = Formatting.Indented });


        }
    }

    public class MyLocation
    {
        public string Location { get; set; }
    }

}