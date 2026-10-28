# Red y nombre
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 10.23.56.138 -PrefixLength 29 -DefaultGateway 10.23.56.137
Rename-NetAdapter -Name "Ethernet" -NewName "LAN-SERVIDORES"
Set-TimeZone -Id "SA Western Standard Time"
Rename-Computer -NewName "DC-NPS" -Restart

# Active Directory + DNS
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
Install-ADDSForest -DomainName "itla.local" -DomainNetbiosName "ITLA" -InstallDns -Force -SafeModeAdministratorPassword (Read-Host -AsSecureString "Contrasena DSRM")
Set-DnsClientServerAddress -InterfaceAlias "LAN-SERVIDORES" -ServerAddresses 127.0.0.1

# OU, grupos y usuarios
New-ADOrganizationalUnit -Name "Red-AAA" -Path "DC=itla,DC=local"
$ou = "OU=Red-AAA,DC=itla,DC=local"
New-ADGroup -Name "AAA-Nivel0"  -GroupScope Global -Path $ou -Description "Privilegio 0"
New-ADGroup -Name "AAA-Nivel5"  -GroupScope Global -Path $ou -Description "Privilegio 5"
New-ADGroup -Name "AAA-Nivel10" -GroupScope Global -Path $ou -Description "Privilegio 10"
$p = Read-Host -AsSecureString "Contrasena de los usuarios"
New-ADUser -Name "Luis Martinez" -SamAccountName "lmartinez" -UserPrincipalName "lmartinez@itla.local" -Path $ou -AccountPassword $p -Enabled $true -PasswordNeverExpires $true
New-ADUser -Name "Pedro Garcia"  -SamAccountName "pgarcia"   -UserPrincipalName "pgarcia@itla.local"   -Path $ou -AccountPassword $p -Enabled $true -PasswordNeverExpires $true
New-ADUser -Name "Ana Gomez"     -SamAccountName "agomez"    -UserPrincipalName "agomez@itla.local"    -Path $ou -AccountPassword $p -Enabled $true -PasswordNeverExpires $true
Add-ADGroupMember -Identity "AAA-Nivel0"  -Members "lmartinez"
Add-ADGroupMember -Identity "AAA-Nivel5"  -Members "pgarcia"
Add-ADGroupMember -Identity "AAA-Nivel10" -Members "agomez"

# NPS y clientes RADIUS
Install-WindowsFeature NPAS -IncludeManagementTools
Add-ADGroupMember -Identity "RAS and IAS Servers" -Members "DC-NPS$"
Restart-Service IAS
New-NpsRadiusClient -Name "R-AAA"  -Address 10.23.56.137 -SharedSecret "<SHARED-SECRET>"
New-NpsRadiusClient -Name "SW-AAA" -Address 10.23.56.130 -SharedSecret "<SHARED-SECRET>"
New-NetFirewallRule -DisplayName "RADIUS desde R-AAA y SW-AAA" -Direction Inbound -Protocol UDP -LocalPort 1812,1813 -RemoteAddress 10.23.56.137,10.23.56.130 -Action Allow
Restart-Service IAS
auditpol /set /subcategory:"Network Policy Server" /success:enable /failure:enable

# Network Policies (GUI: nps.msc):
#   Cisco-Nivel10 | ITLA\AAA-Nivel10 | Cisco-AV-Pair = shell:priv-lvl=10
#   Cisco-Nivel5  | ITLA\AAA-Nivel5  | Cisco-AV-Pair = shell:priv-lvl=5
#   Cisco-Nivel0  | ITLA\AAA-Nivel0  | Cisco-AV-Pair = shell:priv-lvl=0
#   Autenticacion: solo PAP | Standard: quitar Framed-Protocol, Service-Type = Login
