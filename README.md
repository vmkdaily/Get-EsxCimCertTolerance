# Get-EsxCimCertTolerance
Gets a list of valid options that can be used to return CIM hardware results with PowerCLI.

## Dot Source the function

    PS C:\> . C:\temp\Get-EsxCimCertTolerance.ps1

## Run it

```
PS C:\> Get-EsxCimCertTolerance -Server vcva02.lab.local

CimResult InvalidCertificateAction VMHostHardwareOption
--------- ------------------------ --------------------
     True Fail                     SkipAllSslCertificateChecks
     True Ignore                   WaitForAllData
     True Ignore                   SkipCACheck
     True Ignore                   SkipCNCheck
     True Ignore                   SkipRevocationCheck
     True Ignore                   SkipAllSslCertificateChecks
     True Prompt                   SkipAllSslCertificateChecks
     True Unset                    SkipAllSslCertificateChecks
     True Warn                     SkipAllSslCertificateChecks

PS C:\>
```

## Optionally, use the `PassThru` switch for additional info added to PSObject

```
PS C:\> $report = Get-EsxCimCertTolerance -Server vcva02.lab.local -PassThru
PS C:\> $report | select -First 1


VMHostHardwareOption     : WaitForAllData
InvalidCertificateAction : Fail
PowerShellVersion        : 5.1.14409.1005
vCenterVersion           : vCenter 6.5.0
CimResult                : False
PowerCLIVersion          : VMware PowerCLI 6.5.1 build 5377412
ClientOS                 : 6.3.9600.0
EsxVersion               : ESX 6.0.0 Build 3825889

PS C:\>
```
