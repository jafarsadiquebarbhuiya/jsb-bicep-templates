# -----------------------------------------------------------------------------
# Azure Deployment Cleanup & Lock Management Script
# -----------------------------------------------------------------------------

# --- Variables ---
$SubscriptionId = "9dc0b1a6-8062-4d72-b39d-7d45d1b38ab6"
$DeploymentsToKeep = 0  # Number of recent deployments to keep per Resource Group

# -----------------------------------------------------------------------------
# 1. Set Context
# -----------------------------------------------------------------------------
try {
    Write-Output "Setting context to Subscription: $SubscriptionId"
    # Ensure we are logged in and selecting the specific subscription
    $context = Set-AzContext -SubscriptionId $SubscriptionId -ErrorAction Stop
    Write-Output "Successfully set context to: $($context.Subscription.Name)"
}
catch {
    Write-Error "CRITICAL ERROR: Failed to set subscription context."
    Write-Error "System Error Message: $_"
    Write-Error "Fix: Please run 'Connect-AzAccount' in this terminal before running the script."
    exit
}

# -----------------------------------------------------------------------------
# 2. Identify and Remove Resource Locks
# -----------------------------------------------------------------------------
Write-Output "-----------------------------------------------"
Write-Output "--- Phase 1: Analyzing and Removing Locks ---"
Write-Output "-----------------------------------------------"

# Get all locks in the subscription
$allLocks = Get-AzResourceLock

# Initialize an array to store lock details for restoration
$locksBackup = @()

if ($allLocks) {
    foreach ($lock in $allLocks) {
        # Store lock properties object for restoration
        $lockDetails = [PSCustomObject]@{
            Name  = $lock.Name
            Level = $lock.Level
            Scope = $lock.ResourceId
            Notes = $lock.Notes
        }
        $locksBackup += $lockDetails

        Write-Output "Removing Lock: $($lock.Name) at scope: $($lock.ResourceId)"
        
        # Remove the lock
        try {
            Remove-AzResourceLock -LockId $lock.LockId -Force -ErrorAction Stop
        }
        catch {
            Write-Warning "Could not remove lock $($lock.Name). Error: $_"
        }
    }
    Write-Output "Total locks backed up for restoration: $($locksBackup.Count)"
}
else {
    Write-Output "No resource locks found in this subscription."
}

# -----------------------------------------------------------------------------
# 3. Delete Old Deployments
# -----------------------------------------------------------------------------
Write-Output "-----------------------------------------------"
Write-Output "--- Phase 2: Cleaning Old Deployments ---"
Write-Output "-----------------------------------------------"

# Get all Resource Groups
$resourceGroups = Get-AzResourceGroup

foreach ($rg in $resourceGroups) {
    # Get deployments for this RG, sorted by Timestamp (Newest first)
    $deployments = Get-AzResourceGroupDeployment -ResourceGroupName $rg.ResourceGroupName | Sort-Object Timestamp -Descending

    if ($deployments.Count -gt $DeploymentsToKeep) {
        Write-Output "Processing RG: $($rg.ResourceGroupName) | Found $($deployments.Count) deployments."
        
        # Select deployments to delete (skip the newest ones defined by variable)
        $deploymentsToDelete = $deployments | Select-Object -Skip $DeploymentsToKeep

        foreach ($dep in $deploymentsToDelete) {
            Write-Output " -> Deleting Deployment: $($dep.DeploymentName) (Date: $($dep.Timestamp))"
            
            # Delete the deployment
            Remove-AzResourceGroupDeployment -ResourceGroupName $rg.ResourceGroupName -Name $dep.DeploymentName -Force -ErrorAction SilentlyContinue
        }
    }
    else {
        # Optional: Comment this out if you want less noise in the logs
        # Write-Output "Skipping RG: $($rg.ResourceGroupName) (Count: $($deployments.Count) <= Limit: $DeploymentsToKeep)"
    }
}

# -----------------------------------------------------------------------------
# 4. Restore Resource Locks
# -----------------------------------------------------------------------------
Write-Output "-----------------------------------------------"
Write-Output "--- Phase 3: Restoring Locks ---"
Write-Output "-----------------------------------------------"

if ($locksBackup.Count -gt 0) {
    foreach ($backup in $locksBackup) {
        Write-Output "Restoring Lock: $($backup.Name) ($($backup.Level))"
        
        try {
            # Re-create the lock using the stored scope
            New-AzResourceLock -LockName $backup.Name `
                -LockLevel $backup.Level `
                -Scope $backup.Scope `
                -Notes $backup.Notes `
                -Force `
                -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Warning "Failed to restore lock '$($backup.Name)' on scope '$($backup.Scope)'. Error: $_"
        }
    }
    Write-Output "Lock restoration process completed."
}
else {
    Write-Output "No locks to restore."
}

Write-Output "--- Script Execution Finished ---"
