# This script automatically locks the mailbox of the 

DO
{
Get-MsolUser | Where { $_.isLicensed -eq "True"} | FT UserPrincipalName, BlockCredential
$input = Read-Host "Who would you like to modify? Please type their UserPrincipalName" 
Get-MsolUser -UserPrincipalName $input | FT DisplayName, BlockCredential
$Target = Get-MsolUser -UserPrincipalName $input
if  ($Target.BlockCredential)
    {
    $Forgive = Read-Host $Target.DisplayName "is currently blocked. Do you want to restore access? (y/n) "
    if ($Forgive -like "y")
        {
        Write-Host "Unblocking " $Target.DisplayName
        Set-MsolUser -UserPrincipalName $Target.UserPrincipalName -BlockCredential $False
        }
    }
Else
    {
    $Spank = Read-Host $Target.DisplayName "is currently NOT blocked. Do you want to Block them? (y/n)"
    if ($Spank -like "y")
        {
        Write-Host "Blocking " $Target.DisplayName
        Set-MsolUser -UserPrincipalName $Target.UserPrincipalName -BlockCredential $True
        }
    }
$Cont = Read-Host "Would you like to modify another user?" 
} While ($Cont -like "y")
