# Find out if we are on a VM that has a temporary drive can be moved
# e.g. DS1 series has a temp drive, while DS2 series does not
function hasTemporaryDrive {
  $pageFileDrive = Get-CimInstance -ClassName win32_pagefilesetting | Select-Object -Property Name -ExpandProperty Name
  if ($pageFileDrive -ieq 'C:\') {
    # Page file is on C: drive so unsupported sku
    return $false
  } else {
    # Page file not on C: drive so using sku with temporary drives
    return $true
  }
}

function Get-TargetResource 
{    
  [OutputType([System.Collections.Hashtable])] 
  param 
  (   
    [Parameter(Mandatory)] 
    [string]$DriveLetter
  )
  
  Write-Verbose -Message 'Retrieving Pagefile settings'  
  $pagefile = Get-CimInstance win32_pagefilesetting
  if ($pagefile -ne $null) {
    $pagefile = $pagefile.Name.ToLower()  
  }

  $returnValue = @{ 
    DriveLetter = [string]$pagefile
  }
         
  return $returnValue
} 

function Set-TargetResource 
{   
  param 
  ( 
    [Parameter(Mandatory)] 
    [string]$DriveLetter   
  ) 

  # Check to see if we are on a sku that can have drive re-mapped
  if(hasTemporaryDrive -eq $false) {
    Write-Verbose "Not-supported sku for drive re-mapping"
    return $true
  }
  
  if ($DriveLetter.Length -gt 1){$DriveLetter = $DriveLetter[0]}
  $CurrentValue = (Get-TargetResource @PSBoundParameters).DriveLetter
  $CurrentDriveLetter = (Get-CimInstance -Class Win32_LogicalDisk -Filter "VolumeName = 'Temporary Storage'").DeviceID
  $CurrentDrive = Get-CimInstance -Class win32_volume -Filter "DriveLetter = '$($CurrentDriveLetter)'"

  if (((get-ciminstance win32_volume).driveletter -contains "$($DriveLetter):") -and ($CurrentDriveLetter -ne "$($DriveLetter):")){
    throw "Driveletter $DriveLetter is already in use!"
  }

  if ($currentvalue -ne $null) {
    $pagefiles = Get-CimInstance win32_pagefilesetting
    foreach ($pagefile in $pagefiles) {
        Remove-CimInstance -InputObject $pagefile
    }
    $global:DSCMachineStatus = 1 
  }

  else {
    $DriveLetter = $DriveLetter + ":"

    if ($CurrentDriveLetter -ne $DriveLetter) {
        Write-Verbose "Changing drive letter from [$CurrentDriveLetter] to [$DriveLetter]"
        $CurrentDrive.DriveLetter = $DriveLetter
        Set-CimInstance -InputObject $CurrentDrive
    }
        
    Write-Verbose "Attaching pagefile to the new Driveletter"
    New-CimInstance -ClassName Win32_PageFileSetting -Property @{Name = "$DriveLetter\pagefile.sys"}

    $global:DSCMachineStatus = 1 
  }             
    
} 

function Test-TargetResource 
{ 
  [OutputType([System.Boolean])]    
  param 
  ( 
    [Parameter(Mandatory)] 
    [string]$DriveLetter
  ) 

  # Check to see if we are on a sku that can have drive re-mapped
  if(hasTemporaryDrive -eq $false) {
    Write-Verbose "Not-supported sku for drive re-mapping"
    return $true
  }
  
  Write-Verbose -Message 'Testing Pagefile Driveletter assignment'    
  if ($DriveLetter.Length -gt 1){$DriveLetter = $DriveLetter[0]}
  $CurrentValue = Get-TargetResource @PSBoundParameters

  if ($CurrentValue.DriveLetter -notlike "$($DriveLetter):*") {
    return $false
  }

  Write-Verbose -Message 'Testing Temporary Storage Driveletter' 
  $CurrentDriveLetter = (Get-CimInstance -Class Win32_LogicalDisk -Filter "VolumeName = 'Temporary Storage'").DeviceID[0]
  if ($CurrentDriveLetter -ne $DriveLetter) {
    return $false
  }

  else {
    return $true
  }
} 

Export-ModuleMember -Function *-TargetResource
