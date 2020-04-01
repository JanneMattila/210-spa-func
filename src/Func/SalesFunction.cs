using System;
using System.Net;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;

namespace Func
{
    public class SalesFunction
    {
        private readonly ISecurityValidator _securityValidator;

        public SalesFunction(
            ISecurityValidator securityValidator)
        {
            _securityValidator = securityValidator;
        }

        [FunctionName("Sales")]
        public async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", "delete", Route = "sales/{id?}")] HttpRequest req,
            string id,
            ILogger log)
        {
            log.LogInformation("Sales function processing request.");

            var principal = await _securityValidator.GetClaimsPrincipalAsync(req, log);
            if (principal == null)
            {
                return new UnauthorizedResult();
            }

            return req.Method switch
            {
                "GET" => Get(req, id),
                "POST" => Post(req, id),
                "DELETE" => Delete(req, id),
                _ => new StatusCodeResult((int)HttpStatusCode.NotImplemented)
            };
        }

        private static IActionResult Get(HttpRequest req, string id)
        {
            return new OkObjectResult($"sales data fetch {id}");
        }

        private static IActionResult Post(HttpRequest req, string id)
        {
            return new OkObjectResult($"sales data updated {id}");
        }

        private static IActionResult Delete(HttpRequest req, string id)
        {
            return new OkResult();
        }
    }
}
