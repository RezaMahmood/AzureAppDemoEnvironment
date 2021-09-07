using System;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using System.Threading.Tasks;
using System.Net.Http;
using System.Net.Http.Headers;
using Newtonsoft.Json;

namespace IngestAPI.Controllers
{
    [Route("controller")]
    public class LocationController : Controller
    {
        private string maps_account_key = string.Empty;
        private string maps_client_id = string.Empty;
        private readonly ILogger<LocationController> logger;

        public LocationController(ILogger<LocationController> logger, IConfiguration configuration)
        {
            this.logger = logger;
            maps_account_key = Environment.GetEnvironmentVariable("azuremaps_key");
            maps_client_id = Environment.GetEnvironmentVariable("azuremaps_client_id");
        }

        [HttpGet]
        [Route("/Location")]
        public async Task<ActionResult> Get()
        {

            // get the client's IP location
            var remoteIpAddress = Request.HttpContext.Connection.RemoteIpAddress;

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

            return Content(string.Format("Based on your IP address ({0} it looks like your country code is {1}", remoteIpAddress, response.countryRegion.isoCode.ToString()));

        }
    }

}