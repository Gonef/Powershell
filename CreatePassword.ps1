Add-Type -AssemblyName 'System.Web'
function global:new-pwd
    {
    #Password Properties:
    $pwdLenght = 20
    $pwdNonAlphaChars = 7
    $pwdForbiddenChars = "^","%","&","<",">"
    $pwdNumberOfForbiddenChars = ($pwdForbiddenChars.count)

    $pwdForbiddenCharsIndex = 0
    $pwd = [System.Web.Security.Membership]::GeneratePassword($pwdLenght, $pwdNonAlphaChars)

    $pwdForbiddenCharsState = New-Object System.Collections.ArrayList

    while ($pwdForbiddenCharsIndex -lt $pwdNumberOfForbiddenChars)
        {
        $pwdForbiddenCharState = $pwd.Contains($pwdForbiddenChars[$pwdForbiddenCharsIndex])
        $pwdForbiddenCharsState.add([string]$pwdForbiddenCharState)
        $pwdForbiddenCharsIndex++
            
        }




    }
