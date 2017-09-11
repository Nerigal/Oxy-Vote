#    
#   Created on: 11/04/2017
#   Author:     Nerigal
#   Version:    0.2.0
#   Purpose:    Powershell vote script 
#
#------------------------------------------------------------------------------------------
function IgnoreSSL()
{
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
           ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}
#------------------------------------------------------------------------------------------

#------------------------------------------------------------------------------------------
function TranslateDelegateName( [ref]$DelegateList, $chost, [ref]$verbose )
{
	$list = $DelegateList.value
	$result = @()
	foreach( $n in $list )
	{
		Write-verbose "TranslateDelegateName : Getting Adress for... $($n| out-string )"
        $url = $chost + "/api/delegates/get?username=" + $n
		Write-verbose "$TranslateDelegateName $url"
        $obj = ((Invoke-WebRequest -Uri $url | ConvertFrom-Json ).delegate).address
		if( $obj )
		{
			Write-verbose "TranslateDelegateName : Address is... $obj"
		}
		else
		{
			write-error "TranslateDelegateName : Address not found for... $n"
		}
		
		$result += $obj
	}	
	return $result
}
#------------------------------------------------------------------------------------------

#------------------------------------------------------------------------------------------
function Oxy-Vote()
{
	[CmdletBinding(DefaultParametersetName="Set 1", ConfirmImpact='high' )]
	
    PARAM(
    [parameter( Position=0, Mandatory=$true, ValueFromPipeline = $True, ParameterSetName = "Set 1" )]
	[parameter(ParameterSetName = "Set 2")]
    [ValidateNotNullOrEmpty()]
    [string]$HostUrl = '',

    [parameter( Position=1, Mandatory=$true, ValueFromPipeline = $True, ParameterSetName = "Set 1" )]
	[parameter(ParameterSetName = "Set 2")]
    [ValidateNotNullOrEmpty()]
    [Security.SecureString]$Secret = '',
	
    [parameter( Position=2, Mandatory=$true, ValueFromPipeline = $True, ParameterSetName = "Set 1" )]
	[parameter(ParameterSetName = "Set 2")]
    [ValidateNotNullOrEmpty()]	
	[Security.SecureString]$SecondSecret = '',
	
    [parameter( Position=3, Mandatory=$true, ValueFromPipeline = $True, ParameterSetName = "Set 1" )]
	[parameter(ParameterSetName = "Set 2")]
    [ValidateNotNullOrEmpty()]
    [string]$Address = '',	

    [parameter( Position=4, Mandatory=$true, ValueFromPipeline = $True, ParameterSetName = "Set 1")]
    [ValidateNotNullOrEmpty()]
    [string]$File = '',
	
    [parameter( Position=4, Mandatory=$true, ValueFromPipeline = $True, ParameterSetName = "Set 2")]
    [ValidateNotNullOrEmpty()]
    [string]$Url = '',	

	[parameter( Position=5, Mandatory=$true, ValueFromPipeline = $True, ParameterSetName = "Set 1")]
	[parameter(ParameterSetName = "Set 2")]
    [ValidateNotNullOrEmpty()]
	[ValidateSet('Address','DelegateName')]
    [string]$DataType = 'DelegateName',
	
    [parameter( Position=6, Mandatory=$false, ValueFromPipeline = $True, ParameterSetName = "Set 1" )]
	[parameter(ParameterSetName = "Set 2")]
    [bool]$SSL = $True,
	
    [parameter( Position=7, Mandatory=$false, ValueFromPipeline = $True, ParameterSetName = "Set 1" )]
	[parameter(ParameterSetName = "Set 2")]
    [bool]$Remove = $False
    )

	$VerbosePrefix = 'Lisk-Vote :'
	$verbose = $True
	$debug = $false
	$FolderList = $null		
	
	if( $VerbosePreference -eq 'Continue' )
	{
		$verbose = $true
	}
	
	if( $SSL -eq $false )
	{
		IgnoreSSL
	}

	$delegatesPubKey = @()
	$urlvote = $HostUrl + '/api/accounts/delegates'
	$voteddelegates =  $HostUrl + '/api/accounts/delegates?address=' + $address
	$votelist = (((Invoke-WebRequest -Uri $voteddelegates ).content | convertfrom-json).delegates | select -property address) | %{  $_.address }	
	$max = 101 - $votelist.count 
	$r = @()
	
	switch ($PsCmdlet.ParameterSetName)
	{
		"Set 1"
		{
			Write-verbose "$VerbosePrefix Get list from File... $File"
			$list = Get-Content $file
			if( $DataType -eq 'DelegateName' )
			{
				$list = TranslateDelegateName ( [ref]$list ) ($HostUrl)
			}			
			break
		}
		"Set 2"
		{
			Write-verbose "$VerbosePrefix Get list from URL... $url"
			$list = ((( Invoke-WebRequest -Uri $url ).content) -replace '"','').split(',')
			if( $DataType -eq 'DelegateName' )
			{
				$list = TranslateDelegateName ( [ref]$list ) ($HostUrl)
			}	
			break
		}
	}
	
	foreach( $addr in $list )
	{
		$addr = $addr.Trim()
		if( $remove -eq $true )
		{
			if ( $votelist -match $addr )
			{
				Write-verbose "$VerbosePrefix Address found in vote list... $addr" 
				$uri = $HostUrl + '/api/accounts?address=' + $addr
				Write-verbose "$VerbosePrefix $uri"
				$call = (( Invoke-WebRequest -uri $uri -Method GET).Content | convertfrom-json)
				if($call.success -eq $true )
				{
					$pb = $call.account.publicKey
					Write-verbose "$VerbosePrefix Removing...$pb"
					$delegatesPubKey += '-' + $pb

				}
			}		
		}
		else
		{
			if ( $votelist -match $addr )
			{
				Write-verbose "$VerbosePrefix Address found in vote list... $addr" 
				$r += $addr
			}
			else
			{
				$uri = $HostUrl + '/api/accounts?address=' + $addr
				Write-verbose "$VerbosePrefix $uri"
				$call = ((Invoke-WebRequest -uri $uri -Method GET).Content | convertfrom-json)
				if( $call.success -eq $true )
				{
					$pb = $call.account.publicKey
					Write-verbose "$VerbosePrefix PubKey is ... $pb"
					if( $call.account.publicKey -match '[a-z0-9]+'  )
					{
						Write-verbose "$VerbosePrefix Adding Pubkey... $pb"
						$delegatesPubKey += '+' + $pb
					}
				}
			}
		}
	}
	
	write-host $delegatesPubKey 
	
	if( $delegatesPubKey.count -ne 0 )
	{
		if( $remove -eq $false )
		{
			$delegatesPubKey = ( $delegatesPubKey[ 0..$max ] )
		}		
		Write-verbose "$VerbosePrefix Final list... $delegatesPubKey" 
		$counter = [pscustomobject] @{ Value = 0 }
		$groupSize = 33
		$delegatesChunk = $delegatesPubKey | Group-Object -Property { [math]::Floor($counter.Value++ / $groupSize) }
		$result = @()
		Write-verbose "$VerbosePrefix Chuck is... $($delegatesChunk | out-string )"  
	}
	else
	{
		Write-verbose "$VerbosePrefix All Address were found in the vote list...Nothing to do."
	}
	
	write-host ( $delegatesChunk | out-string )
	
	foreach( $delegatePubKey in $delegatesChunk )
	{
		$delegateGroup = $delegatePubKey.group
		Write-verbose "$VerbosePrefix voting group is... $delegateGroup"
		
		$Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($Secret)
		$Secret = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr)
		
		$Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($SecondSecret)
		$SecondSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr)	

		if( $SecondSecret )
		{
			$put = @{ 'secret' = $secret; 'delegates' = $delegateGroup; 'secondSecret' = $SecondSecret }
		}
		else
		{
			$put = @{ 'secret' = $secret; 'delegates' = $delegateGroup }
		}
		
        $json = $put | ConvertTo-Json
		if( $PSCmdlet.ShouldProcess( "$json" ) )
		{
			#$result += Invoke-WebRequest $urlvote -Method Put -Body $json -ContentType 'application/json' -verbose:$verbose
			Write-verbose "$VerbosePrefix $urlvote"
		}
		else
		{
			Write-verbose "$VerbosePrefix Not Changes have been applied... You must confirm"
			Write-verbose "$VerbosePrefix To apply changes, make sure to use -confirm:$False"			
		}
	}
	return $result
}
#------------------------------------------------------------------------------------------

