function ChangeOrder([string]$inputString){
    $charArray = $inputString.ToCharArray()
    $RandomizedStringArray = $charArray | Get-Random -Count $charArray.Length
    $outputString = -join $RandomizedStringArray
    return $outputString
    }
