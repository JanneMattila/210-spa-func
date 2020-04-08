Param (
    [Parameter(HelpMessage="Deployment environment name")] 
    [string] $EnvironmentName = "local",

    [Parameter(HelpMessage="SPA Reader address root uri")] 
    [string] $SPAReaderUri = "https://localhost:44387/",
    
    [Parameter(HelpMessage="SPA Writer address root uri")] 
    [string] $SPAWriterUri = "https://localhost:44388/",

    [Parameter(HelpMessage="Deployment target resource group")] 
    [string] $ResourceGroupName = "rg-spafunc-local",
    
    [Parameter(HelpMessage="Azure Functions root uri")] 
    [string] $FunctionsUri,
    
    [Parameter(HelpMessage="Deployment target storage account name")] 
    [string] $WebStorageName,

    [Parameter(HelpMessage="App root folder path to publish e.g. ..\src\AmazerrrWeb\wwwroot\")] 
    [string] $AppRootFolder
)

$ErrorActionPreference = "Stop"

# Use existing Azure context to login to Azure AD
$context = Get-AzContext
$accountId = $context.Account.Id
$tenant = $context.Tenant.TenantId
$scope = "https://graph.windows.net" # Azure AD Graph API
$dialog = [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never

$azureSession = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $tenant, $null, $dialog, $null, $scope)

# Azure AD Graph API token
$accessToken = $azureSession.AccessToken

$aadInstalledModule = Get-Module -Name "AzureAD" -ListAvailable
if ($null -eq $aadInstalledModule)
{
    Install-Module AzureAD -Scope CurrentUser
}
else
{
    Import-Module AzureAD
}

Connect-AzureAD -AadAccessToken $accessToken -AccountId $accountId -TenantId $tenant

######################
# Setup functions app:
# - Expose API "Sales.Read"
# - Expose API "Sales.ReadWrite"
$permissions = New-Object System.Collections.Generic.List[Microsoft.Open.AzureAD.Model.OAuth2Permission]

# Known identifiers of Microsoft Graph API
$microsoftGraphAPI = "00000003-0000-0000-c000-000000000000"
$userRead = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # "User.Read"

# Custom identifiers for our APIs
$permissionSalesRead = "d2dc4339-3161-4d78-a579-8b50f4c4da39" # "Sales.Read"
$permissionSalesReadWrite = "39579f07-da63-4735-850d-f802b0d08057" # "Sales.ReadWrite"

$readPermission = New-Object Microsoft.Open.AzureAD.Model.OAuth2Permission
$readPermission.Id = $permissionSalesRead
$readPermission.Value = "Sales.Read"
$readPermission.Type = "User"
$readPermission.AdminConsentDisplayName = "Admin consent for granting read access to sales data"
$readPermission.AdminConsentDescription = "Admin consent for granting read access to sales data"
$readPermission.UserConsentDisplayName = "Read access to sales data"
$readPermission.UserConsentDescription = "Read access to sales data"
$permissions.Add($readPermission)

$readWritePermission = New-Object Microsoft.Open.AzureAD.Model.OAuth2Permission
$readWritePermission.Id = $permissionSalesReadWrite
$readWritePermission.Value = "Sales.ReadWrite"
$readWritePermission.Type = "User"
$readWritePermission.AdminConsentDisplayName = "Admin consent for granting read-write access to sales data"
$readWritePermission.AdminConsentDescription = "Admin consent for granting read-write access to sales data"
$readWritePermission.UserConsentDisplayName = "Read-write access to sales data"
$readWritePermission.UserConsentDescription = "Read-write access to sales data"
$permissions.Add($readWritePermission)

$apiApplication = New-AzureADApplication -DisplayName "SPA-FUNC API $EnvironmentName" `
    -IdentifierUris "api://spa-func.$EnvironmentName" `
    -PublicClient $false `
    -Oauth2Permissions $permissions
$apiApplication

$spn = New-AzureADServicePrincipal -AppId $apiApplication.AppId

###########################
# Setup SPASalesReader app:
$readerAccesses = New-Object System.Collections.Generic.List[Microsoft.Open.AzureAD.Model.RequiredResourceAccess]

# API permission for "User.Read" in Microsoft Graph
$readerUserRead = New-Object Microsoft.Open.AzureAD.Model.ResourceAccess
$readerUserRead.Id = $userRead # "User.Read"
$readerUserRead.Type = "Scope"

$readerGraph = New-Object Microsoft.Open.AzureAD.Model.RequiredResourceAccess
$readerGraph.ResourceAppId = $microsoftGraphAPI # "Microsoft Graph API"
$readerGraph.ResourceAccess = New-Object System.Collections.Generic.List[Microsoft.Open.AzureAD.Model.ResourceAccess]
$readerGraph.ResourceAccess.Add($readerUserRead)

# API permission for "Sales.Read" in SPA-FUNC
$readerSalesRead = New-Object Microsoft.Open.AzureAD.Model.ResourceAccess
$readerSalesRead.Id = $readPermission.Id # "Sales.Read"
$readerSalesRead.Type = "Scope"

$readerApi = New-Object Microsoft.Open.AzureAD.Model.RequiredResourceAccess
$readerApi.ResourceAppId = $apiApplication.AppId # "SPA FUNC"
$readerApi.ResourceAccess = New-Object System.Collections.Generic.List[Microsoft.Open.AzureAD.Model.ResourceAccess]
$readerApi.ResourceAccess.Add($readerSalesRead)

# Add required accesses
$readerAccesses.Add($readerGraph)
$readerAccesses.Add($readerApi)

$readerApplication = New-AzureADApplication -DisplayName "SPA-FUNC Sales Reader $EnvironmentName" `
    -Oauth2AllowImplicitFlow $true `
    -Homepage $SPAReaderUri `
    -ReplyUrls $SPAReaderUri `
    -RequiredResourceAccess $readerAccesses
