$delete=$args[0] # capture argument if sent as paramer

$computername = "computer-name"
$zonename = "zone.name"

# Read records to be modified from csv
$InputFile = "C:\Users\username\Desktop\dnsrecords.csv"
$csvRecords = Import-CSV $InputFile

# Get all Zone
$DnsServerZones = Get-DnsServerZone

# Create Zone if doesn't exist
ForEach ($csvRecord in $csvRecords){
    $foundZone = 0
 
    # Loop through the zone names to check if the zone given in csv exist
    ForEach ($DnsServerZone in $DnsServerZones){
        If ($csvRecord.zonename -eq $DnsServerZone.ZoneName){
            $foundZone = 1
        }
    }

    # If zone name from CSV doesn't match with any record in server then create the zone
    If (-Not $foundZone){
        # Create new Primary zone
        Add-DnsServerPrimaryZone -Name $csvRecord.zonename -ReplicationScope "Forest" -PassThru
    }
}

# EDIT/ADD Records
# parse through each record in csv file
ForEach ($csvRecord in $csvRecords){
    # Flag variable to check if the record is found in server
    $foundRecord = 0
    
    # Collect all DNS records from the zone
    $zonename = $csvRecord.zonename
    $machineRecords = Get-DnsServerResourceRecord -ZoneName $zonename

    # EDIT
    # loop through the records collection to get individual record
    ForEach ($machineRecord in $machineRecords){

        # If csv record name exists in server then EDIT
        If ($csvRecord.name -eq $machineRecord.HostName){
            # set to one when record found
            $foundRecord = 1

            # Check and Modify A record | If record type is A and csv record doesn't match server record
            If (($csvRecord.type -eq "A") -and ( -Not ($machineRecord.RecordData.IPv4Address.IPAddressToString -contains $csvRecord.value ))){
                # Get two identical objects representing a DNS record
                $Objects = Get-DnsServerResourceRecord -ZoneName $zonename -RRType $csvRecord.type -Name $csvRecord.name
               
                ForEach ($OldObj in $Objects){
                    $NewObj = $OldObj.clone()

                    # Change IPv4 on the new object
                    $NewObj.RecordData.IPv4Address = [System.Net.IPAddress]::parse($csvRecord.value)

                    # ttl
                    $NewObj.TimeToLive = [System.TimeSpan]::FromSeconds($csvRecord.ttl)

                    $newMachineRecord = Get-DnsServerResourceRecord -ZoneName $zonename -RRType A -Name $machineRecord.HostName
                    # If csv record is not present in machine record
                    If (-Not($newMachineRecord.RecordData.IPv4Address.IPAddressToString -contains $NewObj.RecordData.IPv4Address.IPAddressToString)) {
                        # Update record on the server
                        Set-DNSServerResourceRecord -NewInputObject $NewObj -OldInputObject $OldObj -ZoneName $zonename -PassThru
                    }
                }
            }

            # Check and Modify CNAME record | If record type is CNAME and csv record doesn't match server record
            If (($csvRecord.type -eq "CNAME") -and ($csvRecord.value -ne $machineRecord.RecordData.HostNameAlias) ){
                # Get two identical objects representing a DNS record
                $OldObj = Get-DnsServerResourceRecord -ZoneName $zonename -RRType $csvRecord.type -Name $csvRecord.name
                $NewObj = $OldObj.clone()

                # Change CNAME on the new object
                $NewObj.RecordData.HostNameAlias = $csvRecord.value

                # ttl
                $NewObj.TimeToLive = [System.TimeSpan]::FromSeconds($csvRecord.ttl)

                # Update record on the server
                Set-DNSServerResourceRecord -NewInputObject $NewObj -OldInputObject $OldObj -ZoneName $zonename -PassThru

            }

            # Check and Modify SRV record | If record type is SRV and csv record doesn't match server record
            If (($csvRecord.type -eq "SRV") -and ($csvRecord.domainname -ne $machineRecord.RecordData.DomainName) ){
                # Get two identical objects representing a DNS record
                $Objects = Get-DnsServerResourceRecord -ZoneName $zonename -RRType $csvRecord.type -Name $csvRecord.name
                
                ForEach ($OldObj in $Objects){
                    $NewObj = $OldObj.clone()

                    # Change SRV records on the new object
                    $NewObj.RecordData.DomainName = $csvRecord.domainname
                    $NewObj.RecordData.Weight = $csvRecord.weight
                    $NewObj.RecordData.Priority = $csvRecord.priority
                    $NewObj.RecordData.Port = $csvRecord.port

                    # ttl
                    $NewObj.TimeToLive = [System.TimeSpan]::FromSeconds($csvRecord.ttl)

                    $newMachineRecord = Get-DnsServerResourceRecord -ZoneName $zonename -RRType SRV -Name $machineRecord.HostName

                    # If csv record is not present in machine record
                    If (-Not($newMachineRecord.RecordData.DomainName -contains $NewObj.RecordData.DomainName)) {
                        # Update record on the server
                        Set-DNSServerResourceRecord -NewInputObject $NewObj -OldInputObject $OldObj -ZoneName $zonename -PassThru
                    }
                }
            }

            # Check and Modify AAAA record | If record type is AAAA and csv record doesn't match server record
            If (($csvRecord.type -eq "AAAA") -and ($csvRecord.value -ne $machineRecord.RecordData.IPv6Address) ){
                # Get two identical objects representing a DNS record
                $OldObj = Get-DnsServerResourceRecord -ZoneName $zonename -RRType $csvRecord.type -Name $csvRecord.name
                $NewObj = $OldObj.clone()

                # Change AAAA on the new object
                $NewObj.RecordData.IPv6Address = $csvRecord.value

                # ttl
                $NewObj.TimeToLive = [System.TimeSpan]::FromSeconds($csvRecord.ttl)

                # Update record on the server
                Set-DNSServerResourceRecord -NewInputObject $NewObj -OldInputObject $OldObj -ZoneName $zonename -PassThru

            }

            # Check and Modify PTR record | If record type is PTR and csv record doesn't match server record
            If (($csvRecord.type -eq "PTR") -and ($csvRecord.value -ne $machineRecord.RecordData.PtrDomainName) ){
                # Get two identical objects representing a DNS record
                $OldObj = Get-DnsServerResourceRecord -ZoneName $zonename -RRType $csvRecord.type -Name $csvRecord.name
                $NewObj = $OldObj.clone()

                # Change PTR on the new object
                $NewObj.RecordData.PtrDomainName = $csvRecord.value

                # ttl
                $NewObj.TimeToLive = [System.TimeSpan]::FromSeconds($csvRecord.ttl)

                # Update record on the server
                Set-DNSServerResourceRecord -NewInputObject $NewObj -OldInputObject $OldObj -ZoneName $zonename -PassThru

            }

            # Check and Modify MX record | If record type is MX and csv record doesn't match server record
            If (($csvRecord.type -eq "MX") -and ($csvRecord.value -ne $machineRecord.RecordData.MailExchange) ){
                # Get two identical objects representing a DNS record
                $OldObj = Get-DnsServerResourceRecord -ZoneName $zonename -RRType $csvRecord.type -Name $csvRecord.name
                $NewObj = $OldObj.clone()

                # Change MX record on the new object
                $NewObj.RecordData.MailExchange = $csvRecord.value
                $NewObj.RecordData.Preference = $csvRecord.preference

                # ttl
                $NewObj.TimeToLive = [System.TimeSpan]::FromSeconds($csvRecord.ttl)

                # Update record on the server
                Set-DNSServerResourceRecord -NewInputObject $NewObj -OldInputObject $OldObj -ZoneName $zonename -PassThru

            }

        }
    }

    # ADD
    # Check if found flag is true/false | If record not found in the server then create

    If (-Not $foundRecord){
        # A record
        If ($csvRecord.type -eq "A"){
            # set ttl
            $time = [System.TimeSpan]::FromSeconds($csvRecord.ttl)
            $timeToLive = "{0:HH:mm:ss}" -f ([datetime]$time.Ticks)

            Add-DnsServerResourceRecord -ZoneName $zonename -A -Name $csvRecord.name -IPv4Address $csvRecord.value -TimeToLive $timeToLive
        }

        # CNAME record
        If ($csvRecord.type -eq "CNAME"){
            # set ttl
            $time = [System.TimeSpan]::FromSeconds($csvRecord.ttl)
            $timeToLive = "{0:HH:mm:ss}" -f ([datetime]$time.Ticks)

            Add-DnsServerResourceRecordCName -ZoneName $zonename -Name $csvRecord.name -HostNameAlias $csvRecord.value -TimeToLive $timeToLive
        }

        # SRV record
        If ($csvRecord.type -eq "SRV"){
            Add-DnsServerResourceRecord -Srv -ZoneName $zonename -Name $csvRecord.name -TimeToLive $csvRecord.ttl –DomainName $csvRecord.domainname –Weight $csvRecord.weight –Priority $csvRecord.priority –Port $csvRecord.port
        }

        # Add an AAAA resource record
        If ($csvRecord.type -eq "AAAA"){
            # set ttl
            $time = [System.TimeSpan]::FromSeconds($csvRecord.ttl)
            $timeToLive = "{0:HH:mm:ss}" -f ([datetime]$time.Ticks)

            Add-DnsServerResourceRecord -AAAA -Name $csvRecord.name -ZoneName $zonename -AllowUpdateAny -IPv6Address $csvRecord.value -TimeToLive $timeToLive -AgeRecord
        }

        # Add a PTR resource record
        If ($csvRecord.type -eq "PTR"){
            Add-DnsServerResourceRecord -Ptr -Name $csvRecord.name -ZoneName $zonename -AllowUpdateAny -PtrDomainName $csvRecord.value
        }

        # Add a MX resource record
        If ($csvRecord.type -eq "MX"){
            Add-DnsServerResourceRecord -MX -Name $csvRecord.name -ZoneName $zonename -MailExchange $csvRecord.value -Preference $csvRecord.preference
        }

    }
}

# DELETE
# Export records to be deleted in CSV file

# Declare array variable
$results = @()

# Loop through the zones in the machine
ForEach ($DnsServerZone in $DnsServerZones){
    $zonename = $DnsServerZone.ZoneName

    # Collect all DNS records from the zone
    $machineRecords = Get-DnsServerResourceRecord -ZoneName $zonename

  # loop through the records collection to get individual record
  ForEach ($machineRecord in $machineRecords){
    # Flag variable to check if the record is found in server
    $recordExist = 0
    
    # parse through each record in csv file
    ForEach ($csvRecord in $csvRecords){
        # If csv record name exists in server then change teh Flag variable
        If (($machineRecord.HostName -eq $csvRecord.name) -and ($zonename -eq $csvRecord.zonename)){
            $recordExist = 1
        }
    }

    # If record doesn't exist in csv then remove it from the server
    If (-Not $recordExist){

    # Fetch A records and save in an array
    If ($machineRecord.RecordType -eq "A"){
        $RecordData = $machineRecord.RecordData.IPv4Address.IPAddressToString
        $details = @{            
            name     = $machineRecord.HostName 
            zonename = $zonename
            type     = $machineRecord.RecordType
            value    = $RecordData
            ttl      = ([TimeSpan]::Parse($machineRecord.TimeToLive)).TotalSeconds
        }
    }

    # Fetch CNAME records and save in an array
    If ($machineRecord.RecordType -eq "CNAME"){
        $RecordData = $machineRecord.RecordData.HostNameAlias
        $details = @{            
            name     = $machineRecord.HostName 
            zonename = $zonename
            type     = $machineRecord.RecordType
            value    = $RecordData
            ttl      = ([TimeSpan]::Parse($machineRecord.TimeToLive)).TotalSeconds
        }
    }

    # Fetch NS records and save in an array
    If ($machineRecord.RecordType -eq "NS"){
        $RecordData = $machineRecord.RecordData.NameServer
        $details = @{            
            name     = $machineRecord.HostName
            zonename = $zonename
            type     = $machineRecord.RecordType
            value    = $RecordData
            ttl      = ([TimeSpan]::Parse($machineRecord.TimeToLive)).TotalSeconds
        }
    }

    # Fetch SRV records and save in an array
    If ($machineRecord.RecordType -eq "SRV"){
        $details = @{            
            name       = $machineRecord.HostName
            zonename   = $zonename
            type       = $machineRecord.RecordType
            ttl        = ([TimeSpan]::Parse($machineRecord.TimeToLive)).TotalSeconds
            priority   = $machineRecord.RecordData.Priority
            weight     = $machineRecord.RecordData.Weight
            port       = $machineRecord.RecordData.Port
            domainname = $machineRecord.RecordData.DomainName
        }
    }

    # Fetch SOA records and save in an array
    If ($machineRecord.RecordType -eq "SOA"){
        $details = @{            
            name              = $machineRecord.HostName
            zonename          = $zonename
            type              = $machineRecord.RecordType
            ttl               = ([TimeSpan]::Parse($machineRecord.TimeToLive)).TotalSeconds
            minimumttl        = $machineRecord.RecordData.MinimumTimeToLive
            expirelimit       = $machineRecord.RecordData.ExpireLimit
            primaryserver     = $machineRecord.RecordData.PrimaryServer
            refreshinterval   = $machineRecord.RecordData.RefreshInterval
            responsibleperson = $machineRecord.RecordData.ResponsiblePerson
            retrydelay        = $machineRecord.RecordData.RetryDelay
            serialnumber      = $machineRecord.RecordData.SerialNumber
        }
    }

    # Fetch PTR records and save in an array
    If ($machineRecord.RecordType -eq "PTR"){
        $details = @{            
            name          = $machineRecord.HostName
            zonename      = $zonename
            type          = $machineRecord.RecordType
            ttl           = ([TimeSpan]::Parse($machineRecord.TimeToLive)).TotalSeconds
            ptrdomainname = $machineRecord.RecordData.PtrDomainName
        }
    }

    # Convert array to object and save in variable                       
    $results += New-Object PSObject -Property $details

        # Force delete
        If ($delete -eq "delete"){
            # The following couple of lines can be removed.
            Remove-DnsServerResourceRecord -Force -ZoneName $zonename -RRType $machineRecord.RecordType -Name $machineRecord.HostName
            # Remove-DnsServerResourceRecord -Force -ZoneName $zonename -RRType $machineRecord.RecordType -Name ABCDEFG-A
        }

    }
  }
}

# Sort results
$results = $results | Sort type -Descending

# Export Data to timestamped CSV File named delete.csv
$results | Select-Object name,zonename,type,value,ttl,priority,weight,port,domainname,minimumttl,expirelimit,primaryserver,refreshinterval,responsibleperson,retrydelay,serialnumber | Export-Csv -Path "C:\Users\user\Desktop\delete-csv\delete-$(get-date -f yyyy-MM-dd_HH_mm_ss).csv" -NoTypeInformation
