configuration Sample_xAzureTempDrive
{
    param
    (
        [Parameter(Mandatory)]
        [String]$Driveletter
    )

    Import-DscResource –ModuleName PSDesiredStateConfiguration
    Import-DscResource -module xAzureTempDrive

    LocalConfigurationManager
      {
          AllowModuleOverwrite = $true
          RefreshMode = 'Push'
          ConfigurationMode = 'ApplyAndAutoCorrect'
          RebootNodeIfNeeded = $true
          DebugMode = "All"
      }

	xAzureTempDrive AzureTempDrive
    {
        Driveletter = $Driveletter
    }
}

Sample_xAzureTempDrive -Driveletter 'Z'