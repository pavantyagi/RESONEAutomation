data localizedData {
    # Localized messages; culture="en-US"
    ConvertFrom-StringData @'
        ResourceIncorrectPropertyState  = Resource property '{0}' is NOT in the desired state. Expected '{1}', actual '{2}'.
        ResourceInDesiredState          = Resource '{0}' is in the desired state.
        ResourceNotInDesiredState       = Resource '{0}' is NOT in the desired state.
        QueryingSiteId                  = Querying '{0}\{1}' database for Site Id.
        DiscoveredSiteId                = Discovered Site Id '{0}'.
'@
}


function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        ## RES ONE Automation database server name/instance (equivalient to DBSERVER).
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $DatabaseServer,

        ## RES ONE Automation database name (equivalient to DBNAME).
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $DatabaseName,

        ## Microsoft SQL username/password to connect to the database (equivalent to DBUSER/DBPASSWORD).
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()] $Credential,

        ## File path containing the RES ONE Automation MSIs or the literal path to the Agent MSI.
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Path,

        ## By default, the Agent will autodetect Dispatchers. To use a fixed list of Dispatchers instead, use
        ## this parameter to specify the names or GUIDs of Dispatchers to use. Separate multiple entries with a semi-colon (;).
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String[]] $DispatcherList,

        ## Should the agent try autodetecting Dispatchers before using the $DispatcherList
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean] $UseAutodetectFirst = $true,

        ## Should the agent extend its list of Dispatchers by downloading a list of all Dispatchers.
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean] $DownloadDispatcherList = $false,

        ## To add the Agent as a member of one or more Teams, use this property to specify the names or GUIDs
        ## of the Teams. Separate multiple entries with a semi-colon (;).
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String[]] $AddToTeam,

        ## To run one or more Modules, Projects or Run Books on the new Agent as soon as it comes online, use this property
        ## to specify the GUIDs.
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String[]] $InvokeProject,

        ## RES ONE Automation component version to be installed, i.e. 8.0.3.0
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String] $Version,

        ## The specified Path is a literal file reference (bypasses the $Versioncheck).
        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.SwitchParameter] $IsLiteralPath,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String] $Ensure = 'Present'
    )

    $setupPath = Resolve-ROAPackagePath -Path $Path -Component 'Agent' -Version $Version -IsLiteralPath:$IsLiteralPath -Verbose:$Verbose;
    [System.String] $msiProductName = Get-WindowsInstallerPackageProperty -Path $setupPath -Property ProductName;
    $productName = $msiProductName.Trim();

    $targetResource = @{
        Path = $setupPath;
        ProductName = $productName;
        Ensure = if (Get-InstalledProductEntry -Name $productName) { 'Present' } else { 'Absent' };
    }
    return $targetResource;

} #end function Get-TargetResource


function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        ## RES ONE Automation database server name/instance (equivalient to DBSERVER).
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $DatabaseServer,

        ## RES ONE Automation database name (equivalient to DBNAME).
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $DatabaseName,

        ## Microsoft SQL username/password to connect to the database (equivalent to DBUSER/DBPASSWORD).
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()] $Credential,

        ## File path containing the RES ONE Automation MSIs or the literal path to the Agent MSI.
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Path,

        ## By default, the Agent will autodetect Dispatchers. To use a fixed list of Dispatchers instead, use
        ## this parameter to specify the names or GUIDs of Dispatchers to use. Separate multiple entries with a semi-colon (;).
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String[]] $DispatcherList,

        ## Should the agent try autodetecting Dispatchers before using the $DispatcherList
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean] $UseAutodetectFirst = $true,

        ## Should the agent extend its list of Dispatchers by downloading a list of all Dispatchers.
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean] $DownloadDispatcherList = $false,

        ## To add the Agent as a member of one or more Teams, use this property to specify the names or GUIDs
        ## of the Teams. Separate multiple entries with a semi-colon (;).
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String[]] $AddToTeam,

        ## To run one or more Modules, Projects or Run Books on the new Agent as soon as it comes online, use this property
        ## to specify the GUIDs.
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String[]] $InvokeProject,

        ## RES ONE Automation component version to be installed, i.e. 8.0.3.0
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String] $Version,

        ## The specified Path is a literal file reference (bypasses the $Versioncheck).
        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.SwitchParameter] $IsLiteralPath,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String] $Ensure = 'Present'
    )

    $targetResource = Get-TargetResource @PSBoundParameters;
    if ($Ensure -ne $targetResource.Ensure) {
        Write-Verbose -Message ($localizedData.ResourceIncorrectPropertyState -f 'Ensure', $Ensure, $targetResource.Ensure);
        Write-Verbose -Message ($localizedData.ResourceNotInDesiredState -f $targetResource.ProductName);
        return $false;
    }
    else {
        Write-Verbose -Message ($localizedData.ResourceInDesiredState -f $targetResource.ProductName);
        return $true;
    }

} #end function Test-TargetResource


function Set-TargetResource {
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param (
        ## RES ONE Automation database server name/instance (equivalient to DBSERVER).
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $DatabaseServer,

        ## RES ONE Automation database name (equivalient to DBNAME).
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $DatabaseName,

        ## Microsoft SQL username/password to connect to the database (equivalent to DBUSER/DBPASSWORD).
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()] $Credential,

        ## File path containing the RES ONE Automation MSIs or the literal path to the Agent MSI.
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Path,

        ## By default, the Agent will autodetect Dispatchers. To use a fixed list of Dispatchers instead, use
        ## this parameter to specify the names or GUIDs of Dispatchers to use. Separate multiple entries with a semi-colon (;).
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String[]] $DispatcherList,

        ## Should the agent try autodetecting Dispatchers before using the $DispatcherList
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean] $UseAutodetectFirst = $true,

        ## Should the agent extend its list of Dispatchers by downloading a list of all Dispatchers.
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean] $DownloadDispatcherList = $false,

        ## To add the Agent as a member of one or more Teams, use this property to specify the names or GUIDs
        ## of the Teams. Separate multiple entries with a semi-colon (;).
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String[]] $AddToTeam,

        ## To run one or more Modules, Projects or Run Books on the new Agent as soon as it comes online, use this property
        ## to specify the GUIDs.
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String[]] $InvokeProject,

        ## RES ONE Automation component version to be installed, i.e. 8.0.3.0
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String] $Version,

        ## The specified Path is a literal file reference (bypasses the $Versioncheck).
        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.SwitchParameter] $IsLiteralPath,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String] $Ensure = 'Present'
    )

    $setupPath = Resolve-ROAPackagePath -Path $Path -Component 'Agent' -Version $Version -IsLiteralPath:$IsLiteralPath -Verbose:$Verbose;
    if ($Ensure -eq 'Present') {

        Write-Verbose -Message ($localizedData.QueryingSiteId -f $DatabaseServer, $DatabaseName);
        $siteId = Get-ROALicense -Server $DatabaseServer -Database $DatabaseName -Credential $Credential;
        Write-Verbose -Message ($localizedData.DiscoveredSiteId -f $siteId);

        $arguments = @(
            ('/i "{0}"' -f $setupPath),
            ('SITELICENSE="{0}"' -f $siteId),
            ('DISPATCHERAUTODETECTFIRST="{0}"' -f [System.Int32] $UseAutodetectFirst),
            ('DISPATCHERGETLIST="{0}"' -f [System.Int32] $DownloadDispatcherList)
        )

        if ($PSBoundParameters.ContainsKey('DispatcherList')) {
            $arguments += 'DISPATCHERLIST="{0}"' -f ($DispatcherList -join ';');
        }
        if ($PSBoundParameters.ContainsKey('AddToTeam')) {
            $arguments += 'ADDTOTEAM="{0}"' -f ($AddToTeam -join ';');
        }
        if ($PSBoundParameters.ContainsKey('InvokeProject')) {
            $arguments += 'INVOKEPROJECT="{0}"' -f ($InvokeProject -join ';');
        }

    }
    elseif ($Ensure -eq 'Absent') {

        [System.String] $msiProductCode = Get-WindowsInstallerPackageProperty -Path $setupPath -Property ProductCode;
        $arguments = @(
            ('/X{0}' -f $msiProductCode)
        )

    }

    ## Start install/uninstall
    $arguments += '/norestart';
    $arguments += '/qn';
    Start-WaitProcess -FilePath "$env:WINDIR\System32\msiexec.exe" -ArgumentList $arguments -Verbose:$Verbose;

} #end function Set-TargetResource


## Import the ROACommon library functions
$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;
$moduleParent = Split-Path -Path $moduleRoot -Parent;
Import-Module (Join-Path -Path $moduleParent -ChildPath 'ROACommon') -Force;

Export-ModuleMember -Function *-TargetResource;
