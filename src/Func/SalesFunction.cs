using System.Net;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;

namespace Func
{
    public static class SalesFunction
    {
        [FunctionName("Sales")]
        public static IActionResult Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", "delete", Route = "sales/{id?}")] HttpRequest req,
            string id,
            ILogger log)
        {
            log.LogInformation("Sales function processing request.");
            return req.Method switch
            {
                "GET" => new OkObjectResult($"sales data fetch {id}"),
                "POST" => new OkObjectResult($"sales data updated {id}"),
                "DELETE" => new OkResult(),
                _ => new StatusCodeResult((int)HttpStatusCode.NotImplemented),
            };
        }
    }
}
