# xAzureTempDrive

The **xAzureTempDrive** DSC resource lets you modify your Azure Temporary Drive

## Contributing
Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).

## Resources

* **xAzureTempDrive** Makes you change the temporary driveletter while maintaining its pagefile.

### xAzureTempDrive

* **Driveletter**: Driveletter that should be used for the Azure Temporary Drive

## Versions

### 1.0.1.5
* Fixed reboot loop when dive letter already exists
* Added example file to module
* minor updates

### 1.0.1.3

* Fixed reboot loop issue with 1.0.1.1

### 1.0.1.1

* Added support for Server 2008(R2)

### 1.0.1.0

* Changed WMI to CIM
* Added additional verbose logs
* Removed unused variables

### 1.0.0.2

* Added additional check against volume name in Test-Targetresource

### 1.0.0.1

* minor update to filter the driveletter, if somebody specifies a full path (fe: 'N:\' instead of 'N')

### 1.0.0.0

* First version of the module

## Examples

### Configuring a new drive letter for the Azure Temporary Drive

```powershell
configuration Sample_xAzureTempDrive
{
    param
    (
        [Parameter(Mandatory)]
        [String]$Driveletter
    )
    Import-DscResource -module xAzureTempDrive
    
	xAzureTempDrive AzureTempDrive
    {
        Driveletter = $Driveletter
    }
}
Sample_xAzureTempDrive -Driveletter 'Z'
```
