$Owner = Read-Host -Prompt 'Input the requested AA-account (without AA)'
echo ""
echo "Type 1 for domainname.domainsufix"
echo "Type 2 for domainname.domainsufix"
echo "Type 3 for domainname.domainsufix" 
echo "Type 4 for domainname.domainsufix"

$DomainSelect = Read-Host -Prompt 'Make your choice:'
    if ( $DomainSelect -eq 1 ) { $server = 'servername.domainname.domainsufix'
	$domain = "domainname.domainsufix"}
	elseif ( $DomainSelect -eq 2 ) { $server = 'servername.domainname.domainsufix'
	$domain = "domainname.domainsufix"}
    elseif ( $DomainSelect -eq 3 ) { $server = 'servername.domainname.domainsufix'
	$domain = "domainname.domainsufix"}
    elseif ( $DomainSelect -eq 4 ) { $server = 'servername.domainname.domainsufix'
	$domain = "domainname.domainsufix"}

    $TodayDate = Get-Date -Format "MM-dd-yyyy"
    $DirectoryName = 'AA' + $Owner + '-' + $domain + '-' + $TodayDate
    $GroupsFileName = 'AA' + $Owner + '-' + $domain + '-groups' + '.csv'
    $AccountsFileName = 'AA' + $Owner + '-' + $domain + '-accounts' + '.csv'
    new-item -Name $DirectoryName -ItemType directory -Force
    Get-ADUser -filter {EmployeeID -like $Owner} -Properties * -server $server | Select Name, DistinguishedName, enabled, EmployeeID, AccountExpirationDate, @{Name="accountExpires";Expression={[datetime]::FromFileTime($_.accountExpires)}}, @{Name="lastLogon";Expression={[datetime]::FromFileTime($_.lastLogon)}}, whenChanged, whenCreated, @{Name="pwdLastSet";Expression={[datetime]::FromFileTime($_.pwdLastSet)}}, AccountLockoutTime, AccountNotDelegated, AllowReversiblePasswordEncryption, AuthenticationPolicy, AuthenticationPolicySilo, BadLogonCount, badPwdCount, CannotChangePassword, CanonicalName, Certificates, City, CN, codePage, Company, CompoundIdentitySupported, Country, countryCode, Created, createTimeStamp, Deleted, Department, Description, DisplayName, Division, DoesNotRequirePreAuth, dSCorePropagationData, EmailAddress, EmployeeNumber, Fax, GivenName, HomeDirectory, HomedirRequired, HomeDrive, HomePage, HomePhone, Initials, instanceType, isDeleted, KerberosEncryptionType, LastBadPasswordAttempt, LastKnownParent, lastLogoff, LockedOut, lockoutTime, logonCount, LogonWorkstations, Manager, MemberOf, MNSLogonAccount, MobilePhone, Modified, modifyTimeStamp, msDS-SupportedEncryptionTypes, msDS-User-Account-Control-Computed, msTSExpireDate, msTSLicenseVersion, msTSManagingLS, nTSecurityDescriptor, ObjectCategory, ObjectClass, ObjectGUID, objectSid, Office, OfficePhone, Organization, OtherName, PasswordExpired, PasswordLastSet, PasswordNeverExpires, PasswordNotRequired, POBox, PostalCode, PrimaryGroup, primaryGroupID, PrincipalsAllowedToDelegateToAccount, ProfilePath, ProtectedFromAccidentalDeletion, SamAccountName, sAMAccountType, ScriptPath, sDRightsEffective, ServicePrincipalNames, SID, SIDHistory, SmartcardLogonRequired, State, StreetAddress, Surname, Title, TrustedForDelegation, TrustedToAuthForDelegation, UseDESKeyOnly, userAccountControl, userCertificate, UserPrincipalName, uSNChanged, uSNCreated, PropertyNames, AddedProperties, RemovedProperties, ModifiedProperties, PropertyCount, @{Name="LastLogonTimeStamp";Expression={[datetime]::FromFileTime($_.lastlogontimestamp)}}, @{Name="badPasswordTime";Expression={[datetime]::FromFileTime($_.badPasswordTime)}}, @{Name="LastLogonDate";Expression={[datetime]::FromFileTime($_.LastLogonDate)}} | Export-Csv -Path $DirectoryName\$AccountsFileName -UseCulture -NoTypeInformation 
    Get-ADGroup -filter {adminDisplayName -like $Owner} -Properties * -server $server | Select Name, whenChanged, whenCreated | Export-Csv -Path $DirectoryName\$GroupsFileName -UseCulture -NoTypeInformation

echo 'Export is done! '
Write-Host 'You can find the results in the folder' $DirectoryName 
