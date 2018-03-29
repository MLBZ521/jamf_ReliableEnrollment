#!/bin/bash

###################################################################################################
# Script Name:  jamf_DeployReliableEnrollment.sh
# By:  Zack Thompson / Created:  3/23/2018
# Version:  0.1 / Updated:  3/23/2018 / By:  ZT
#
# Description:  This script creates a LaunchDaemon and a Script, then loads a LaunchDaemon.
#
###################################################################################################

echo "*****  deploy_ReliableEnrollment process:  START  *****"

##################################################
# Define Variables

scriptLocation="/Library/Application Support/JAMF/tmp/jamf_ReliableEnrollment.sh"
launchDaemonLabel="com.github.mlbz521.ReliableEnrollment"
launchDaemonLocation="/Library/LaunchDaemons/${launchDaemonLabel}.plist"
osVersion=$(/usr/bin/sw_vers -productVersion | /usr/bin/awk -F '.' '{print $2}')

##################################################
# Bit staged...

# Create the script...
echo "Creating the Jamf Reliable Enrollment Script..."

cat > "${scriptLocation}" <<'EOF'
#!/bin/bash

###################################################################################################
# Script Name:  jamf_ReliableEnrollment.sh
# By:  Zack Thompson / Created:  11/20/2017
# Version:  1.0 / Updated:  11/21/2017 / By:  ZT
#
# Description:  This script stages files and loads a LaunchDaemon.
#
###################################################################################################

/usr/bin/logger -s "*****  ReliableEnrollment process:  START  *****"

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
	/usr/bin/logger -s "Unloading LaunchDaemon"

	# Determine proper launchctl syntax
	if [[ ${osVersion} -ge 11 ]]; then
		/bin/launchctl bootout system $launchDaemonLocation
	elif [[ ${osVersion} -le 10 ]]; then
		/bin/launchctl unload $launchDaemonLocation
	fi

	# Function exitStatus
	exitStatus $?

	# Remove LaunchDaemon
	/usr/bin/logger -s "Deleting LaunchDaemon"
	/bin/rm -f $launchDaemonLocation

	# Function exitStatus
	exitStatus $?

	# Delete Self
	/usr/bin/logger -s "Deleting Script"
	/bin/rm -f "$0"

	# Function exitStatus
	exitStatus $?
}

exitStatus() {
	if [[ $1 != "0" ]]; then
		/usr/bin/logger -s " -> Failed"
		/usr/bin/logger -s "*****  ReliableEnrollment process:  FAILED  *****"
		exit 2
	else
		/usr/bin/logger -s " -> Success!"
	fi
}

##################################################
# Bits staged...

# Check if the .JamfEnrollmentDone file exits.
if [[ -e "${doneLocation}" ]]; then

	# Function tearDown
	tearDown

else
	if [[ -e $jamfBinary ]]; then
		/usr/bin/logger -s "Checking if the current JSS instance is available..."
		checkAvailablity=$(${jamfBinary} checkJSSConnection)

		# Function exitStatus
		exitStatus $?

		if [[ "${checkAvailablity}" != *"The JSS is available"* ]]; then
			# If the JSS is unavailable, suspend further processing...
			/usr/bin/logger -s "The Jamf Pro Server is unavailable at this time.  Suspending until next interval..."
			/usr/bin/logger -s "*****  ReliableEnrollment process:  SUSPENDED  *****"
			exit 1
		else
			# If the JSS is available, then continue...
			/usr/bin/logger -s "Checking if the distribution point is available..."
			/sbin/ping -oq "${jamfDP}" >/dev/null

			# Function exitStatus
			exitStatus $?
		fi
	fi

	# If we can communicate with the Jamf Services, run the enrollmentComplete Trigger.
	$jamfBinary policy -event enrollmentComplete

fi

/usr/bin/logger -s "*****  ReliableEnrollment process:  COMPLETE  *****"

exit 0
EOF


# Create the Launch Daemon...
echo "Creating the jamf_ReliableEnrollment.sh LaunchDaemon..."

cat > "${launchDaemonLocation}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>com.github.mlbz521.ReliableEnrollment</string>
	<key>ProgramArguments</key>
	<array>
		<string>/bin/bash</string>
		<string>-c</string>
		<string>(/Library/Application\ Support/JAMF/tmp/jamf_ReliableEnrollment.sh)</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>StartInterval</key>
	<integer>600</integer>
	<key>AbandonProcessGroup</key>
	<true/>
	<key>StandardErrorPath</key>
	<string>/var/log/jamf_ReliableEnrollment.log</string>
	<key>StandardOutPath</key>
	<string>/var/log/jamf_ReliableEnrollment.log</string>
</dict>
</plist>
EOF


# Verify the files exist...
if [[ -e "${scriptLocation}" && -e "${launchDaemonLocation}" ]]; then

	# Determine proper launchctl syntax based on OS Version 
	if [[ ${osVersion} -ge 11 ]]; then
		/bin/launchctl bootstrap system $launchDaemonLocation
		/bin/launchctl enable system/$launchDaemonLabel
	elif [[ ${osVersion} -le 10 ]]; then
		/bin/launchctl load $launchDaemonLocation
	fi

	echo "*****  deploy_ReliableEnrollment process:  COMPLETE  *****"
else
	echo "*****  deploy_ReliableEnrollment process:  FAILED  *****"
	exit 1
fi

exit 0