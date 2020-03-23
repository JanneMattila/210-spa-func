using System;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authentication.OpenIdConnect;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Protocols;
using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using Microsoft.IdentityModel.Tokens;
using Microsoft.Net.Http.Headers;

namespace Func
{
    public class SecurityValidator : ISecurityValidator
    {
        private readonly SecurityValidatorOptions _securityValidatorOptions;
        private TokenValidationParameters _tokenValidationParameters;

        public SecurityValidator(SecurityValidatorOptions securityValidatorOptions)
        {
            _securityValidatorOptions = securityValidatorOptions;
        }

        public async Task InitializeAsync()
        {
            var configurationManager = new ConfigurationManager<OpenIdConnectConfiguration>(
                $"{_securityValidatorOptions.Authority}/.well-known/openid-configuration",
                new OpenIdConnectConfigurationRetriever());

            var configuration = await configurationManager.GetConfigurationAsync();
            _tokenValidationParameters = new TokenValidationParameters
            {
                ValidAudiences = new[]
                {
                    _securityValidatorOptions.Audience,
                    _securityValidatorOptions.ClientId
                },
                ValidIssuers = _securityValidatorOptions.ValidIssuers,
                IssuerSigningKeys = configuration.SigningKeys
            };
        }

        public ClaimsPrincipal GetClaimsPrincipal(HttpRequest req, ILogger log)
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
            var tokenHandler = new JwtSecurityTokenHandler();

            try
            {
                var claimsPrincipal = tokenHandler.ValidateToken(
                    accessToken, 
                    _tokenValidationParameters, 
                    out SecurityToken securityToken);
                return claimsPrincipal;
            }
            catch (Exception ex)
            {
                log.LogError(ex, "Token validation failed");
                return null;
            }
        }
    }
}
