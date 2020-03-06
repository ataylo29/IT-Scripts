#This will be a  script for loaners in general. It will contain a switch statement to choose what action to do
#It will contain a refresh script, loaner account add, the ability to add a user to the admin group and more to come

#This script begins with this because I need to make sure it will have admin rights as PowerShell requires it
#for some of the functions

<#
This part of the code is only for testing purposes. It does not work when you convert the code to an exe.
There is a setting in the conversion program to force the exe to run as an admin. It will only ask to run 
powershell as admin then end if you use the below if statement
#>
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{   
    #"No Administrative rights, it will display a popup window asking user for Admin rights"

    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process "$psHome\powershell.exe" -Verb runAs -ArgumentList $arguments

    break
}

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
    }

}

#This function will add a user to the local admin group
function addToAdmin
{
    $USER = Read-Host -Prompt "Who would you like to add to the Admin group? (username)"
    $group = "Administrators";
    $groupObj =[ADSI]"WinNT://./$group,group" 
    $membersObj = @($groupObj.psbase.Invoke("Members")) 

    $members = ($membersObj | foreach {$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)})

    #tests to see what members looks like as a output for future upgrades
    #Write-Host "$($members)"

    Write-Host "Testing to see if the user $($USER) is already an admin"

    if($members -contains $USER)
    {
        Write-Host "User is in group"
    }
    else
    {
        Write-Host "User $($USER) is not in the Admin group and will be added"
        Add-LocalGroupMember -Group $group -Member $USER
        Write-Host "User has been added"
    }


    Write-Host -NoNewline 'Press any key to continue...';
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
}

function addCurrentUsrToAdmin
{
    $User = $env:UserName
    $Group = "Administrators";
    $GroupObj =[ADSI]"WinNT://./$Group,group" 
    $MembersObj = @($groupObj.psbase.Invoke("Members")) 

    $Members = ($MembersObj | foreach {$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)})

    Write-Host "Testing to see if $($User) is already in the admin group..."

    if($Members -contains $User)
    {
        Write-Host "User is in the Admin group"
    }
    else
    {
        Write-Host "User $($User) is not in the admin goup and will be added"
        Add-LocalGroupMember -Group $Group -Member $USER
        Write-Host "User has been added. Run a gpupdate and restart if needed"
    }

    Write-Host -NoNewline 'Press any key to continue...'; $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
}

function adminUsrOptions
{
    $condition = 0

    While($condition -eq 0)
    {
        Clear-Host
        Write-Host "Please choose the correct option for what you need done"
        Write-Host "Press 1 if you are not logged into the user that needs to be added to the admin group"
        Write-Host "Press 2 if the current logged in user is the user that needs to be added to the admin group"
        Write-Host "Press 3 to return to the main menu"
        $choice = Read-Host -Prompt "Which option would you like to do?"

        switch($choice)
        {
            1 {addToAdmin; $condition = 1; break}
            2 {addCurrentUsrToAdmin; $condition = 1; break}
            3 {$condition = 1; break}
            default {Write-Host -NoNewline "Incorrect choice. Hit any key to try again "; $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown'); break}
        }
    }
}

$Condition = 0

While($Condition -eq 0)
{
    Clear-Host
    Write-Host 'Welcome to the loaner script!!'
    Write-Host 'Please choose what function you would like to do:'
    Write-Host 'Press 1 to refresh the loaner'
    Write-Host 'Press 2 to add/delete loaner account'
    Write-Host 'Press 3 to add user to local admin options'
    Write-Host 'Press 4 to exit this program'
    $Choice = Read-Host -Prompt "Which option would you like to do?"

    switch($Choice)
    {
        1 {RefreshLoaner; break}
        2 {LoanerAcct; break}
        3 {adminUsrOptions; break}
        4 {$Condition = 1; break}
        default {Write-Host -NoNewline "Incorrect choice. Hit any key to try again "; $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown'); break}
    }
}