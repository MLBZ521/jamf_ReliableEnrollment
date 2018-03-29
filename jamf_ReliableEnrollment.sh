#!/bin/bash

###################################################################################################
# Script Name:  jamf_ReliableEnrollment.sh
# By:  Zack Thompson / Created:  3/23/2018
# Version:  1.0 / Updated:  3/28/2018 / By:  ZT
#
# Description:  This script verifies the JSS and DP are accessible and if so, runs the enrollmentComplete event.
#
###################################################################################################

echo " "
echo "*****  ReliableEnrollment process:  START  *****"

##################################################
# Define Variables
	jamfPS="https://jamfps.company.com:8443"
	jamfDP="jamfdp.company.com"
	doneLocation="/var/db/.JamfEnrollmentDone"
	launchDaemonLabel="com.github.mlbz521.ReliableEnrollment"
	launchDaemonLocation="/Library/LaunchDaemons/${launchDaemonLabel}.plist"
	jamfBinary="/usr/local/bin/jamf"
	osVersion=$(/usr/bin/sw_vers -productVersion | /usr/bin/awk -F '.' '{print $2}')

##################################################
# Setup Functions

tearDown() {
	# Unload LaunchDaemon
	echo "Unloading LaunchDaemon..."

	# Determine proper launchctl syntax
	if [[ $osVersion -ge 11 ]]; then
		/bin/launchctl bootout system "${launchDaemonLocation}"
	elif [[ $osVersion -le 10 ]]; then
		/bin/launchctl unload "${launchDaemonLocation}"
	fi

	# Function exitStatus
	exitStatus $?

	# Remove LaunchDaemon
	echo "Deleting LaunchDaemon..."
	/bin/rm -f "${launchDaemonLocation}"

	# Function exitStatus
	exitStatus $?

	# Delete Self
	echo "Deleting Script..."
	/bin/rm -f "${0}"

	# Function exitStatus
	exitStatus $?
}

exitStatus() {
	if [[ $1 != "0" ]]; then
		echo "  -> Failed"
		echo "*****  ReliableEnrollment process:  FAILED  *****"
		exit 1
	else
		echo "  -> Success!"
	fi
}

##################################################
# Bits staged...

# Check if the .JamfEnrollmentDone file exits.
if [[ -e "${doneLocation}" ]]; then
	echo "This machine has completed the Enrollment process."
	echo "Performing clean up of the Reliable Enrollment process."
	echo " "

	# Function tearDown
	tearDown

	echo "Clean up complete!"
else
	if [[ -e $jamfBinary ]]; then
		echo "Checking if the current JSS instance is available..."
		checkAvailablity=$($jamfBinary checkJSSConnection)

		# Function exitStatus
		exitStatus $?

		if [[ "${checkAvailablity}" != *"The JSS is available"* ]]; then
			# If the JSS is unavailable, suspend further processing...
			echo "The Jamf Pro Server is unavailable at this time.  Suspending until next interval..."
			echo "*****  ReliableEnrollment process:  SUSPENDED  *****"
			exit 3
		else
			# If the JSS is available, then continue...
			echo "Checking if the distribution point is available..."
			/sbin/ping -oq "${jamfDP}" >/dev/null

			# Function exitStatus
			exitStatus $?
		fi
	else
		echo "ERROR:  Unable to locate the Jamf Binary"
		echo "*****  ReliableEnrollment process:  FAILED  *****"
		exit 2
	fi

	# If we can communicate with the Jamf Services, run the enrollmentComplete Trigger.
	$jamfBinary policy -event enrollmentComplete

fi

echo "*****  ReliableEnrollment process:  COMPLETE  *****"
echo " "
exit 0