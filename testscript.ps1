# Keep names in variables
$computername = "DC-A"
$zonename = "extstaging.local"

# Collect all DNS records from the machine in a variable
$machineRecords = Get-DnsServerResourceRecord -ZoneName $zonename

# Read records to be modified from csv
$InputFile = "C:\Users\mbandlamudi\Desktop\dnsrecords.csv"
$csvRecords = Import-CSV $InputFile

# EDIT/ADD Records
# parse through each record in csv file
ForEach ($csvRecord in $csvRecords){
    # Flag variable to check if the record is found in server
    $foundRecord = 0
    
    # EDIT
    # loop through the records collection to get individual record
    ForEach ($machineRecord in $machineRecords){

        # If csv record name exists in server then EDIT
        If ($csvRecord.name -eq $machineRecord.HostName){
            # set to one when record found
            $foundRecord = 1

            # Check and Modify A record | If record type is A and csv record doesn't match server record
            If (($csvRecord.type -eq "A") -and ($csvRecord.value -ne $machineRecord.RecordData.IPv4Address.IPAddressToString) ){
                # Get two identical objects representing a DNS record
                $OldObj = Get-DnsServerResourceRecord -ZoneName $zonename -RRType $csvRecord.type -Name $csvRecord.name
                $NewObj = $OldObj.clone()

                # Change IPv4 on the new object
                $NewObj.RecordData.IPv4Address = [System.Net.IPAddress]::parse($csvRecord.value)

                # Set ttl
                $NewObj.TimeToLive = [System.TimeSpan]::FromSeconds($csvRecord.ttl)

                # Update record on the server
                Set-DNSServerResourceRecord -NewInputObject $NewObj -OldInputObject $OldObj -ZoneName $zonename -PassThru
            }

            # Check and Modify CNAME record | If record type is CNAME and csv record doesn't match server record
            If (($csvRecord.type -eq "CNAME") -and ($csvRecord.value -ne $machineRecord.RecordData.HostNameAlias) ){
                # Get two identical objects representing a DNS record
                $OldObj = Get-DnsServerResourceRecord -ZoneName $zonename -RRType $csvRecord.type -Name $csvRecord.name
                $NewObj = $OldObj.clone()

                # Change CNAME on the new object
                $NewObj.RecordData.HostNameAlias = $csvRecord.value

                # Need to figure out how to modify the ttl
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
            # ttl
            $TimeToLive = [System.TimeSpan]::FromSeconds($csvRecord.ttl)

            Add-DnsServerResourceRecord -ZoneName $zonename -A -Name $csvRecord.name -IPv4Address $csvRecord.value -TimeToLive $TimeToLive
        }

        # CNAME record
        If ($csvRecord.type -eq "CNAME"){
            # ttl
            $TimeToLive = [System.TimeSpan]::FromSeconds($csvRecord.ttl)

            Add-DnsServerResourceRecordCName -ZoneName $zonename -Name $csvRecord.name -HostNameAlias $csvRecord.value -TimeToLive $TimeToLive
        }
    }
}
