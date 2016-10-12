[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [string[]]
    $icao,
    [Parameter(Mandatory=$true)]
    [string]
    $type,
    [Parameter(Mandatory=$true)]
    [string]
    $asaUsername,

    [Parameter(Mandatory=$true)]
    [string]
    $asaPassword
    )

filter Get-BeforeFirstBlankLine() {
    $blankLineFound = $false
    $results = ""
    foreach ($line in $_.Split("`n")) {
        if (-not $blankLineFound) {
            if ($line.trim().length -eq 0) {
                $blankLineFound = $true
            } else {
                $results += "$line`n"
            }
        }
    }
    # Remove the last empty line
    $results = $results.Trim()

    return $results
}


# Constants
$soapEndpointUri = 'https://www.airservicesaustralia.com/naips/briefing-service?wsdl'
$supportedBriefingTypes = @("ATIS","TAF","TTF","FULL")

# Variables
$soapRequestXml = @'
<?xml version="1.0" encoding="UTF-8"?>
    <SOAP-ENV:Envelope
        xmlns:ns0="http://schemas.xmlsoap.org/soap/envelope/"
        xmlns:ns1="http://www.airservicesaustralia.com/naips/xsd"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
    <SOAP-ENV:Header/>
    <ns0:Body>
      <ns1:loc-brief-rqs password="%SOAPPASSWORD%" requestor="%SOAPUSERNAME%" source="atis">
      <ns1:loc>%AD%</ns1:loc>
      <ns1:flags met="true"/>
    </ns1:loc-brief-rqs>
    </ns0:Body>
    </SOAP-ENV:Envelope>
'@

# before we start, make sure the requested briefing is a supported one
if ($supportedBriefingTypes -notcontains $type.ToUpper()) {
    throw "You must provide a supported briefing type. Supported types: $($supportedBriefingTypes -join ", ")."
}
        

$soapRequestXml = $soapRequestXml -replace "%SOAPUSERNAME%", $asaUsername.ToUpper()
$soapRequestXml = $soapRequestXml -replace "%SOAPPASSWORD%", $asaPassword

$soapHeaders = @{
    "Content-type" = 'text/xml;charset="utf-8"'
    "Accept" = "text/xml"
    "Cache-Control" = "no-cache"
    "Pragma" = "no-cache"
    "SOAPAction" = $soapEndpointUri
    "Content-length" = $soapRequestXml.Length
}

$results = @{}

foreach ($ad in $icao) {
    $thisRequestXml = $soapRequestXml -replace "%AD%",$ad 
    $res = Invoke-WebRequest -Uri $soapEndpointUri -Method Post `
        -ContentType 'text/xml' `
        -Body $thisRequestXml `
        -Headers $soapHeaders
        
    $results.$ad = $res.Content.ToString()
}

$briefings = @()
switch ($type) {
    'atis' {
        foreach ($ad in $results.GetEnumerator()) {

            $briefing = $ad.value | Out-String
            try { 
                $chunk = $briefing.Substring($briefing.IndexOf("ATIS"))
            } catch {
                throw "Got the briefing, but could not retrieve the ATIS! Does this location have automatic ATIS?"
            }

            # Split by newline and remove the last two
            $chunk = $chunk -split "`n" | Select-Object -SkipLast 2
            # Join back together
            $chunk = $chunk -join "`n" 
            # Return everything before the next blank line
            $briefings += $chunk | Get-BeforeFirstBlankLine
        }
    }
    'taf' {
        foreach ($ad in $results.GetEnumerator()) {

            $briefing = $ad.value | Out-String
            $chunk = $briefing.Substring($briefing.IndexOf("TAF"))

            # Split by newline and remove the last two
            $chunk = $chunk -split "`n" | Select-Object -SkipLast 2
            # Join back together
            $chunk = $chunk -join "`n" 
            # Return everything before the next blank line
            $briefings += $chunk | Get-BeforeFirstBlankLine
        }
    }
    'ttf' {
        foreach ($ad in $results.GetEnumerator()) {

            $briefing = $ad.value | Out-String
            $chunk = $briefing.Substring($briefing.IndexOf("TTF"))

            # Split by newline and remove the last two
            $chunk = $chunk -split "`n" | Select-Object -SkipLast 2
            # Join back together
            $chunk = $chunk -join "`n" 
            # Return everything before the next blank line
            $briefings += $chunk | Get-BeforeFirstBlankLine
        }
    }
    'full' {
        foreach ($ad in $results.GetEnumerator()) {
            $briefing = $ad.value | Out-String
            $briefing = $briefing -split "`n" | Select-Object -Skip 1 | Select-Object -SkipLast 2
            $briefings += $briefing
        }
    }

    default {
        throw "You must provide a supported briefing type. Supported types: $($supportedBriefingTypes -join ", ")."
    }
}
return $briefings