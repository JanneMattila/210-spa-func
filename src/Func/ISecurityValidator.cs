using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;

namespace Func
{
    public interface ISecurityValidator
    {
        ClaimsPrincipal GetClaimsPrincipal(HttpRequest req, ILogger log);
    }
}
