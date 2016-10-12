# Get-AirServicesBriefing.ps1
Retrieves a briefing from AirServices Australia's SOAP web service using PowerShell.

## Usage
Call this script from Windows PowerShell with the following syntax:

    .\Get-AirServicesBriefing.ps1 -icao YSBK -Type ATIS -asaUsername "yourNAIPSUsername" -asaPassword "yourNAIPSPassword"
    
"-Type" can be any of ATIS, TAF, TTF, or FULL (which retrieves all of them)

If you don't have a NAIPS account, you should [register](https://www.airservicesaustralia.com/naips/Account/Register) for one.