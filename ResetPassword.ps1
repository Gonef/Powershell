#For user: Define Password Properties: Excluded chars, password length
#$pwdExcludeCharsString = '<>()&?#$%'
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

#$pwdExcludeChars = $pwdExcludeCharsString.ToCharArray()

#Import Modules
Import-Module C:\Modules\CsvInputModule.psm1
Import-Module C:\Modules\KeePassModule.psm1

$ScriptUser = whoami
$timestamp = get-date
$inputfile = Get-FileName ".\" 
$csv = Import-Csv $inputfile -Delimiter ";"
$KeePassDB = 'c:\keepassdb\lab.kdbx'
$KeePassBin = 'C:\Apps\KeePass'
$logFile = 'c:\Scripts\ResetPassword\logs.txt'
$errorFile = 'c:\Scripts\ResetPassword\errors.txt'

#Get KeePass Password from user
$KeePassPwd = Read-Host -AsSecureString -Prompt "Enter Master Keepass Password"
$DB = Open-Keepassdatabase -SecuredPasswordToDB $KeePassPwd -PathToDB $KeePassDB -PathToKeePassBinFolder $KeePassBin

#Get Excluded Characters from user
$pwdExcludeCharsString = Read-Host -Prompt "Enter characters you dont want to use in password. Leave blank if there is no forbidden characters"
$pwdExcludeChars = $pwdExcludeCharsString.ToCharArray()

foreach ($Char in $pwdExcludeChars){
    $charTemp =  '\' + $Char
    $pwdSpecial = $pwdSpecial -replace $charTemp, ''
    }

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
    $domain = $line.domain
    $domainusername = $user+'@'+$domain
    $pwd = CreatePwd
    $pwdEncrypted = ConvertTo-SecureString $pwd -AsPlainText -Force
    try {
        $userInfo = Get-ADUser -Identity $user -Server $domain
        $entry = Get-KeePassEntry -UserName $user -KeePassDB $DB
        Set-ADAccountPassword -Server $domain -Identity $user -Reset -NewPassword $pwdEncrypted
        
        # if keepass entry exist
        if($entry.count -eq 1){
            Update-KeePassEntry -UserName $domainusername -KeePassDB $DB -newPassword $pwdEncrypted
            Write-Host "Password changed for user $user . New password: $pwd `r`nKeePass Entry updated" -foregroundcolor green
            Write-Output "$timestamp $ScriptUser changed password for $user" >> $logFile
            }

        # if keepass entry does not exist
        elseif($entry.count -eq 0){
            $userOU = ($userInfo.DistinguishedName -split "OU=",3)[2]
            $userApp = $userOU.Substring(0,$userou.IndexOf(','))
            $groupsExist = Check-ifKeePassFolderExists -GroupName $userApp -PrimaryGroup "Applications" -KeePassDB $DB
            
            #if group doesnt exist in keepass
            if(!$GroupsExist){
                Add-KeepassGroup -GroupName $userApp -KeePassDB $DB -PrimaryGroup "Applications"
                }
            Add-KeepassEntry -GroupName $userApp -PrimaryGroup "Applications" -KeePassDB $DB -Title $domainusername -Username $user -Password $pwdEncrypted
            # KeePAssModule use write-host to let know that he added new folder and entry
            Write-Host "Password changed for user $user . New password: $pwd" -foregroundcolor green
            Write-Output "$timestamp $ScriptUser changed password for $user" >> $logFile
            }

        # if there is more than 1 keepas entry
        else{
             Write-Host "Password changed for user $user . New password: $pwd" -foregroundcolor green
             Write-Output "$timestamp $ScriptUser changed password for $user" >> $logFile
             Write-Host "KeePass Entry has not been updated, please check it manually. There is probably more than 1 entry of that title" -foregroundcolor red
            }
            
        }
    Catch {
        Write-Host "Password wasn't changed for user $user . User doesn't exist or you don't have access to edit this account" -foregroundcolor red
        Write-Output "$timestamp Password wasn't changed for user $user . User doesn't exist or $ScriptUser doesn't have access to edit this account" >> $errorFile     
        }
    }

$db.close()
$KeePassPwd = ""
$Pwd = ""
