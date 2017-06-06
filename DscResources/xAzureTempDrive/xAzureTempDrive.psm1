function Get-TargetResource 
{    
    [OutputType([System.Collections.Hashtable])] 
  param 
   (   
	[Parameter(Mandatory)] 
        [string]$DriveLetter

   ) 
   
    $pagefile = gwmi win32_pagefilesetting
    if ($pagefile -ne $null) {
        $pagefile = $pagefile.Name.ToLower()  
    }

    $returnValue = @{ 
        DriveLetter = $pagefile      
    }
         
    $returnValue 
} 

function Set-TargetResource 
{   
   param 
    ( 
      [Parameter(Mandatory)] 
        [string]$DriveLetter   
    ) 
    
    $CurrentValue = (Get-TargetResource @PSBoundParameters).DriveLetter

    if ($currentvalue -ne $null) {
        $pagefile = gwmi win32_pagefilesetting
        $pagefile.Delete()
        $global:DSCMachineStatus = 1 
    }

    else {
        $CurrentDriveLetter = (get-volume -FileSystemLabel "Temporary Storage").DriveLetter
        write-verbose "Changing drive letter from [$CurrentDriveLetter] to [$DriveLetter]"
        Get-Partition -DriveLetter $CurrentDriveLetter | Set-Partition -NewDriveLetter $DriveLetter
        
        $DriveLetter = $DriveLetter + ":"
        $drive = Get-WmiObject -Class win32_volume -Filter “DriveLetter = '$DriveLetter'”
        write-verbose "Attaching pagefile to the new Driveletter"
        Set-WMIInstance -Class Win32_PageFileSetting -Arguments @{ Name = "$DriveLetter\pagefile.sys"; MaximumSize = 0; }

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
    
    $CurrentValue = Get-TargetResource @PSBoundParameters

    if ($CurrentValue.DriveLetter -like "$DriveLetter*") {
        return $true
    }
    else {
        return $false
    }
} 


Export-ModuleMember -Function *-TargetResource 