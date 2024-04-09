# Find out if we are on a VM that has a temporary drive can be moved
# e.g. DS1 series has a temp drive, while DS2 series does not
function Find-TemporaryDrive {
  # Check to see if there are any disks labelled as Temporary Storage
  $volumes = Get-Volume
  foreach ($volume in $volumes) {
      if ($volume.FileSystemLabel -eq 'Temporary Storage') {
          return $true
      }
  }
  return $false
}

function Get-TargetResource
{
  [OutputType([System.Collections.Hashtable])]
  param
  (
    [Parameter(Mandatory)]
    [string]$DriveLetter
  )

  # Obtain driveletter that contains the pagefile
  Write-Verbose -Message 'Retrieving Pagefile settings'
  $pagefile = Get-CimInstance win32_pagefilesetting
  if ($null -ne $pagefile) {
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
  $hasTempDrive = Find-TemporaryDrive
  if($hasTempDrive -eq $false) {
    Write-Verbose "Non-supported SKU for drive re-mapping"
    return $true
  }

  if ($DriveLetter.Length -gt 1){$DriveLetter = $DriveLetter[0]}
  $CurrentValue = (Get-TargetResource @PSBoundParameters).DriveLetter
  $CurrentDriveLetter = (Get-CimInstance -Class Win32_LogicalDisk -Filter "VolumeName = 'Temporary Storage'").DeviceID
  $CurrentDrive = Get-CimInstance -Class win32_volume -Filter "DriveLetter = '$($CurrentDriveLetter)'"

  # Check if the new assigned driveletter is alreadu in use
  if (((get-ciminstance win32_volume).driveletter -contains "$($DriveLetter):") -and ($CurrentDriveLetter -ne "$($DriveLetter):")){
    throw "Cannot update Temporary Storage to $($DriveLetter): Driveletter $DriveLetter is already in use!"
  }

  # Remove pagefile before updating driveletter
  if ($null -ne $currentvalue) {
    $pagefiles = Get-CimInstance win32_pagefilesetting
    foreach ($pagefile in $pagefiles) {
        Remove-CimInstance -InputObject $pagefile
    }
    # Initiate reboot to complete removal of pagefile.
    $global:DSCMachineStatus = 1
  }

  else {
    $DriveLetter = $DriveLetter + ":"

    # Update driveletter
    if ($CurrentDriveLetter -ne $DriveLetter) {
        Write-Verbose "Changing drive letter from [$CurrentDriveLetter] to [$DriveLetter]"
        $CurrentDrive.DriveLetter = $DriveLetter
        Set-CimInstance -InputObject $CurrentDrive
    }

    # Attach pagefile back to the new driveletter
    Write-Verbose "Attaching pagefile to the new Driveletter"
    New-CimInstance -ClassName Win32_PageFileSetting -Property @{Name = "$DriveLetter\pagefile.sys"}

    # Initiate reboot to complete attaching the pagefile.
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
  $hasTempDrive = Find-TemporaryDrive
  if($hasTempDrive -eq $false) {
    Write-Verbose "Non-supported SKU for drive re-mapping"
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
