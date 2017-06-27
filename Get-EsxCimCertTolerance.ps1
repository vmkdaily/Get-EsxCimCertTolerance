#Requires -version 3

Function Get-EsxCimCertTolerance {

    <#
        .SYNOPSIS
            Tests the client's ability to connect to ESX and return CIM hardware results using PowerCLI.

        .DESCRIPTION
            Tests the client's ability to connect to ESX and return CIM hardware results using PowerCLI.
            Iterates through all possible parameter sets of Set-PowerCLIConfiguration and
            Get-VMHostHardware which together create the union of effective certificate
            requirements to successfully return CIM results.

            For pure object access, save to a variable:
            $report = <your command>.  For even greater detail, see the PassThru parameter.

        .NOTES
            Script:        Get-EsxCimCertTolerance.ps1
            Type:          Function
            Author:        Mike Nisk
            Organization:  vmkdaily
            Requires:      PowerShell 3.0 or greater, 5.1 preferred
            Requires:      Get-VMHostHardware cmdlet only available in PowerCLI 6.0 R2 or greater
            Tested on:     PowerShell 4.0, 5.1
            Tested on:     PowerCLI 6.0 R2, 6.0 R3, 6.3 R1, 6.5 R1, 6.5.1
            Tested on:     Runs well in Microsoft ISE.  Just add your command to the end and press play.  See the help examples for usage.
            Assumptions:   We expect that you are module autoloading or have otherwise added a PowerCLI
                           loader to your profile. For more information on loading PowerCLI see:
                           https://github.com/vmkdaily/Invoke-PowerLoader 

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
            
            Select the desired test by populating the TypeType parameter (Basic, Advanced, All). For a basic test, the script will iterate through all
            possible options of 'Set-PowerCLIConfiguration -InvalidCertificateAction'. The TestType of Advanced performs the
            basic test and also iterates though Get-VMHostHardware parameters related to suppressing cert warnings.
            The TestType of All runs both the Simple and Advanced tests and is the default.
            
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

        .PARAMETER Server
            String. The IP Address or DNS Name of a vCenter Server machine to connect to.

        .PARAMETER Credential
            PSCredential.  The login for vCenter.

        .PARAMETER TestType
            String.  Choose the type of test to run (Simple or Advanced).  The default is Advanced.
            The Simple test iterates through the parameter options of 'Set-PowerCLIConfiguration -InvalidCertificateAction'
            changing scope of the Session for each test (nothing permanent).  The Advanced test iterates through each option
            in the Simple test, but then also tries the various parameter options avaiable on the Get-VMHostHardware cmdlet
            which can be used for suppressing certificate warnings.

        .PARAMETER ShowError
            Switch. Returns the CIM error experienced.  Since the error is always the same we only return the error
            once at the end of the run.  To get obnoxious level logging you can activate the ExhaustivelyReturnErrors
            bool located in the Begin block (not recommended), or review the contents of the object in PassThru mode
            which returns an Error object for each CIM scenario attempted.

        .PARAMETER PassThru
            Switch.  Activate this switch to get the entire object results including PowerShell version, PowerCLI version, OS version, etc.

        .EXAMPLE
        Get-EsxCimCertTolerance -Server vcva02.lab.local -TestType Simple -ShowError

        .EXAMPLE
        Get-EsxCimCertTolerance -Server vcva02.lab.local -TestType Advanced

        .EXAMPLE
        $credsVC = Get-Credential administrator@vsphere.local
        Get-EsxCimCertTolerance -Server vcva02.lab.local -Credential $CredsVC

        .EXAMPLE
        PS C:\> $report = Get-EsxCimCertTolerance -Server vcva02.lab.local -PassThru
        PS C:\> $report | Where-Object {$_.CimResult -eq $true}

        CimResult InvalidCertificateAction VMHostHardwareOption       
        --------- ------------------------ --------------------       
             True Fail                     WaitForAllData             
             True Fail                     SkipAllSslCertificateChecks
             True Ignore                   WaitForAllData             
             True Ignore                   SkipCACheck                
             True Ignore                   SkipCNCheck                
             True Ignore                   SkipRevocationCheck        
             True Ignore                   SkipAllSslCertificateChecks
             True Prompt                   WaitForAllData             
             True Prompt                   SkipAllSslCertificateChecks
             True Unset                    WaitForAllData             
             True Unset                    SkipAllSslCertificateChecks
             True Warn                     WaitForAllData             
             True Warn                     SkipAllSslCertificateChecks

        This example captures the results to a variable.  We then check for CimResult true, which means
        we successfully returned CIM information from ESX.  Not shown, but when using The PassThru parameter,
        additional info is returned such as PowerShell and PowerCLI versions, etc.

        .INPUTS

        .OUTPUTS
        String
        PSObject

    #>

    [CmdletBinding(HelpUri = 'https://github.com/vmkdaily/Get-EsxCimCertTolerance/')]
    Param(

        #String. IP Address or DNS Name of vCenter Server
        [Parameter(Mandatory,HelpMessage='IP Address or DNS Name of vCenter Server machine')]
        [Alias('Computer')]
        [string]$Server,

        #PSCredential. Optionally, use a PSCredential, or we use pass-through SSPI (Default)
        [pscredential]$Credential,

        #String.  Type of test to run (Simple or Advanced).  Default is Advanced.
        [ValidateSet('Simple','Advanced')]
        [Alias('Test')]
        [string]$TestType = 'Advanced',

        #Switch. Optionally, return an example error message at the end of run.
        #In the case of enumerating CIM hardware, the error is always the same.
        [switch]$ShowError,

        #Switch.  Adds additional information to the returned object such as PowerShell,PowerCLI, OS versions, etc.
        [switch]$PassThru

    )
    Begin {
        [string]$InititalRuntimeSessionCertPref = Get-PowerCLIConfiguration -Scope Session | Select-Object -ExpandProperty InvalidCertificateAction
    }
    Process {

        #Connect to vCenter if needed
        If(-Not($Global:DefaultVIServer)){
            $null = Connect-VIServer -Server $Server -WarningAction SilentlyContinue -ErrorAction stop
            $initialConState = 'NotConnected'
        }

        #region runtime info
        $PowerCLI = Get-PowerCLIVersion -WarningAction SilentlyContinue
        [int]$PowerCLIBuildNum = $PowerCLI.Build
        If($PowerCLIBuildNum -lt 3056836){
            Write-Warning -Message 'The Get-VMHostHardware cmdlet requires PowerCLI 6.0 R2 (Build 3056836) or greater!'
            Throw 'PowerCLI version too low!'
        }

        $PowerCLIBuildFriendly = $PowerCLI | Select-Object -ExpandProperty UserFriendlyVersion
        $bluePowerShell = $PSVersionTable.PSVersion -as [string]
        $vcVer = "vCenter $($Global:DefaultVIServer | Select-Object -ExpandProperty Version)"
        
        #esx version
        $h = Get-VMHost -Verbose:$false | Get-Random
        $hVer = $h | Select-Object -ExpandProperty Version
        $hBuild = $h | Select-Object -ExpandProperty Build
        [string]$esxVer = "ESX $($hVer) Build $($hBuild)"
        
        $ClientOsVer =  ([Environment]::OSVersion.Version).ToString()
        if(-Not($ClientOsVer)){
            throw 'Cannot determine Windows version'
        }

        Write-Verbose -Message "Running on Windows $($ClientOsVer)"
        Write-Verbose -Message "Running $($PowerCLIBuildFriendly), on PowerShell $($bluePowerShell)"
        Write-Verbose -Message "Running $($vcVer) and $($esxVer)"
        #endregion

        #Array of Possible InvalidCertificateAction options for Set-PowerCLIConfiguration per the cmdlet's ValidateSet
        $ParamOptions = @('Fail','Ignore','Prompt','Unset','Warn')

        #main report array
        $report = @()

        switch($TestType){
            'Simple' {
                #region Simple Test
                Write-Verbose -Message '------------------'
                Write-Verbose -Message ' Simple Test'
                Write-Verbose -Message '------------------'
                Write-Verbose -Message '// For each InvalidCertificateAction parameter of Set-PowerCLIConfiguration,'
                Write-Verbose -Message '// try returning values from ESX CIM.'

                Foreach ($option in $ParamOptions){
                        
                    Try {
                        $null = Set-PowerCLIConfiguration -Scope Session -InvalidCertificateAction $option -Confirm:$false -ErrorAction Stop
                        
                        #Main
                        Try {
                            $result = Get-VMHost -Verbose:$false | Get-Random | Get-VMHostHardware -Verbose:$false -ErrorAction Stop | Select-Object -Property VMHost,MemorySlotCount
                        }
                        Catch {
                            Write-Error -Message $Error[0].exception.Message
                            Throw
                        }

                        If(($result.MemorySlotCount) -and ($result.MemorySlotCount -ne -1)){
                            [bool]$CimResult = $true
                            Write-Verbose -Message "Succeeded using option of $($option)"
                            Write-Verbose -Message "$($result)"
                        }
                        Else {
                            [bool]$CimResult = $false
                            Write-Verbose -Message "CIM test failed using option of $($option) on $($Result.VMhost)!"

                            #ESX CIM return value of -1 indicates a failure
                            If(($result.MemorySlotCount -is [int]) -and ($result.MemorySlotCount = -1)){
                                Write-Debug -Message 'ESX CIM returned a value of -1.'
                            }
                        }
                    }
                    Catch {
                        Write-Error -Message $Error[0].exception.Message
                        throw
                    }
                    Finally {
                        #Info for this simple runtime
                        $properties = @{
                            'ClientOS'                 = $ClientOsVer
                            'PowerShellVersion'        = $bluePowerShell
                            'vCenterVersion'           = $vcVer
                            'EsxVersion'               = $esxVer
                            'PowerCLIVersion'          = $PowerCLIBuildFriendly
                            'InvalidCertificateAction' = $option
                            'VMHostHardwareOption'     = 'None'
                            'CimResult'                = $CimResult
                            #'Error'                   = $Error[0].exception.Message  #optional, but not recommended since error is always same.
                        }
                        $objSimple = New-Object -TypeName PSObject -Property $Properties
                        $report += $objSimple
                    } #End Finally
                } #End Foreach
                #endregion
            } #End switch simple

            'Advanced' {
                #region Advanced Test
                Write-Verbose -Message '------------------'
                Write-Verbose -Message ' Advanced Test'
                Write-Verbose -Message '------------------'
                Write-Verbose -Message '// For each InvalidCertificateAction parameter of Set-PowerCLIConfiguration,'
                Write-Verbose -Message '// try all possible suppress switches of Get-VMHostHardware.'
                    
                ## All possible switches on Get-VMHostHardware
                $hwSupressOptions = @('WaitForAllData','SkipCACheck','SkipCNCheck','SkipRevocationCheck','SkipAllSslCertificateChecks')

                Foreach ($option in $ParamOptions){
                    $null = Set-PowerCLIConfiguration -Scope Session -InvalidCertificateAction $option -Confirm:$false -ErrorAction Stop
                        
                    $subarray = @()
                    Foreach($opt in $hwSupressOptions){
    
                        #Build it
                        $cmd = "Get-VMHost -Verbose:`$false | Get-Random | Get-VMHostHardware -$($opt) -Verbose:`$false -ErrorAction SilentlyContinue | Select-Object VMHost,MemorySlotCount"
                            
                        #Run it
                        $result = Invoke-Expression -Command $cmd 2>&1

                        #Check it
                        If(($result.MemorySlotCount) -and ($result.MemorySlotCount -ne -1)){
                            [bool]$CimResult = $true
                            Write-Verbose -Message "Succeeded using option of $($option) with $($opt)!"
                            Write-Verbose -Message "$($result)"
                        }
                        Else {
                            [bool]$CimResult = $false
                            Write-Verbose -Message "Option of $($option) with $($opt) failed."
                                
                            #ESX CIM return value of -1 indicates a failure
                            If(($result.MemorySlotCount -is [int]) -and ($result.MemorySlotCount = -1)){
                                Write-Debug -Message 'ESX CIM returned a value of -1.'
                            }
                        }

                        #Info for this advanced runtime
                        $properties = @{
                            'ClientOS'                 = $ClientOsVer
                            'PowerShellVersion'        = $bluePowerShell
                            'vCenterVersion'           = $vcVer
                            'EsxVersion'               = $esxVer
                            'PowerCLIVersion'          = $PowerCLIBuildFriendly
                            'InvalidCertificateAction' = $option
                            'VMHostHardwareOption'     = $opt
                            'CimResult'                = $CimResult
                            #'Error'                   = $Error[0].exception.Message  #optional, but not recommended since error is always same
                        }
                        $objAdvanced = New-Object -TypeName PSObject -Property $Properties
                        $subarray += $objAdvanced
                    }
                    $report += $subarray
                } #End Foreach
                #endregion
            } #End switch advanced
        } #End Switch
    } #End Process

    End {

        #quietly set session back to normal
        $null = Set-PowerCLIConfiguration -Scope Session -InvalidCertificateAction $InititalRuntimeSessionCertPref -Confirm:$false -ErrorAction SilentlyContinue

        If(($Global:DefaultVIServer) -and ($initialConState -eq 'NotConnected')){
            $null = Disconnect-VIServer -Server $Server -Force -Confirm:$false
        }

        #If user wants to see an example ESX CIM error
        If($ShowError){
            Write-Warning -Message "..RETURNING ERROR MESSAGE PER USER REQUEST`n"
            Write-Error -Message $Error[0].exception.Message
        }

        #Output
        If($PassThru){
            return $report
        }
        Else {
            $report | Where-Object { $_.CimResult -eq $true } | Select-Object -Property CimResult,InvalidCertificateAction,VMHostHardwareOption
        }
    } #End End
} #End Function