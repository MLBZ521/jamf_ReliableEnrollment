#!/bin/bash

###################################################################################################
# Script Name:  jamf_ea_JamfEnrollmentDone.sh
# By:  Zack Thompson / Created:  3/23/2018
# Version:  1.0 / Updated:  3/28/2018 / By:  ZT
#
# Description:  A Jamf Extension Attribute to verify if a machine has completed enrollment.
#
###################################################################################################

##################################################
# Define Variables
doneLocation="/var/db/.JamfEnrollmentDone"
jamfBinary="/usr/local/bin/jamf"

##################################################
# Bits staged... 

# Check if the .JamfEnrollmentDone file exits.
if [[ -e "${doneLocation}" ]]; then
	echo "<result>Enrollment Complete</result>"
else
	echo "<result>Pending</result>"
	# You may want to comment the below line out until your pre-existing machines have been "marked".
	$jamfBinary policy -event enrollmentComplete
fi

exit 0