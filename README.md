# Get-EsxCimCertTolerance
Gets a list of valid options that can be used to return CIM hardware results with PowerCLI.

## Supporting Blog Post
http://vmkdaily.ghost.io/test-access-to-esx-cim-from-powercli/

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

## Additional Info

```

    OVERVIEW
    If you need dependable CIM results from ESX you may consider setting your runtime
    PowerCLI configuration InvalidCertificateAction to Ignore.
    
    $null = Set-PowerCLIConfiguration -Scope Session -InvalidCertificateAction Ignore -Confirm:$false
    
    DETAILS
    The purpose of this script is to help you find settings that will allow you to successfully interact with ESX CIM
    from your current client.  The easy fix is simply to set your PowerCLI configuration to Ignore InvalidCertificateAction.
    
    To access ESX CIM, we depend on the Get-VMHostHardware cmdlet (available in PowerCLI 6.0 R2 or later).  In my testing, I am able to
    reproduce the behavior (missing CIM results) across all versions up to the latest PowerCLI 6.5.1.
    
    The ability to consistently return ESX CIM results may depend on the effective combination of runtime settings for
    Set-PowerCLIConfiguration and Get-VMHostHardware.
    
    We know that the Possible InvalidCertificateAction options for Set-PowerCLIConfiguration is
    'Fail', 'Ignore', 'Prompt', 'Unset', or 'Warn'.
    
    We know that Get-VMHostHardware has several parameters to assist with invalid certificate handling.
    These include 'WaitForAllData', 'SkipCACheck', 'SkipCNCheck', 'SkipRevocationCheck', and
    'SkipAllSslCertificateChecks'.
    
    The script herein, connects to vCenter and attempts to return CIM information from a random ESX host.
    The host we connect to is not important since this is a client side issue.  As such, we choose a random
    ESX host.
    
    Select the desired test by populating the TypeType parameter (Simple or Advanced).  The default is Advanced.
    The Simple test iterates through all possible options of 'Set-PowerCLIConfiguration -InvalidCertificateAction'.
    The TestType of Advanced performs the Simple test and also iterates though Get-VMHostHardware parameters related to suppressing
    cert warnings.
    
    TESTING RESULTS
    Understand that the error is returned in all cases.  What you can control is how the system reacts to such failed CIM requests.
    In my testing, any of the following work:
    
        OPTION #1
        $null = Set-PowerCLIConfiguration -Scope Session -InvalidCertificateAction Ignore -Confirm:$false
        This option sets the preference for the current session and successfully returns CIM results.
    
        OPTION #2
        Get-VMHost | Get-Random | Get-VMHostHardware -WaitForAllData | Select-Object VMHost,MemorySlotCount
        Using the WaitForAllData parameter of the Get-VMHostHardware cmdlet successfully returns CIM results.
    
        OPTION #3
        Get-VMHost | Get-Random | Get-VMHostHardware -SkipAllSslCertificateChecks | Select-Object VMHost,MemorySlotCount
        Using the SkipAllSslCertificateChecks parameter of the Get-VMHostHardware cmdlet successfully returns CIM results.
    
    ABOUT ESX CIM CERTIFICATE ERRORS
    This may change in future versions, and may vary if you actually use signed certs.  For regular default installs that use
    the VMware self-signed certs, we will experience one of the following errors:
    
        Failed to retrieve CIM power supply data for <esxname>
    
        -or
    
        Failed to retrieve CIM memory slot data for <esxname>
    
        -or-
    
         Failed to retrieve CIM memory modules data for <esxname>
    
    In all such cases the following error is returned:
    
        The underlying error message was: The server certificate on the destination computer <esxname> has the following errors: 
        The SSL certificate could not be checked for revocation. The server used to check for revocation might be unreachable.    
        The SSL certificate is signed by an unknown certificate authority.
```

## Verbose Example

```
PS C:\> Get-EsxCimCertTolerance -Server vcva02.lab.local -Verbose
VERBOSE: Attempting to connect using SSPI
VERBOSE: Reversely resolved 'vcva02.lab.local' to 'vcva02'
VERBOSE: SSPI Kerberos: Acquired credentials for user 'LAB\vmadmin'
VERBOSE: SSPI Kerberos: Successful call to InitializeSecurityContext for target 'host/vcva02'
VERBOSE: Connected successfully using SSPI
VERBOSE: 6/27/2017 5:22:22 PM Get-PowerCLIVersion Started execution
VERBOSE: 6/27/2017 5:22:22 PM Get-PowerCLIVersion Finished execution
VERBOSE: Running on Windows 6.3.9600.0
VERBOSE: Running VMware PowerCLI 6.5.1 build 5377412, on PowerShell 5.1.14409.1005
VERBOSE: Running vCenter 6.5.0 and ESX 6.0.0 Build 3825889
VERBOSE: ------------------
VERBOSE:  Advanced Test
VERBOSE: ------------------
VERBOSE: // For each InvalidCertificateAction parameter of Set-PowerCLIConfiguration,
VERBOSE: // try all possible suppress switches of Get-VMHostHardware.
VERBOSE: Option of Fail with WaitForAllData failed.
VERBOSE: Option of Fail with SkipCACheck failed.
VERBOSE: Option of Fail with SkipCNCheck failed.
VERBOSE: Option of Fail with SkipRevocationCheck failed.
VERBOSE: Succeeded using option of Fail with SkipAllSslCertificateChecks!
VERBOSE: @{VMHost=esx01.lab.local; MemorySlotCount=4}
VERBOSE: Succeeded using option of Ignore with WaitForAllData!
VERBOSE: @{VMHost=esx01.lab.local; MemorySlotCount=4}
VERBOSE: Succeeded using option of Ignore with SkipCACheck!
VERBOSE: @{VMHost=esx04.lab.local; MemorySlotCount=4}
VERBOSE: Succeeded using option of Ignore with SkipCNCheck!
VERBOSE: @{VMHost=esx02.lab.local; MemorySlotCount=4}
VERBOSE: Succeeded using option of Ignore with SkipRevocationCheck!
VERBOSE: @{VMHost=esx01.lab.local; MemorySlotCount=4}
VERBOSE: Succeeded using option of Ignore with SkipAllSslCertificateChecks!
VERBOSE: @{VMHost=esx04.lab.local; MemorySlotCount=4}
VERBOSE: Option of Prompt with WaitForAllData failed.
VERBOSE: Option of Prompt with SkipCACheck failed.
VERBOSE: Option of Prompt with SkipCNCheck failed.
VERBOSE: Option of Prompt with SkipRevocationCheck failed.
VERBOSE: Succeeded using option of Prompt with SkipAllSslCertificateChecks!
VERBOSE: @{VMHost=esx03.lab.local; MemorySlotCount=4}
VERBOSE: Option of Unset with WaitForAllData failed.
VERBOSE: Option of Unset with SkipCACheck failed.
VERBOSE: Option of Unset with SkipCNCheck failed.
VERBOSE: Option of Unset with SkipRevocationCheck failed.
VERBOSE: Succeeded using option of Unset with SkipAllSslCertificateChecks!
VERBOSE: @{VMHost=esx02.lab.local; MemorySlotCount=4}
VERBOSE: Option of Warn with WaitForAllData failed.
VERBOSE: Option of Warn with SkipCACheck failed.
VERBOSE: Option of Warn with SkipCNCheck failed.
VERBOSE: Option of Warn with SkipRevocationCheck failed.
VERBOSE: Succeeded using option of Warn with SkipAllSslCertificateChecks!
VERBOSE: @{VMHost=esx03.lab.local; MemorySlotCount=4}
VERBOSE: 6/27/2017 5:22:35 PM Disconnect-VIServer Started execution
VERBOSE: 6/27/2017 5:22:35 PM Disconnect-VIServer Finished execution
```

-end-
