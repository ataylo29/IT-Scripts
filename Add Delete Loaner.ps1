$USERNAME = "loaner"
$PASSWORD = ConvertTo-SecureString "b0rr0wIT" -AsPlainText -Force
$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"
$ObjLocalUser = $null

try
{
    Write-Verbose "Testing to see if the user $($USERNAME) is a user already"
    $ObjLocalUser = Get-LocalUser $USERNAME
    Write-Verbose "User $($USERNAME) was found"
}
catch [Microsoft.PowerShell.Commands.UserNotFoundException]
{
    "User $($USERNAME) was not found" | Write-Warning
}
catch
{
    "An unspecified error has occured" | Write-Error
}

if ($ObjLocalUser-eq $null)
{
    Write-Host "Making the user $($USERNAME) right now"
    New-LocalUser $USERNAME -FullName 'Loaner' -Password $PASSWORD -PasswordNeverExpires -UserMayNotChangePassword
    Write-Host "The user $($USERNAME) has been created"
    Write-Host "Press any key to continue..."; $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeydown');
}
else
{
    Write-Host "Deleting the user $($USERNAME)"
    Remove-LocalUser $USERNAME
    $ObjLocalUser = $null
    try
    {
        Write-Host "Testing to see if the user $($USERNAME) has been deleted"
        $ObjLocalUser = Get-LocalUser $USERNAME
        Write-Verbose "User $($USERNAME) is still there for some reason"
        Write-Host -NoNewline "It could not delete the loaner account for some reason. Ending now.";
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
        Write-Host ""
        Exit
    }
    catch [Microsoft.PowerShell.Commands.UserNotFoundException]
    {
        "User $($USERNAME) was deleted properly" | Write-Verbose
    }
    catch
    {
        "An unspecified error has occured" | Write-Error
    }
    Write-Host "Now to create the $($USERNAME) account"
    New-LocalUser $USERNAME -FullName 'Loaner' -Password $PASSWORD -PasswordNeverExpires -UserMayNotChangePassword
    Write-Host "The user $($USERNAME) has been created"
    Write-Host -NoNewline "Press any key to continue..."; $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
    Write-Host ""
}