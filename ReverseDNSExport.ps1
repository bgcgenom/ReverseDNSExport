# Define the DNS server and the file path for export
$dnsServer = "DNS_IP"  # Replace with your DNS server name if different
$outputFolder = "C:\"

# Create the output folder if it doesn't exist
if (-Not (Test-Path -Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder
}

# Get the list of reverse lookup zones
$reverseZones = Get-DnsServerZone -ComputerName $dnsServer | Where-Object { $_.ZoneName -like "*.in-addr.arpa" }

# Function to format DNS resource records
function Format-DnsServerResourceRecord {
    param (
        [Parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance]$record
    )

    $recordData = $record.RecordData

    switch ($record.RecordType) {
        "A" {
            return "$($record.HostName) IN A $($recordData.IPv4Address)"
        }
        "PTR" {
            return "$($record.HostName) IN PTR $($recordData.PtrDomainName)"
        }
        "NS" {
            return "$($record.HostName) IN NS $($recordData.NameServer)"
        }
        "SOA" {
            return "$($record.HostName) IN SOA $($recordData.PrimaryServer) $($recordData.ResponsiblePerson) $($recordData.SerialNumber) $($recordData.RefreshInterval) $($recordData.RetryDelay) $($recordData.ExpireLimit) $($recordData.MinimumTimeToLive)"
        }
        default {
            return "$($record.HostName) IN $($record.RecordType) $($recordData)"
        }
    }
}

# Export each reverse lookup zone to a file
foreach ($zone in $reverseZones) {
    $zoneName = $zone.ZoneName
    $outputFile = Join-Path -Path $outputFolder -ChildPath ($zoneName + ".dns")
    
    # Remove the file if it already exists
    if (Test-Path -Path $outputFile) {
        Remove-Item -Path $outputFile -Force
    }
    
    Write-Output "Exporting $zoneName to $outputFile"
    
    # Retrieve and format the zone data
    $zoneData = Get-DnsServerResourceRecord -ZoneName $zoneName -ComputerName $dnsServer
    $formattedZoneData = $zoneData | ForEach-Object { Format-DnsServerResourceRecord -record $_ }
    
    # Write formatted data to the file
    $formattedZoneData | Out-File -FilePath $outputFile
}

Write-Output "Reverse lookup zones have been exported to $outputFolder"
