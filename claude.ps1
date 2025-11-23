# Variables Configuration
$subscriptionId = "9dc0b1a6-8062-4d72-b39d-7d45d1b38ab6"  # Replace with your actual subscription ID
$numberOfDeploymentsToKeep = 0  # Number of recent deployments to retain

# Set the subscription context
Write-Host "Setting subscription context to: $subscriptionId" -ForegroundColor Yellow
az account set --subscription $subscriptionId

# Check if logged in and subscription is set
$currentSub = az account show --query "id" -o tsv 2>$null
if ($LASTEXITCODE -ne 0 -or $currentSub -ne $subscriptionId) {
    Write-Error "Failed to set subscription context. Please ensure you're logged in with 'az login'"
    exit 1
}

Write-Host "Successfully set subscription context" -ForegroundColor Green

# Initialize arrays to store lock information
$allOriginalLocks = @()

Write-Host "`n=== PHASE 1: IDENTIFYING AND REMOVING RESOURCE LOCKS ===" -ForegroundColor Green

try {
    # Get all resource locks at subscription level
    Write-Host "Identifying resource locks across subscription..." -ForegroundColor Cyan
    
    # Get all locks in the subscription with detailed information
    Write-Host "Retrieving all locks in subscription..." -ForegroundColor White
    $allLocksJson = az lock list --output json 2>$null
    
    if ($allLocksJson -and $allLocksJson -ne "[]") {
        $allLocks = $allLocksJson | ConvertFrom-Json
        
        # Store original lock information for restoration
        foreach ($lock in $allLocks) {
            $lockInfo = @{
                id = $lock.id
                name = $lock.name
                level = $lock.level
                notes = $lock.notes
                resourceId = $lock.id -replace "/providers/Microsoft\.Authorization/locks/.*", ""
                scope = ""
            }
            
            # Determine the scope type
            $scope = $lock.id
            if ($scope -match "/subscriptions/[^/]+$") {
                $lockInfo.scope = "subscription"
            }
            elseif ($scope -match "/subscriptions/[^/]+/resourceGroups/[^/]+$") {
                $lockInfo.scope = "resourcegroup"
                $lockInfo.resourceGroupName = ($scope -split '/')[4]
            }
            else {
                $lockInfo.scope = "resource"
                $lockInfo.resourceGroupName = ($scope -split '/')[4]
            }
            
            $allOriginalLocks += $lockInfo
        }
        
        # Categorize for display
        $subscriptionLocks = $allOriginalLocks | Where-Object { $_.scope -eq "subscription" }
        $resourceGroupLocks = $allOriginalLocks | Where-Object { $_.scope -eq "resourcegroup" }
        $resourceLocks = $allOriginalLocks | Where-Object { $_.scope -eq "resource" }
        
        # Display summary of found locks
        $totalLocks = $allOriginalLocks.Count
        Write-Host "`nLock Summary:" -ForegroundColor Green
        Write-Host "- Subscription locks: $($subscriptionLocks.Count)" -ForegroundColor White
        Write-Host "- Resource Group locks: $($resourceGroupLocks.Count)" -ForegroundColor White
        Write-Host "- Resource locks: $($resourceLocks.Count)" -ForegroundColor White
        Write-Host "- Total locks found: $totalLocks" -ForegroundColor Yellow
        
        # Remove all locks
        Write-Host "`nRemoving all resource locks..." -ForegroundColor Cyan
        
        foreach ($lockInfo in $allOriginalLocks) {
            Write-Host "Removing lock: $($lockInfo.name) (Level: $($lockInfo.level), Scope: $($lockInfo.scope))" -ForegroundColor White
            
            # Use the lock ID for deletion
            az lock delete --ids $lockInfo.id 2>$null
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  Successfully removed: $($lockInfo.name)" -ForegroundColor Green
            } else {
                Write-Warning "Failed to remove lock: $($lockInfo.name)"
            }
        }
        
        Write-Host "Lock removal process completed!" -ForegroundColor Green
        
        # Wait a moment for Azure to propagate the lock changes
        Write-Host "Waiting for lock changes to propagate..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        
    } else {
        Write-Host "No locks found in the subscription." -ForegroundColor Yellow
        $totalLocks = 0
    }
}
catch {
    Write-Error "Error during lock identification/removal: $($_.Exception.Message)"
    exit 1
}

Write-Host "`n=== PHASE 2: DELETING OLD DEPLOYMENTS ===" -ForegroundColor Green

try {
    # Get all resource groups for deployment cleanup
    Write-Host "Retrieving resource groups..." -ForegroundColor Cyan
    $resourceGroupsJson = az group list --query "[].name" -o json 2>$null
    
    if ($resourceGroupsJson -and $resourceGroupsJson -ne "[]") {
        $resourceGroups = $resourceGroupsJson | ConvertFrom-Json
        
        foreach ($rgName in $resourceGroups) {
            Write-Host "`nProcessing deployments in Resource Group: $rgName" -ForegroundColor Cyan
            
            # Get all deployments in the resource group
            $deploymentsJson = az deployment group list --resource-group $rgName --query "[].{name:name,timestamp:properties.timestamp}" -o json 2>$null
            
            if ($deploymentsJson -and $deploymentsJson -ne "[]") {
                $deployments = $deploymentsJson | ConvertFrom-Json | Sort-Object timestamp -Descending
                
                Write-Host "Found $($deployments.Count) total deployments" -ForegroundColor White
                
                if ($deployments.Count -gt $numberOfDeploymentsToKeep) {
                    # Calculate deployments to delete
                    $deploymentsToDelete = $deployments | Select-Object -Skip $numberOfDeploymentsToKeep
                    
                    Write-Host "Keeping $numberOfDeploymentsToKeep most recent deployments" -ForegroundColor Yellow
                    Write-Host "Deleting $($deploymentsToDelete.Count) old deployments" -ForegroundColor Yellow
                    
                    # Delete old deployments
                    foreach ($deployment in $deploymentsToDelete) {
                        Write-Host "Deleting deployment: $($deployment.name) (Created: $($deployment.timestamp))" -ForegroundColor White
                        
                        az deployment group delete --resource-group $rgName --name $deployment.name --no-wait 2>$null
                        
                        if ($LASTEXITCODE -eq 0) {
                            Write-Host "  Successfully initiated deletion: $($deployment.name)" -ForegroundColor Green
                        } else {
                            Write-Warning "Failed to delete deployment: $($deployment.name) - This may be due to remaining locks or dependencies"
                        }
                    }
                } else {
                    Write-Host "No deployments to delete (total: $($deployments.Count), keeping: $numberOfDeploymentsToKeep)" -ForegroundColor Yellow
                }
            } else {
                Write-Host "No deployments found in resource group: $rgName" -ForegroundColor Yellow
            }
        }
    }
    
    # Also clean up subscription-level deployments
    Write-Host "`nProcessing subscription-level deployments..." -ForegroundColor Cyan
    $subDeploymentsJson = az deployment sub list --query "[].{name:name,timestamp:properties.timestamp}" -o json 2>$null
    
    if ($subDeploymentsJson -and $subDeploymentsJson -ne "[]") {
        $subscriptionDeployments = $subDeploymentsJson | ConvertFrom-Json | Sort-Object timestamp -Descending
        
        Write-Host "Found $($subscriptionDeployments.Count) subscription-level deployments" -ForegroundColor White
        
        if ($subscriptionDeployments.Count -gt $numberOfDeploymentsToKeep) {
            $subDeploymentsToDelete = $subscriptionDeployments | Select-Object -Skip $numberOfDeploymentsToKeep
            
            Write-Host "Deleting $($subDeploymentsToDelete.Count) old subscription deployments" -ForegroundColor Yellow
            
            foreach ($deployment in $subDeploymentsToDelete) {
                Write-Host "Deleting subscription deployment: $($deployment.name)" -ForegroundColor White
                
                az deployment sub delete --name $deployment.name --no-wait 2>$null
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  Successfully initiated deletion: $($deployment.name)" -ForegroundColor Green
                } else {
                    Write-Warning "Failed to delete subscription deployment: $($deployment.name)"
                }
            }
        } else {
            Write-Host "No subscription deployments to delete" -ForegroundColor Yellow
        }
    } else {
        Write-Host "No subscription-level deployments found" -ForegroundColor Yellow
    }
    
    # Wait for deployment deletions to complete
    if ($allOriginalLocks.Count -gt 0) {
        Write-Host "`nWaiting for deployment deletions to complete before restoring locks..." -ForegroundColor Yellow
        Start-Sleep -Seconds 15
    }
}
catch {
    Write-Error "Error during deployment cleanup: $($_.Exception.Message)"
    exit 1
}

Write-Host "`n=== PHASE 3: RESTORING RESOURCE LOCKS ===" -ForegroundColor Green

try {
    if ($allOriginalLocks.Count -gt 0) {
        Write-Host "Restoring previously identified locks..." -ForegroundColor Cyan
        
        foreach ($lockInfo in $allOriginalLocks) {
            Write-Host "Restoring lock: $($lockInfo.name) (Scope: $($lockInfo.scope))" -ForegroundColor White
            
            # Prepare notes parameter
            $notesParam = if ($lockInfo.notes -and $lockInfo.notes.Trim() -ne "") { 
                $lockInfo.notes.Trim() 
            } else { 
                "Restored by automation script" 
            }
            
            try {
                switch ($lockInfo.scope) {
                    "subscription" {
                        az lock create --name $lockInfo.name --lock-type $lockInfo.level --notes $notesParam --subscription $subscriptionId 2>$null
                    }
                    "resourcegroup" {
                        az lock create --name $lockInfo.name --lock-type $lockInfo.level --notes $notesParam --resource-group $lockInfo.resourceGroupName 2>$null
                    }
                    "resource" {
                        az lock create --name $lockInfo.name --lock-type $lockInfo.level --notes $notesParam --resource $lockInfo.resourceId 2>$null
                    }
                }
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  Successfully restored: $($lockInfo.name)" -ForegroundColor Green
                } else {
                    Write-Warning "Failed to restore lock: $($lockInfo.name)"
                }
            }
            catch {
                Write-Warning "Exception restoring lock $($lockInfo.name): $($_.Exception.Message)"
            }
        }
        
        Write-Host "Lock restoration process completed!" -ForegroundColor Green
    } else {
        Write-Host "No locks to restore." -ForegroundColor Yellow
    }
}
catch {
    Write-Error "Error during lock restoration: $($_.Exception.Message)"
    Write-Warning "Some locks may not have been restored. Please review manually."
}

Write-Host "`n=== SCRIPT EXECUTION COMPLETED ===" -ForegroundColor Green
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "- Original locks found: $($allOriginalLocks.Count)" -ForegroundColor White
Write-Host "- Deployments kept per resource group: $numberOfDeploymentsToKeep" -ForegroundColor White

# Verify locks are restored
Write-Host "`nVerifying restored locks..." -ForegroundColor Cyan
$finalLocksJson = az lock list --output json 2>$null
if ($finalLocksJson -and $finalLocksJson -ne "[]") {
    $finalLocks = $finalLocksJson | ConvertFrom-Json
    Write-Host "Current total locks in subscription: $($finalLocks.Count)" -ForegroundColor Yellow
    
    if ($finalLocks.Count -eq $allOriginalLocks.Count) {
        Write-Host "✅ All locks successfully restored!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Lock count mismatch. Original: $($allOriginalLocks.Count), Current: $($finalLocks.Count)" -ForegroundColor Yellow
        Write-Host "Please verify locks manually." -ForegroundColor Yellow
    }
} else {
    if ($allOriginalLocks.Count -eq 0) {
        Write-Host "✅ No locks to restore - status correct!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  No locks currently in subscription, but $($allOriginalLocks.Count) were expected to be restored" -ForegroundColor Yellow
    }
}

Write-Host "`n🎉 Script execution completed successfully!" -ForegroundColor Green
