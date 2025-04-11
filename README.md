# elm327-zero
Bluetooth OBD2 scanner connected to a Radxa Zero for Real time data from my Camaro

There is nothing but bad information on connecting a single board computer (Raspberry PI Zero, Radxa Zero in my case..) to a bluetooth to a elm327 OBD2 device. 
1. Had to install Armbian instead of the official ubuntu image for the Radxa Zero because it would not allow me to bind to rfcomm0. I found the link to the unofficial Armbian was referenced in old releases that ultimately led me to https://www.armbian.com/radxa-zero/ where I downloaded the debian bookworm image https://dl.armbian.com/radxa-zero/Bookworm_current_minimal-homeassistant.
2. 
