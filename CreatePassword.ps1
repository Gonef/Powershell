Add-Type -AssemblyName 'System.Web'
    #Password Properties:
    $pwdLenght = 20
    $pwdNonAlphaChars = 7
    $pwdForbiddenChars = "^","%","&","<",">"
    $pwdNumberOfForbiddenChars = ($pwdForbiddenChars.count)

    #Generate password
    $pwdForbiddenCharsIndex = 0
    $pwd = [System.Web.Security.Membership]::GeneratePassword($pwdLenght, $pwdNonAlphaChars)

    #Create list which will be used to contain state of forbidden characters
    $pwdForbiddenCharsState = New-Object System.Collections.ArrayList
    
    #Chech if password contains forbidden characters and add it to list     
    while ($pwdForbiddenCharsIndex -lt $pwdNumberOfForbiddenChars)
        {
        $pwdForbiddenCharState = $pwd.Contains($pwdForbiddenChars[$pwdForbiddenCharsIndex])
        $pwdForbiddenCharsState.add([string]$pwdForbiddenCharState)
        $pwdForbiddenCharsIndex++
            
        }
