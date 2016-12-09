# Create log folder and file.
# Store path as a string.
$path = "C:\temp\report"

# Create log folder.
New-Item $path -Type directory -Force

# Create unique log file name.
$dateTime = Get-Date -format yyyyMMdd-HHmmss
$logFullPath = $path + "\365UserAnalysis-" + $dateTime + ".txt"

#Create log file.
New-Item $logFullPath -type file -Force
Add-Content -Path $logFullPath -Value "365 User analysis script executed at $datetime"

$mailboxes = Get-Mailbox -ResultSize Unlimited | Select-Object DisplayName, UserPrincipalName, ArchiveStatus, LitigationHoldEnabled, RetentionPolicy, RetentionHoldEnabled, HiddenFromAddressListsEnabled, CustomAttribute1, RecipientTypeDetails

$365Mailboxes = @()

foreach ($mailbox in $mailboxes)
	{
	$mailboxStatistics = Get-MailboxStatistics -Identity $mailbox.UserPrincipalName | Select-Object -Property LastLogonTime, TotalItemSize, TotalDeletedItemSize
	Write-Host "."

        if ($mailboxStatistics.LastLogonTime)
            {
                $lastLogonTime = $mailboxStatistics.LastLogonTime.ToShortDateString()
            }
        else 
            {
                $lastLogonTime = "Never"
            }  

        $mailbox | Add-Member -type NoteProperty -name LastLogonTime -value $lastLogonTime
        $mailbox | Add-Member -type NoteProperty -Name ItemSize -Value $mailboxStatistics.TotalItemSize.value 
        $mailbox | Add-Member -type NoteProperty -Name DeletedItemSize -Value $mailboxStatistics.TotalDeletedItemSize.value 

        $msolData = Get-MsolUser -UserPrincipalName $mailbox.UserPrincipalName | Select-Object -Property IsLicensed, Licenses, BlockCredential
		

        Write-Host ".."
	$license = @()
    Switch -Wildcard ($msolData.Licenses.AccountSkuId)
           {
           "*:ENTERPRISEPACK" { $license += "Enterprise 3" }
           "*:STANDARDWOFFPACK" { $license += "Enterprise 2" }
           "*:STANDARDPACK" { $license += "Enterprise 1" }
           "*:EXCHANGESTANDARD" { $license += "Exchange 1" }
           "*:SHAREPOINTSTANDARD" { $license += "SharePoint 1" }
           "*:POWER_BI_STANDARD" { $license += "Power Bi 1" }
           "*:PROJECTONLINE_PLAN_1" { $license += "Project 1" }
           "*:INTUNE_A" { $license += "Intune" }
           "*:EMS" { $license += "EMS"}
           }
        
        $365Mailboxes += $mailbox | Select-Object DisplayName, UserPrincipalName, @{L='Disabled'; E={$msolData.BlockCredential}}, CustomAttribute1, RecipientTypeDetails, ArchiveStatus, LitigationHoldEnabled, RetentionPolicy, RetentionHoldEnabled, HiddenFromAddressListsEnabled, LastLogonTime, ItemSize, DeletedItemSize, @{L='Licenses'; E={$license}} 
        Write-Host "..."

	}

$365MailboxesSorted = $365Mailboxes | Sort-Object -property DisplayName

$outputPath = $path + "\365UserAnalysis-" + $dateTime + ".csv"

$365MailboxesSorted | Export-Csv -path $outputPath -notypeinformation

Add-Content -Path $logFullPath -Value "365 user analysis done."