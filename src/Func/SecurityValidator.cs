using System;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Microsoft.Net.Http.Headers;

namespace Func
{
    public class SecurityValidator : ISecurityValidator
    {
        public SecurityValidator()
        {
        }

        public async Task<ClaimsPrincipal> GetClaimsPrincipalAsync(HttpRequest req, ILogger log)
        {
            if (!req.Headers.ContainsKey(HeaderNames.Authorization))
            {
                // Does not contain authorization header
                return null;
            }

            var authorizationValue = req.Headers[HeaderNames.Authorization].ToString().Split(' ');
            if (authorizationValue.Length != 2 &&
                authorizationValue[0] != JwtBearerDefaults.AuthenticationScheme)
            {
                // Does not contain Bearer token
                return null;
            }

            var accessToken = authorizationValue[1];

            throw new NotImplementedException();
        }
    }
}
