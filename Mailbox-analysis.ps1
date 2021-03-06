# Creates a CSV file for the following Mailbox and MSOLUser attributes:
# DisplayName, UserPrincipalName, ArchiveStatus, LitigationHoldEnabled, 
# RetentionPolicy, RetentionHoldEnabled, HiddenFromAddressListsEnabled, 
# IsLicensed, Licenses
#
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

$mailboxes = Get-Mailbox -ResultSize Unlimited | Select-Object DisplayName, UserPrincipalName, ArchiveStatus, LitigationHoldEnabled, RetentionPolicy, RetentionHoldEnabled, HiddenFromAddressListsEnabled

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

        $msolData = Get-MsolUser -UserPrincipalName $mailbox.UserPrincipalName | Select-Object -Property IsLicensed,Licenses
		
    ForEach ($license in $msolData.Licenses.AccountSkuId)
        {
        Write-Host ".."
	Switch -Wildcard ($license)
           {
           "*:ENTERPRISEPACK" { $mailbox | Add-Member -type NoteProperty -name LicenseType -value "E3" ; break }
           "*:STANDARDWOFFPACK" { $mailbox | Add-Member -type NoteProperty -name LicenseType -value "E2" ; break }
           "*:STANDARDPACK" { $mailbox | Add-Member -type NoteProperty -name LicenseType -value "E1" ; break }
           "*:PROJECTONLINE_PLAN_1" { $mailbox | Add-Member -type NoteProperty -name ProjectLicense -value "Plan 1" ; break }
           }
        
	$365Mailboxes += $mailbox
        Write-Host "..."
	}
	}

$365MailboxesSorted = $365Mailboxes | Sort-Object -property DisplayName

$outputPath = $path + "\365UserAnalysis-" + $dateTime + ".csv"

$365Mailboxes | Export-Csv -path $outputPath -notypeinformation

Add-Content -Path $logFullPath -Value "365 user analysis done."
