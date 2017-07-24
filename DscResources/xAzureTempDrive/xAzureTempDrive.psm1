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
    
  if ($DriveLetter.Length -gt 1){$DriveLetter = $DriveLetter[0]}
  $CurrentValue = (Get-TargetResource @PSBoundParameters).DriveLetter

  if ($currentvalue -ne $null) {
    $pagefile = Get-CimInstance win32_pagefilesetting
    Remove-CimInstance -InputObject $pagefile
    $global:DSCMachineStatus = 1 
  }

  else {
    $CurrentDriveLetter = (get-volume -FileSystemLabel "Temporary Storage").DriveLetter
    if ($CurrentDriveLetter -ne $DriveLetter) {
      Write-Verbose "Changing drive letter from [$CurrentDriveLetter] to [$DriveLetter]"
      Get-Partition -DriveLetter $CurrentDriveLetter | Set-Partition -NewDriveLetter $DriveLetter
    }
        
    $DriveLetter = $DriveLetter + ":"
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
  
  Write-Verbose -Message 'Testing Pagefile Driveletter assignment'    
  if ($DriveLetter.Length -gt 1){$DriveLetter = $DriveLetter[0]}
  $CurrentValue = Get-TargetResource @PSBoundParameters

  if ($CurrentValue.DriveLetter -notlike "$($DriveLetter):*") {
    return $false
  }

  Write-Verbose -Message 'Testing Temporary Storage Driveletter' 
  $CurrentDriveLetter = (get-volume -FileSystemLabel "Temporary Storage").DriveLetter
  if ($CurrentDriveLetter -ne $DriveLetter) {
    return $false
  }

  else {
    return $true
  }
} 

Export-ModuleMember -Function *-TargetResource
