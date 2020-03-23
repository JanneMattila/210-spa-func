using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;

namespace Func
{
    public static class MeFunction
    {
        [FunctionName("MeFunction")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = null)] HttpRequest req,
            ILogger log,
            ISecurityValidator securityValidator)
        {
            log.LogInformation("C# HTTP trigger function processed a request.");

            var principal = await securityValidator.GetClaimsPrincipalAsync(req, log);
            if (principal == null)
            {
                return new UnauthorizedResult();
            }

            return new OkObjectResult(principal
                .Claims
                .Select(c => c.Value)
                .ToList());
        }
    }
}
