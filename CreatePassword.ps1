#Define available characters
$pwdCapital = 'ABCDEFGHKLMNOPRSTUVWXYZ'
$pwdSmall = 'abcdefghiklmnoprstuvwxyz'
$pwdSpecial = '!"§$%/()=?}][{@#*+'
$pwdNumbers = '1234567890'

#Define number of used characters of each type
$pwdCapitalCount = 5
$pwdSmallCount = 5
$pwdSpecialCount = 5
$pwdNumbersCount = 5

#Create Function for getting random chars from list
function GetRandomChars($length, $characters)
    {
    $randomChar = 1..$length | ForEach-Object {
        Get-Random -Maximum $characters.length
        }
    $private:ofs=""
    return [String]$characters[$randomChar]
    }

#Create Function to change order of characters in string
function ChangeOrder([string]$inputString)
    {
    $charArray = $inputString.ToCharArray()
    $RandomizedStringArray = $charArray | Get-Random -Count $charArray.Length
    $outputString = -join $RandomizedStringArray
    return $outputString
    }

#Get random characters
$NewPwdCapitals = GetRandomChars -length $pwdCapitalCount -characters $pwdCapital 
$NewPwdSmalls = GetRandomChars -length $pwdSmallCount -characters $pwdSmall 
$NewPwdSpecials = GetRandomChars -length $pwdSpecialCount -characters $pwdSpecial 
$NewPwdNumbers = GetRandomChars -length $pwdNumbersCount -characters $pwdNumbers

#Generate a password
$pwd = ChangeOrder -inputString ($NewPwdCapitals + $NewPwdSmalls + $NewPwdSpecials + $NewPwdNumbers)
