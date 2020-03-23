Param (
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

# AzureAD app creation:
$identifierUri = "https://" + $AzureADAppName.ToLower().Replace(" ", "") + "." + $TenantName

$app = Get-AzADApplication -IdentifierUri  $identifierUri
$quizApp = $null

if ($app.length -eq 1)
{
    $quizApp = $app[0]
}
else
{
    #
    # Note: "New-AzADApplication" does not yet support
    # setting up "signInAudience" to "AzureADandPersonalMicrosoftAccount"
    # 
    Write-Host "Creating new AAD App: $identifierUri"
    $aadApp = New-AzADApplication `
        -AvailableToOtherTenants $true `
        -DisplayName $AzureADAppName `
        -ReplyUrls "http://localhost/signin-oidc" `
        -IdentifierUris $identifierUri
    
    New-AzADServicePrincipal -ApplicationId $aadApp.ApplicationId
    $quizApp = $aadApp
}


$replyUrls = [array]$quizApp.ReplyUrls
if ($replyUrls.length -eq 0 -or
    $replyUrls[0].StartsWith($webAppUri) -eq $false)
{
    # Update ReplyUrls to the AzureAD application
    Set-AzADApplication -ObjectId $quizApp.ObjectId -ReplyUrls "$webAppUri/signin-oidc"
}
