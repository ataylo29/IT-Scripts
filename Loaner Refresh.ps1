#Function that will delete user profiles from the computer execpt for a couple of specific ones
function refreshLoaner
{
    $ErrorActionPreference = 'silentlycontinue'

    $Users = Get-WmiObject -Class Win32_UserProfile
    $IgnoreList = "helpdesk", "Administrator", "Default"

    :OuterLoop
    foreach($user in $Users)
    {  
        foreach($name in $IgnoreList)
        {    
            if($user.localpath -like "*\$name")
            {
                continue OuterLoop
            }
        }
        Write-Host "$($user.localpath) is about to be deleted"
        $user.Delete()
        Write-Host "$($user.localpath) has been deleted"
    }
    Write-Host -NoNewline "Press any key to continue..."; $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
}

#This function will test for if the loaner account is there and add it if needed
#And it will also delete the loaner account and re-add it and test to see if it can do that
function loanerAcct
{
    $Password = ConvertTo-SecureString 'b0rr0wIT' -AsPlainText -Force
    $ErrorActionPreference = 'Stop'
    $VerbosePreference = 'Continue'

    #User to search
    $USERNAME = 'loaner'

    #Declare LocalUser object
    $ObjLocalUser = $null

    try
    {
        Write-Verbose "Testing to see if $($USERNAME) is a user already"
        $ObjLocalUser = Get-LocalUser $USERNAME
        Write-Verbose "The user $($USERNAME) was found"
    }
    
    catch [Microsoft.PowerShell.Commands.UserNotFoundException]
    {
        "User $($USERNAME) not found" | Write-Warning
    }

    catch
    {
        "An unspecified error occured. Congrats, ya played yourself" | Write-Error
    }

    if($ObjLocalUser -eq $null)
    {
        Write-Host "Making the user $($USERNAME) real quick"
        New-LocalUser 'loaner' -FullName 'Loaner' -Password $Password -PasswordNeverExpires -UserMayNotChangePassword
        Write-Host "Cool beans, the user $($USERNAME) now exists"
        Write-Host -NoNewLine 'Press any key to continue...';
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
    }
    else
    {
        Write-Host "Deleteing the $($USERNAME) user account"
        Remove-LocalUser $USERNAME
        $ObjLocalUser = $null
        try 
        {
            Write-Verbose "Testing to see if the account was actually deleted"
            $ObjLocalUser = Get-LocalUser $USERNAME
            Write-Verbose "User $($USERNAME) is still here, ending script"
            Write-Host -NoNewLine 'Press any key to continue...';
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
            Write-Host ""
            Exit
            
        }
        catch [Microsoft.PowerShell.Commands.UserNotFoundException]
        {
            "User $($USERNAME) was deleted properly" | Write-Host
        }
        catch
        {
            "Unknown error has occured, UH-OH" | Write-Error
        }

        Write-Host "Now to create the $($USERNAME) account"
        New-LocalUser $USERNAME -FullName "Loaner" -Password $Password -PasswordNeverExpires -UserMayNotChangePassword
        Write-Host "The user $($USERNAME) was created"
        Write-Host -NoNewLine 'Press any key to continue...';
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
        Write-Host ""
    }

}

Write-Host "Welcome to the loaner refresh script by Andrew Taylor. It's here for your loaner refreshing needs"
Write-Host "The code will be available in the 4helpdesk folder in the I:\ drive if you want to look at it"
Write-Host -NoNewline "Press any key to continue..."; $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
Write-Host ""
loanerAcct
refreshLoaner