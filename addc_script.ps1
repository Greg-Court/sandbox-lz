$password = ConvertTo-SecureString '${password}' -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential('${username}', $password)

# Install AD-Domain-Services feature
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Promote the server to a Domain Controller
Install-ADDSForest -DomainName '${active_directory_domain}' -InstallDns -SafeModeAdministratorPassword $password -Force

# Add a DNS forwarder to firewall IP
Add-DnsServerForwarder -IPAddress '${firewall_private_ip}'