#   Display Name                      Service Name

#   Double-Take                       Double-Take
#   Double-Take Management Service    CoreManagementService



param(
    [switch]$local,                                            # If $local = $true, run only with local machine as host.
    [string]$path='[Environment]::GetFolderPath("Desktop")',   # Allow for custom input file directory. Assume Desktop.
    [string]$name='computers.txt',                              # Allow for custom input file name. Assume 'computers.txt'.
    [string]$logSuffix=''
)

#Credential
$username = Read-Host -Prompt "Username: "
$password = Read-Host -Prompt "Password: "
$secpw = ConvertTo-SecureString $password -AsPlainText -Force
$global:cred  = New-Object Management.Automation.PSCredential ($username, $secpw)

Function Start-DoubleTake {
    Param(
        [string]$hostname = $env:COMPUTERNAME
    )
    Begin{
        $ServiceStatus = Test-WSMan $hostname
        while (!$ServiceStatus){
            Invoke-Command -ComputerName $hostname -Credential $global:cred -ScriptBlock {Start-Service winrm}
            $ServiceStatus = Test-WSMan $hostname
        }
    }
    Process{
        $ServiceStatus = Invoke-Command -ComputerName $hostname -Credential $global:cred -ScriptBlock {Get-Service -Name Double-Take}

        while (!$ServiceStatus.Status -eq 'Running'){
            Invoke-Command -ComputerName $hostname -Credential $global:cred -ScriptBlock {Start-Service Double-Take}
            Start-Sleep -Seconds 5
            $ServiceStatus = Invoke-Command -ComputerName $hostname -Credential $global:cred -ScriptBlock {Get-Service -Name Double-Take}
        }
    }
    End{
        Write-Host "Successfully started Double-Take on $hostname"
    }
}



Function Stop-DoubleTake {
    Param(
        [string]$hostname = $env:COMPUTERNAME
    )
    Begin{
        $ServiceStatus = Test-WSMan $hostname
        while (!$ServiceStatus){
            Invoke-Command -ComputerName $hostname -Credential $global:cred -ScriptBlock {Stop-Service winrm}
            $ServiceStatus = Test-WSMan $hostname
        }
    }
    Process{
        $ServiceStatus = Invoke-Command -ComputerName $hostname -Credential $global:cred -ScriptBlock {Get-Service -Name Double-Take}

        while ($ServiceStatus.Status -eq 'Running'){
            Invoke-Command -ComputerName $hostname -Credential $global:cred -ScriptBlock {Stop-Service Double-Take}
            Start-Sleep -Seconds 8
            $ServiceStatus = Invoke-Command -ComputerName $hostname -Credential $global:cred -ScriptBlock {Get-Service -Name Double-Take}
        }
    }
    End{
        Write-Host "Successfully stopped Double-Take on $hostname"
    }
}



Function Start-CoreManagementService {
    Param(
        [string]$hostname = $env:COMPUTERNAME
    )
    Begin{
        $ServiceStatus = Test-WSMan $hostname
        while (!$ServiceStatus){
            Invoke-Command -ComputerName $hostname -Credential $global:cred -ScriptBlock {Start-Service winrm}
            $ServiceStatus = Test-WSMan $hostname
        }
    }
    Process{
        $ServiceStatus = Invoke-Command -ComputerName $hostname -Credential $global:cred -ScriptBlock {Get-Service -Name CoreManagementService}

        while (!$ServiceStatus.Status -eq 'Running'){
            Invoke-Command -ComputerName $hostname -Credential $global:cred -ScriptBlock {Stop-Service CoreManagementService}
            Start-Sleep -Seconds 5
            $ServiceStatus = Invoke-Command -ComputerName $hostname -Credential $global:cred -ScriptBlock {Get-Service -Name CoreManagementService}
        }
    }
    End{
        Write-Host "Successfully started CoreManagementService on $hostname"
    }
}



Function Stop-CoreManagementService {
    Param(
        [string]$hostname = $env:COMPUTERNAME
    )
    Begin{
        $ServiceStatus = Test-WSMan $hostname
        while (!$ServiceStatus){
            Invoke-Command -ComputerName $hostname -Credential $global:cred -ScriptBlock {Stop-Service winrm}
            $ServiceStatus = Test-WSMan $hostname
        }
    }
    Process{
        $ServiceStatus = Invoke-Command -ComputerName $hostname -Credential $global:cred -ScriptBlock {Get-Service -Name CoreManagementService}

        while ($ServiceStatus.Status -eq 'Running'){
            Invoke-Command -ComputerName $hostname -Credential $global:cred -ScriptBlock {Stop-Service CoreManagementService}
            Start-Sleep -Seconds 8
            $ServiceStatus = Invoke-Command -ComputerName $hostname -Credential $global:cred -ScriptBlock {Get-Service -Name CoreManagementService}
        }
    }
    End{
        Write-Host "Successfully stopped CoreManagementService on $hostname"
    }
}



$userInput = @() 

Write-Host "Which servers would you like to restart services on?"
Write-Host "One hostname per line"
Write-Host "===================================================="
# Prompt user for input
$userInputString = Read-Host "Enter a hostname or 'q' to quit"

# Create while loop
while($userInputString -ne "q" -and $userInputString -ne "quit")
{
    # Add string to array
    $userInput += $userInputString

    # Prompt user for next input
    $userInputString = Read-Host "Hostname"
}

# Output final array
Write-Output $userInput

ForEach($hostname in $userInput) {
    Stop-DoubleTake $hostname
    Stop-CoreManagementService $hostname
    Start-Sleep -Seconds 2
    Start-DoubleTake $hostname
    Start-CoreManagementService $hostname
    Start-Sleep -Seconds 2
}