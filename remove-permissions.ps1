#   :::  Script :::

$killer = Read-Host "Please provide SMTP of user to terminate"
$kill = Get-Mailbox $killer

$everyone = Get-Mailbox -ResultSize unlimited

ForEach($mb in ($everyone) )
{
$perms = Get-MailboxPermission $mb.alias | Where Where { ($_.User.contains($kill.DisplayName) -eq $True) -or ($_.User.contains($kill.UserPrincipalName) -eq $True) }
Write-host $mb.alias
if ( $perms )
     {
     Write-host 'Updating FullAccess permissions on' $mb.alias
     Remove-MailboxPermission -Identity $mb.alias -User $kill.UserPrincipalName -AccessRights FullAccess
     }

$send = Get-RecipientPermission $mb.alias | Where {$_.Trustee.contains($kill.DisplayName) -eq $True }
Write-host ".."
if ( $send )
     {
     Write-host 'Updating Send As permissions on' $mb.alias
     Remove-RecipientPermission -Identity $mb.alias -Trustee $kill.UserPrincipalName -AccessRights SendAs
     }

$cal = $mb.alias+':\Calendar';
$fold = Get-MailboxFolderPermission $cal | Where {$_.User.displayname.contains($kill.DisplayName) -eq $True }
Write-host "..."
if ( $fold )
     {
     Write-host 'Updating Calendar permissions on' $cal
     Remove-MailboxFolderPermission -Identity $cal -User $kill.UserPrincipalName
     }
          
}

#   ::: End Script :::
