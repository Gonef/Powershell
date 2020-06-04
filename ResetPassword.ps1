#For user: Define Password Properties: Excluded chars, password length
$pwdExcludeCharsString = '<>;'
$pwdLength = 20
$pwdMinCapitalCount = 2
$pwdMinSmallCount = 2
$pwdMinSpecialCount = 2
$pwdMinNumbersCount = 2

#Define available characters
$pwdCapital = 'ABCDEFGHKLMNOPRSTUVWXYZ'
$pwdSmall = 'abcdefghiklmnoprstuvwxyz'
$pwdSpecial = '!"§$%/()=?}][{@#*+<>;'
$pwdNumbers = '1234567890'

$pwdExcludeChars = $pwdExcludeCharsString.ToCharArray()

#input group name, share path and domain from csv file
Function Get-FileName($directory){
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $directory
    $OpenFileDialog.filter = "CSV (*.csv)| *.csv"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
    
    }

$timestamp = get-date

$inputfile = Get-FileName ".\" 

$csv = Import-Csv $inputfile -Delimiter ";" 

#Get KeePass Password from user than convert it to plain text so cmd can use it.
$KeePassPwdEncrypted = Read-Host -AsSecureString -Prompt "Enter Master Keepass Password"
$KeePassPwd = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($KeePassPwdEncrypted))

#Create Function for getting random chars from list
function GetRandomChars($length, $characters){
    $randomChar = 1..$length | ForEach-Object {
        Get-Random -Maximum $characters.length
        }
    $private:ofs=""
    return [String]$characters[$randomChar]
    }

#Create Function to change order of characters in string
function ChangeOrder([string]$inputString){
    $charArray = $inputString.ToCharArray()
    $RandomizedStringArray = $charArray | Get-Random -Count $charArray.Length
    $outputString = -join $RandomizedStringArray
    return $outputString
    }

foreach ($Char in $pwdExcludeChars){
    $charTemp =  '\' + $Char
    $pwdSpecial = $pwdSpecial -replace $Char, ''
    }

#Merge the rest of chars to make it more random
$pwdAllChars = $pwdCapital + $pwdSmall + $pwdSpecial + $pwdNumbers

function CreatePwd{
    #Get random characters
    $NewPwdCapitals = GetRandomChars -length $pwdMinCapitalCount -characters $pwdCapital
    $NewPwdSmalls = GetRandomChars -length $pwdMinSmallCount -characters $pwdSmall
    $NewPwdSpecials = GetRandomChars -length $pwdMinSpecialCount -characters $pwdSpecial
    $NewPwdNumbers = GetRandomChars -length $pwdMinNumbersCount -characters $pwdNumbers
    $NewPwdAllChars = GetRandomChars -length ($pwdLength - $pwdMinCapitalCount - $pwdMinSmallCount - $pwdMinSpecialCount - $pwdMinNumbersCount) -characters $pwdAllChars

    #Generate a password
    $pwd = ChangeOrder -inputString ($NewPwdCapitals + $NewPwdSmalls + $NewPwdSpecials + $NewPwdNumbers + $NewPwdAllChars)
    return $pwd
    }

#Reset password and update KeePass entries
foreach ($line in $csv){
    $user = $line.user
    $pwd = CreatePwd
    Set-ADAccountPassword -Server $line.domain -Identity $line.user -Reset -NewPassword (ConvertTo-SecureString -AsPlainText "$pwd" -Force)
    &"C:\Apps\KeePass\KPScript.exe" -c:EditEntry "C:\KeePassDB\Lab.kdbx" -pw:$KeePassPwd -ref-Title:$user -set-Password:$pwd
    Write-Host "Password changed for user" $line.user ". New password:" $pwd
    }
Write-Host "KeePass entries have been updated"
