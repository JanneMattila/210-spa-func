using System.Security.Claims;

namespace Func
{
    public static class ClaimsPrincipalExtensions
    {
        public static bool HasPermission(this ClaimsPrincipal principal, string permission)
        {
            return false;
        }
    }
}
