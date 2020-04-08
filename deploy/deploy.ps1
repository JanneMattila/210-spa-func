Param (
    [Parameter(HelpMessage="Deployment target resource group")] 
    [string] $ResourceGroupName = "rg-spafunc-local",

    [Parameter(HelpMessage="Deployment target resource group location")] 
    [string] $Location = "North Europe",

    [Parameter(HelpMessage="App root folder path to publish e.g. ..\src\SpaSalesReader\wwwroot\")] 
    [string] $AppRootFolderReader,

    [Parameter(HelpMessage="App root folder path to publish e.g. ..\src\SpaSalesWriter\wwwroot\")] 
    [string] $AppRootFolderWriter,

    [string] $Template = "$PSScriptRoot\azuredeploy.json",
    [string] $TemplateParameters = "$PSScriptRoot\azuredeploy.parameters.json"
)

$ErrorActionPreference = "Stop"

$date = (Get-Date).ToString("yyyy-MM-dd-HH-mm-ss")
$deploymentName = "Local-$date"

if ([string]::IsNullOrEmpty($env:BUILD_BUILDNUMBER))
{
    Write-Host (@"
Not executing inside Azure DevOps Release Management.
Make sure you have done "Login-AzAccount" and
"Select-AzSubscription -SubscriptionName name"
so that script continues to work correctly for you.
"@)
}
else
{
    $deploymentName = $env:BUILD_BUILDNUMBER
}

if ($null -eq (Get-AzResourceGroup -Name $ResourceGroupName -Location $Location -ErrorAction SilentlyContinue))
{
    Write-Warning "Resource group '$ResourceGroupName' doesn't exist and it will be created."
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Verbose
}

# Additional parameters that we pass to the template deployment
$additionalParameters = New-Object -TypeName hashtable
#$additionalParameters['name'] = $value

$result = New-AzResourceGroupDeployment `
    -DeploymentName $deploymentName `
    -ResourceGroupName $ResourceGroupName `
    -TemplateFile $Template `
    -TemplateParameterFile $TemplateParameters `
    @additionalParameters `
    -Mode Complete -Force `
    -Verbose

if ($null -eq $result.Outputs.webStorageNameReader -or
    $null -eq $result.Outputs.webStorageNameWriter -or
    $null -eq $result.Outputs.webAppName -or
    $null -eq $result.Outputs.webAppUri)
{
    Throw "Template deployment didn't return web app information correctly and therefore deployment is cancelled."
}

$result

$webStorageNameReader = $result.Outputs.webStorageNameReader.value
$webStorageNameWriter = $result.Outputs.webStorageNameWriter.value
$webAppName = $result.Outputs.webAppName.value
$webAppUri = $result.Outputs.webAppUri.value

# Setup static website for SPA Reader
$webReaderStorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -AccountName $webStorageNameReader
Enable-AzStorageStaticWebsite -Context $webReaderStorageAccount.Context -IndexDocument index.html -ErrorDocument404Path 404.html
$webReaderStorageUri = $webReaderStorageAccount.PrimaryEndpoints.Web
Write-Host "Static website endpoint for Reader: $webReaderStorageUri"

# Setup static website for SPA Writer
$webWriterStorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -AccountName $webStorageNameWriter
Enable-AzStorageStaticWebsite -Context $webWriterStorageAccount.Context -IndexDocument index.html -ErrorDocument404Path 404.html
$webWriterStorageUri = $webWriterStorageAccount.PrimaryEndpoints.Web
Write-Host "Static website endpoint for Writer: $webWriterStorageUri"

# Publish variable to the Azure DevOps agents so that they
# can be used in follow-up tasks such as application deployment
Write-Host "##vso[task.setvariable variable=Custom.WebAppName;]$webAppName"
Write-Host "##vso[task.setvariable variable=Custom.WebAppUri;]$webAppUri"

if (![string]::IsNullOrEmpty($AppRootFolderReader))
{
    . $PSScriptRoot\deploy_web.ps1 `
        -ResourceGroupName $ResourceGroupName `
        -FunctionsUri $webAppUri `
        -WebStorageName $webStorageAccount.StorageAccountName `
        -AppRootFolder $AppRootFolderReader
}
