$ScriptUser = $env:username
Import-Module "modulepath.psm1"
$KeePassDB = "dbpath.kdbx"
$KeePassBin = 'KeePasspath'

#Check if proper securestring with keepass password already exists, if not create new one
try
	{
	$KeePassPwd = Get-Content "securestringpath.$scriptuser" | ConvertTo-SecureString
	# $KeePassPwd = Get-Content "E:\Apps\Scripts\PoWin\ActiveDirectory\CreateAdUsers_workinprogress\CreateAdUsers.$scriptuser" | ConvertTo-SecureString
	$DB = Open-Keepassdatabase -SecuredPasswordToDB $KeePassPwd -PathToDB $KeePassDB -PathToKeePassBinFolder $KeePassBin
	}
catch
	{
	Read-Host "Enter KeePass Password" | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString > "securestringpath.$scriptuser"
	$KeePassPwd = Get-Content "securestringpath.$scriptuser" | ConvertTo-SecureString
	# $KeePassPwd = Get-Content "E:\Apps\Scripts\PoWin\ActiveDirectory\CreateAdUsers_workinprogress\CreateAdUsers.$scriptuser" | ConvertTo-SecureString
	$DB = Open-Keepassdatabase -SecuredPasswordToDB $KeePassPwd -PathToDB $KeePassDB -PathToKeePassBinFolder $KeePassBin
	}

#For user: Define Password Properties: Excluded chars, password length
$pwdLength = 20
$pwdMinCapitalCount = 2
$pwdMinSmallCount = 2
$pwdMinSpecialCount = 2
$pwdMinNumbersCount = 2

#Define available characters, if requestor ask to don't use specific characters just delete them from $pwdSpecial, remember to bring them back using commented $pwdSpecial
$pwdCapital = 'ABCDEFGHKLMNOPRSTUVWXYZ'
$pwdSmall = 'abcdefghiklmnoprstuvwxyz'
$pwdSpecial = '!"$%/()=?}][{@"#"*+<>;'
$pwdNumbers = '1234567890'

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
    $newPwd = ChangeOrder -inputString ($NewPwdCapitals + $NewPwdSmalls + $NewPwdSpecials + $NewPwdNumbers + $NewPwdAllChars)
    return $newPwd
    }
	

function sendMail
{

$subject = $inf + ": New SY accounts"
$recipients =  @(Get-ADUser -Identity ADname -Server "domainname" | select userprincipalname | %{ $_.UserPrincipalName})


$MailTotal = $usernameTable

# layout email
$body = "BODY {font-family: Arial; font-size: 9pt;}"
$body = "Dear reader, `n  `n"
$body += "This mail is sent by Platform Operations Windows. `n" 
$body += "SY account has been created based on requests from Application Manager. `n  `n"
$body += $MailTotal
$body += " `n  `n"
$body += "Kind regards, `n"
$body += "Platform Operations Windows"
Write-host $maillabel
if ($maillabel.Checked -eq $true)
	{
	#send email
	Send-MailMessage -to $recipients `
					-subject $subject `
					-from "fromadress" `
					-smtpServer "smtpserver" `
					-Body $body `

	$messages = New-Object -ComObject Wscript.Shell
	$messages.Popup("E-mail sent to $recipients",0,"Done",0x30)
	}
}

function createAdUser ($accountname, $userdomain, $applicationOU, $usrenvironment, $employeeID, $inf, $usrdescription) #creates a new user in AD
	{
	$newPwd = CreatePwd
	$pwdEncrypted = ConvertTo-SecureString $newPwd -AsPlainText -force
	$pwdTable += $newPWD

	$expdate = (get-date).AddYears(1) #set expiredate + one year
	[Int]$dow = $expdate | Select-Object -ExpandProperty DayOfWeek
	if ($dow -eq 6)
		{
		$expdate = $expdate.AddDays(3)
		}
		if ($dow -eq 0)
		{
		$expdate = $expdate.AddDays(2)
		}
	if ($userdomain -eq "hosting")
		{
		$principalname = $accountname + "@" + "lab.corp"

        try 
            {
            New-ADOrganizationalUnit -name $applicationOU -path "OU=$environment,OU=Achmea Application Autorisation,DC=lab,DC=corp"
            New-ADOrganizationalUnit -name "Accounts" -path "OU=$applicationOU,OU=$environment,OU=Achmea Application Autorisation,DC=lab,DC=corp"
            New-ADOrganizationalUnit -name "Groups" -path "OU=$applicationOU,OU=$environment,OU=Achmea Application Autorisation,DC=lab,DC=corp"
            
            }

        catch
            {

            }
		
        try
			{
            New-ADUser -name $accountname -DisplayName $accountname -Description $usrdescription -OtherAttributes @{info=$inf} -AccountPassword $pwdEncrypted -CannotChangePassword $true `
            -AccountExpirationDate $expdate -enabled $true -ChangePasswordAtLogon $false -PasswordNeverExpires $true `
            -path "OU=Accounts,OU=$applicationOU,OU=$usrenvironment,OU=Achmea Application Autorisation,DC=lab,DC=corp"
			Write-Host "$Username 	$usrenvironment	$newPWD"
            
			}
			catch [Microsoft.ActiveDirectory.Management.ADIdentityAlreadyExistsException]
			{
			[System.Windows.Forms.MessageBox]::Show("User already exists in Active Directory", "Active Directory Error",[System.Windows.Forms.MessageBoxButtons]::OK ,[System.Windows.Forms.MessageBoxIcon]::error)
			return
			}

			catch
			{
			[System.Windows.Forms.MessageBox]::Show("Unable to create user in Active Directory", "Active Directory Error",[System.Windows.Forms.MessageBoxButtons]::OK ,[System.Windows.Forms.MessageBoxIcon]::error)
			}


		[String] $SubstringEmployeeID = $owner.Substring(2,6)
		Set-ADUser -Identity $accountname -EmployeeID $SubstringEmployeeID
		Set-ADuser -Identity $accountname -UserPrincipalName $principalname
		
		return $pwdEncrypted
		}

	elseif ($userdomain -eq "domainname")
		{
		$principalname = $accountname + "@" + "domainname.corp"
        
        try 
            {
            New-ADOrganizationalUnit -server "domainname.domainsufix" -name $applicationOU -path "OU=$environment,OU=OUname,DC=domainname,DC=domainsufix"
            New-ADOrganizationalUnit -server "domainname.domainsufix" -name "Accounts" -path "OU=$applicationOU,OU=$environment,OU=OUname,DC=domainname,DC=domainsufix"
            New-ADOrganizationalUnit -server "domainname.domainsufix" -name "Groups" -path "OU=$applicationOU,OU=$environment,OU=OUname,DC=domainname,DC=domainsufix"
			domainname
            }
        catch 
            {
            
            }
  

		try
			{
			New-ADUser -server "extrahosting.corp" -name $accountname -DisplayName $accountname -Description $usrdescription -OtherAttributes @{info=$inf} -AccountPassword $pwdEncrypted -CannotChangePassword $true `
			-AccountExpirationDate $expdate -enabled $true -ChangePasswordAtLogon $false -PasswordNeverExpires $true `
			-path "OU=Accounts,OU=$applicationOU,OU=$usrenvironment,OU=OUname,DC=domainname,DC=domainsufix" -erroraction stop 
            Write-Host "$Username 	$usrenvironment	$newPWD"
			}
		catch [Microsoft.ActiveDirectory.Management.ADIdentityAlreadyExistsException]
			{
			[System.Windows.Forms.MessageBox]::Show("User already exists in Active Directory", "Active Directory Error",[System.Windows.Forms.MessageBoxButtons]::OK ,[System.Windows.Forms.MessageBoxIcon]::error)
			return
			}
		catch
			{
			[System.Windows.Forms.MessageBox]::Show("Unable to create user in Active Directory", "Active Directory Error",[System.Windows.Forms.MessageBoxButtons]::OK ,[System.Windows.Forms.MessageBoxIcon]::error)
			}

		[String] $SubstringEmployeeID = $Owner.Substring(2,6)
		Set-ADUser -server "domainname.domainsufix" -Identity $accountname -EmployeeID $SubstringEmployeeID
		Set-ADuser -server "domainname.domainsufix" -Identity $accountname -UserPrincipalName $principalname
		
		return $pwdEncrypted
		}

	elseif ($userdomain -eq "domainname")
		{
		$principalname = $accountname + "@" + "domainname.domainsufix"

		try
			{
			$usrdescription = $applicationOU + " - " + $usrenvironment + " - " + $usrdescription + " - " + $inf
		
			if ($usrenvironment -eq "Productie") 
				{
				New-ADUser -server "achmeavastgoed.local" -name $accountname -DisplayName $accountname -Description $usrdescription -OtherAttributes @{info=$inf} -AccountPassword $pwdEncrypted -CannotChangePassword $true `
				-AccountExpirationDate $expdate -enabled $true -ChangePasswordAtLogon $false -PasswordNeverExpires $true `
				-path "OU=Ouname,OU=Ouname,OU=Ouname,DC=domainname,DC=domainsufix" -erroraction stop
                Write-Host "$Username 	$usrenvironment	$newPWD"
				}
			else 
				{
				New-ADUser -server "achmeavastgoed.local" -name $accountname -DisplayName $accountname -Description $usrdescription -OtherAttributes @{info=$inf} -AccountPassword $pwdEncrypted -CannotChangePassword $true `
				-AccountExpirationDate $expdate -enabled $true -ChangePasswordAtLogon $false -PasswordNeverExpires $true `
				-path "OU=Ouname,OU=Ouname,OU=Ouname,DC=domainname,DC=domainsufix" -erroraction stop
                Write-Host "$Username 	$usrenvironment	$newPWD"
				}
			}
		catch [Microsoft.ActiveDirectory.Management.ADIdentityAlreadyExistsException]
			{
			[System.Windows.Forms.MessageBox]::Show("User already exists in Active Directory", "Active Directory Error",[System.Windows.Forms.MessageBoxButtons]::OK ,[System.Windows.Forms.MessageBoxIcon]::error)
			return
			}
		catch
			{
			[System.Windows.Forms.MessageBox]::Show("Unable to create user in Active Directory", "Active Directory Error",[System.Windows.Forms.MessageBoxButtons]::OK ,[System.Windows.Forms.MessageBoxIcon]::error)
			}
		
		[String] $SubstringEmployeeID = $Owner.Substring(2,6)
		Set-ADUser -server "domainname.domainsufix" -Identity $accountname -EmployeeID $SubstringEmployeeID
		Set-ADuser -server "domainname.domainsufix" -Identity $accountname -UserPrincipalName $principalname
		
		return $pwdEncrypted
		}
	
	elseif ($userdomain -eq "domainname.domainsufix" -or $userdomain -eq "domainname" -or $userdomain -eq "domainname")
		{
		$principalname = $accountname + "@" + "domainname.domainsufix"

		$accountType = $accountname.substring(0,2)
		#My LAB env, no need to change ou names etc
		try 
			{
			switch ($accountType)
				{
				"FA"
					{
					New-ADUser -name $accountname -DisplayName $accountname -Description $usrdescription -OtherAttributes @{info=$inf} -AccountPassword $pwdEncrypted -CannotChangePassword $true `
					-AccountExpirationDate $expdate -enabled $true -ChangePasswordAtLogon $false -PasswordNeverExpires $true `
					-path "OU=User,OU=Accounts,OU=IT,OU=Business Unites,DC=LAB,DC=corp"
					Write-Host "$Username 	$usrenvironment	$newPWD"
					}
				"TS"
					{
					New-ADUser -name $accountname -DisplayName $accountname -Description $usrdescription -OtherAttributes @{info=$inf} -AccountPassword $pwdEncrypted -CannotChangePassword $true `
					-AccountExpirationDate $expdate -enabled $true -ChangePasswordAtLogon $false -PasswordNeverExpires $true `
					-path "OU=Test,OU=Accounts,OU=Pens,OU=Business Units,DC=LAB,DC=corp"
					Write-Host "$Username 	$usrenvironment	$newPWD"
					}
				"SY"
					{
					New-ADUser -name $accountname -DisplayName $accountname -Description $usrdescription -OtherAttributes @{info=$inf} -AccountPassword $pwdEncrypted -CannotChangePassword $true `
					-AccountExpirationDate $expdate -enabled $true -ChangePasswordAtLogon $false -PasswordNeverExpires $true `
					-path "OU=Service,OU=Accounts,OU=IT,OU=Business Units,DC=LAB,DC=corp"
					Write-Host "$Username 	$usrenvironment	$newPWD"
					}
				"TA"
					{		
					New-ADUser -name $accountname -DisplayName $accountname -Description $usrdescription -OtherAttributes @{info=$inf} -AccountPassword $pwdEncrypted -CannotChangePassword $true `
					-AccountExpirationDate $expdate -enabled $true -ChangePasswordAtLogon $false -PasswordNeverExpires $true `
					-path "OU=Test,OU=Accounts,OU=IT,OU=Business Unites,DC=LAB,DC=corp"
					Write-Host "$Username 	$usrenvironment	$newPWD"
					}
				"EX"
					{
					New-ADUser -name $accountname -DisplayName $accountname -Description $usrdescription -OtherAttributes @{info=$inf} -AccountPassword $pwdEncrypted -CannotChangePassword $true `
					-AccountExpirationDate $expdate -enabled $true -ChangePasswordAtLogon $false -PasswordNeverExpires $true `
					-path "OU=User,OU=Accounts,OU=EWP,OU=Business Unites,DC=LAB,DC=corp"
					Write-Host "$Username 	$usrenvironment	$newPWD"
					}
				}
			}

		catch [Microsoft.ActiveDirectory.Management.ADIdentityAlreadyExistsException]
			{
			[System.Windows.Forms.MessageBox]::Show("User already exists in Active Directory", "Active Directory Error",[System.Windows.Forms.MessageBoxButtons]::OK ,[System.Windows.Forms.MessageBoxIcon]::error)
			return
			}
		catch
			{
			[System.Windows.Forms.MessageBox]::Show("Unable to create user in Active Directory", "Active Directory Error",[System.Windows.Forms.MessageBoxButtons]::OK ,[System.Windows.Forms.MessageBoxIcon]::error)
			}
		
		}

	[String] $SubstringEmployeeID = $owner.Substring(2,6)
	Set-ADUser -Identity $accountname -EmployeeID $SubstringEmployeeID
	Set-ADuser -Identity $accountname -UserPrincipalName $principalname
	
	return $pwdEncrypted
	}

Function Get-FileName($directory)
	{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $directory
    $OpenFileDialog.filter = "CSV (*.csv)| *.csv"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
    
    }

$inputfile = Get-FileName ".\" 	
$csv = Import-Csv $inputfile -Delimiter ";"

#Variables are used to generate e-mail content
$usernameTable = @()
$pwdTable =@()

	
foreach ($line in $csv)
	{
	try 
		{
		$username = $line.username
		$domain = $line.domain
		$environmentinput = $line.environment
		$owner = $line.owner
		$applicationOU = $line.Application
		$info = $line.info
		$notes = $line.description
		$KeePassTitle = $domain + '\' + $username

		
		if ($domain -eq "lab.corp" -or $domain -eq "lab" -or $domain -eq "labcorp")
			{
			$domain = "labcorp"
			$environment = ""
			$applicationOU = "lab.corp"
			}
		elseif ($environmentinput -eq "productie" -or $environmentinput -eq "production" -or $environmentinput -eq "prd" -or $environmentinput -eq "prod")
			{
			$environment = "productie"
			}
		elseif ($environmentinput -eq "acceptatie" -or $environmentinput -eq "acceptance" -or $environmentinput -eq "acc")
			{
			$environment = "acceptatie"
			}
		elseif ($environmentinput -eq "test" -or $environmentinput -eq "tst")
			{
			$environment = "test"
			}
		elseif ($environmentinput -eq "development" -or $environmentinput -eq "dev" -or $environmentinput -eq "ont" -or $environmentinput -eq "ontwikkel")
			{
			$environment = "ontwikkel"
			}
		elseif ($environmentinput -eq "IPI-OTA" -or $environmentinput -eq "IPI" -or $environmentinput -eq "OTA")
			{
			$environment = $environmentinput
			}
		else 
			{
			Write-Host "Probably a typo in environment field in csv for account $username, please check and try again."
			continue
			}
			
		$pwdEncrypted = createAduser $username $domain $applicationOU $environment $owner $info $notes

		$KeePassGroupStatus = Check-ifKeePassFolderExists -GroupName $applicationOU -KeePassDB $DB -PrimaryGroup "Applications"
		$usernameTable += "$username $environment"

		#Convert secure string to string
		$null = ConvertFrom-SecureString -SecureString $pwdEncrypted
		$pwdTable += [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwdEncrypted))
		
		
		if ($KeePassGroupStatus -eq $true)
			{
			try
				{
				Add-KeepassEntry -GroupName $applicationOU -PrimaryGroup "Applications" -KeePassDB $DB -Title $KeePassTitle -Username $username -Password $pwdEncrypted
				Write-Host "App folder already exists, KeePass entry added"
				}
			catch
				{
				Write-Host "Error occured, KeePass entry wasn't added. Probably entry $KeePassTitle already exists"
				}
			}

		elseif ($KeePassGroupStatus -eq $false)
			{
			try
				{
				Add-KeepassGroup -GroupName $applicationOU -KeePassDB $DB -PrimaryGroup "Applications"
				Add-KeepassEntry -GroupName $applicationOU -PrimaryGroup "Applications" -KeePassDB $DB -Title $KeePassTitle -Username $username -Password $pwdEncrypted
				Write-Host "App Folder created, KeePass entry added"
				}
			catch
				{
				Write-Host "Error occured, KeePass entry wasn't added."
				}
			}
		
		else 
			{
			Write-Host "Something went wrong, please check KeePass if new entry exists."
			}
		}
		
		
		catch
		{
		$ErrorMessage = $_.Exception.Message
		if ($ErrorMessage -ne "You cannot call a method on a null-valued expression.")
		 	{
			Write-Host "Unknown error occured."
			Write-Host $ErrorMessage
		    }
		
		}
	}
		$db.close()
