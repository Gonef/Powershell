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

#Get random characters
$NewPwdCapitals = Get-RandomCharacters -length $pwdCapitalCount -characters $pwdCapital 
$NewPwdSmalls = Get-RandomCharacters -length $pwdSmallCount -characters $pwdSmall 
$NewPwdSpecials = Get-RandomCharacters -length $pwdSpecialCount -characters $pwdSpecial 
$NewPwdNumbers = Get-RandomCharacters -length $pwdNumbersCount -characters $pwdNumbers

#Generate a password
$pwd = Scramble-String -inputString ($NewPwdCapitals + $NewPwdSmalls + $NewPwdSpecials + $NewPwdNumbers)
