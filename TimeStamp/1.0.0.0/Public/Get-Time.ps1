function Get-Time{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$false,HelpMessage='Delimiter to use between numbers.')]
        [String]$Delimiter = '-'
    )
    $time = Get-Date -Format HH$($Delimiter)mm
    Return $time
}