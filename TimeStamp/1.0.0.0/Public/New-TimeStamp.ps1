function New-TimeStamp {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$false,HelpMessage='Delimiter to use between numbers.')]
        [String]$Delimiter = '-'
    )
    $timeStamp = Get-Date -Format "yyyy$($Delimiter)MM$($Delimiter)dd_HH$($Delimiter)mm"
	Return $timeStamp
}