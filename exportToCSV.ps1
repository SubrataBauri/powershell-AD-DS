# Keep names in variables
$computername = "compname"
$zonename = "zonename"

# Collect all DNS records from the machine in a variable
$machineRecords = Get-DnsServerResourceRecord -ZoneName $zonename

# Declare array variable
$results = @()

# Loop through all records
foreach ($machineRecord in $machineRecords) {
    # Fetch A records and save in an array
    If ($machineRecord.RecordType -eq "A"){
        $RecordData = $machineRecord.RecordData.IPv4Address.IPAddressToString
        $details = @{            
            name     = $machineRecord.HostName 
            zonename = $zonename
            type     = $machineRecord.RecordType
            value    = $RecordData
            ttl      = $machineRecord.TimeToLive
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
            ttl      = $machineRecord.TimeToLive
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
            ttl      = $machineRecord.TimeToLive
        }
    }

    # Fetch SRV records and save in an array
    If ($machineRecord.RecordType -eq "SRV"){
        $details = @{            
            name       = $machineRecord.HostName
            zonename   = $zonename
            type       = $machineRecord.RecordType
            ttl        = $machineRecord.TimeToLive
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
            ttl               = $machineRecord.TimeToLive
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
            ttl           = $machineRecord.TimeToLive
            ptrdomainname = $machineRecord.RecordData.PtrDomainName
        }
    }

    # Convert array to object and save in variable                       
    $results += New-Object PSObject -Property $details
}

# Export Data to CSV File named data.csv
$results | Select-Object name,zonename,type,value,ttl,priority,weight,port,domainname,minimumttl,expirelimit,primaryserver,refreshinterval,responsibleperson,retrydelay,serialnumber | Export-Csv -Path "C:\Users\username\Desktop\data.csv" -NoTypeInformation

