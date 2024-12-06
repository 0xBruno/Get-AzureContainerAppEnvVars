function Get-AzureContainerAppEnvVars {
    [CmdletBinding()]
    param (
        [string]$SubscriptionId = (Get-AzContext).Subscription.Id,
        [string]$ManagementToken = (Get-AzAccessToken).Token
    )

    process {
        try {
            # Get Resource Groups
            $rgListUrl = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups?api-version=2022-01-01"
            $rgList = Invoke-RestMethod -Uri $rgListUrl -Method Get -Headers @{ 
                Authorization = "Bearer $ManagementToken" 
            }

            $envVarCollection = @()

            foreach ($resourceGroup in $rgList.value) {
                # Get Container Apps in the Resource Group
                $caListUrl = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$($resourceGroup.name)/providers/Microsoft.App/containerApps/?api-version=2022-03-01"
                $caList = Invoke-RestMethod -Uri $caListUrl -Method Get -Headers @{ 
                    Authorization = "Bearer $ManagementToken" 
                }

                foreach ($containerApp in $caList.value) {
                    $containerAppName = $containerApp.properties.template.containers.name
                    $containerAppId = $containerApp.id

                    foreach ($envVar in $containerApp.properties.template.containers.env) {
                        $envVarCollection += [PSCustomObject]@{
                            Name        = $containerAppName
                            Id          = $containerAppId
                            EnvVarName  = $envVar.Name
                            EnvVarValue = $envVar.Value
                        }
                    }
                }
            }

            return $envVarCollection
        }
        catch {
            Write-Error "Error retrieving Container App environment variables: $_"
            return $null
        }
    }
}

# Usage
$containerAppEnvVars = Get-AzureContainerAppEnvVars
$containerAppEnvVars | Format-Table Name, EnvVarName, EnvVarValue -AutoSize