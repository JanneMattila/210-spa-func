using System.Collections.Generic;

namespace Func
{
    public class SecurityValidatorOptions
    {
        public string Authority { get; set; }
        public string AadInstance { get; set; }
        public string Audience { get; set; }
        public string ClientId { get; set; }
        public string TenantId { get; set; }
        public List<string> ValidIssuers { get; set; }
    }
}
