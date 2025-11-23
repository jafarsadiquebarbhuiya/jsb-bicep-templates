# Requires: Az.Accounts, Az.Resources
# Connect-AzAccount # Uncomment if not already logged in

# ==============================
# Variables
# ==============================
$SubscriptionId = "9dc0b1a6-8062-4d72-b39d-7d45d1b38ab6"   # e.g. "00000000-0000-0000-0000-000000000000"
$WhatIf = $false                             # Set $true to simulate only
$VerboseLogging = $true

# ==============================
# Select Subscription
# ==============================
if ($VerboseLogging) { Write-Host "Setting context to subscription: $SubscriptionId" -ForegroundColor Cyan }
Set-AzContext -Subscription $SubscriptionId | Out-Null

# ==============================
# 1. Get all locks in subscription
# ==============================
if ($VerboseLogging) { Write-Host "Retrieving all locks in subscription..." -ForegroundColor Cyan }

# This gets locks at all scopes under the subscription
$allLocks = Get-AzResourceLock -AtScope "/subscriptions/$SubscriptionId"

if (-not $allLocks) {
    Write-Host "No resource locks found in subscription." -ForegroundColor Yellow
    return
}

# Filter to only resource-level locks (exclude subscription- and RG-level if desired)
# Comment/uncomment depending on what you want:
$resourceLevelLocks = $allLocks | Where-Object {
    $_.ResourceId -match "^/subscriptions/.*/resourceGroups/.*/providers/.+/.+"
}

if (-not $resourceLevelLocks) {
    Write-Host "No resource-level locks found (only subscription/RG-level locks exist)." -ForegroundColor Yellow
    return
}

if ($VerboseLogging) {
    Write-Host "Total locks found: $($allLocks.Count)" -ForegroundColor Green
    Write-Host "Resource-level locks to process: $($resourceLevelLocks.Count)" -ForegroundColor Green
}

# ==============================
# Group locks by ResourceId
# ==============================
$locksByResource = $resourceLevelLocks | Group-Object -Property ResourceId

if ($VerboseLogging) {
    Write-Host "Number of locked resources: $($locksByResource.Count)" -ForegroundColor Green
}

# Variable to track how many locks we removed
$TotalLocksRemoved = 0

# To store original lock definitions so we can recreate them
$LocksToRecreate = @()

# ==============================
# Helper: Remove locks for a given resource
# ==============================
function Remove-ResourceLocks {
    param(
        [Parameter(Mandatory = $true)]
        [string] $ResourceId,
        [Parameter(Mandatory = $true)]
        [array] $Locks
    )

    foreach ($lock in $Locks) {
        if ($WhatIf) {
            Write-Host "[WhatIf] Would remove lock '$($lock.Name)' on '$ResourceId'" -ForegroundColor Yellow
        }
        else {
            Write-Host "Removing lock '$($lock.Name)' on '$ResourceId'" -ForegroundColor Yellow
            Remove-AzResourceLock -LockId $lock.LockId -Force -ErrorAction Stop
        }
        $script:TotalLocksRemoved++
    }
}

# ==============================
# Helper: Recreate locks for a given resource
# ==============================
function Recreate-ResourceLocks {
    param(
        [Parameter(Mandatory = $true)]
        [string] $ResourceId,
        [Parameter(Mandatory = $true)]
        [array] $LockDefinitions
    )

    foreach ($lockDef in $LockDefinitions) {
        if ($WhatIf) {
            Write-Host "[WhatIf] Would recreate lock '$($lockDef.Name)' on '$ResourceId' (Level: $($lockDef.Level))" -ForegroundColor Yellow
        }
        else {
            Write-Host "Recreating lock '$($lockDef.Name)' on '$ResourceId' (Level: $($lockDef.Level))" -ForegroundColor Yellow
            New-AzResourceLock `
                -LockName $lockDef.Name `
                -LockLevel $lockDef.Level `
                -LockNotes $lockDef.Notes `
                -Scope $ResourceId | Out-Null
        }
    }
}

# ==============================
# Helper: Delete deployments for a resource
# ==============================
function Remove-ResourceDeployments {
    param(
        [Parameter(Mandatory = $true)]
        [string] $ResourceId
    )

    # Extract Resource Group name from ResourceId:
    # /subscriptions/{subId}/resourceGroups/{rgName}/providers/...
    $rgName = ($ResourceId -split "/")[4]

    if (-not $rgName) {
        Write-Host "Could not parse resource group name from ResourceId: $ResourceId" -ForegroundColor Red
        return
    }

    if ($VerboseLogging) {
        Write-Host "Looking for deployments in resource group '$rgName' for resource '$ResourceId'" -ForegroundColor Cyan
    }

    # Get all deployments in the resource group
    $deployments = Get-AzResourceGroupDeployment -ResourceGroupName $rgName -ErrorAction SilentlyContinue

    if (-not $deployments) {
        if ($VerboseLogging) {
            Write-Host "No deployments found in RG '$rgName'." -ForegroundColor DarkYellow
        }
        return
    }

    # You can either:
    # 1) delete ALL deployments in the RG, or
    # 2) try to filter by those that might be relevant to this resource.
    #
    # Here, we delete ALL RG deployments – adjust if you want narrower targeting.
    foreach ($dep in $deployments) {
        if ($WhatIf) {
            Write-Host "[WhatIf] Would remove deployment '$($dep.DeploymentName)' in RG '$rgName'" -ForegroundColor Yellow
        }
        else {
            Write-Host "Removing deployment '$($dep.DeploymentName)' in RG '$rgName'" -ForegroundColor Yellow
            Remove-AzResourceGroupDeployment -ResourceGroupName $rgName -Name $dep.DeploymentName -Force -ErrorAction Stop
        }
    }
}

# ==============================
# Main processing
# ==============================
foreach ($group in $locksByResource) {
    $resourceId = $group.Name
    $locks = $group.Group

    Write-Host "Processing resource: $resourceId" -ForegroundColor Cyan

    # Cache lock definitions to recreate later
    $originalLockDefs = @()
    foreach ($lock in $locks) {
        $originalLockDefs += [PSCustomObject]@{
            Name  = $lock.Name
            Level = $lock.Level
            Notes = $lock.Notes
        }
    }

    # Step 1: Remove locks
    Remove-ResourceLocks -ResourceId $resourceId -Locks $locks

    # Step 2: Delete deployments for the unlocked resource
    Remove-ResourceDeployments -ResourceId $resourceId

    # Step 3: Recreate locks
    Recreate-ResourceLocks -ResourceId $resourceId -LockDefinitions $originalLockDefs

    # Store for record if needed
    $LocksToRecreate += [PSCustomObject]@{
        ResourceId = $resourceId
        Locks      = $originalLockDefs
    }

    Write-Host "Finished processing resource: $resourceId" -ForegroundColor Green
    Write-Host "------------------------------------------------------------"
}

# ==============================
# Summary
# ==============================
Write-Host ""
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "Total resource-level locks processed: $($resourceLevelLocks.Count)"
Write-Host "Total locks removed (and re-created): $TotalLocksRemoved"

if ($WhatIf) {
    Write-Host "NOTE: Script was run in WhatIf mode. No actual changes were made." -ForegroundColor Yellow
}
``_
