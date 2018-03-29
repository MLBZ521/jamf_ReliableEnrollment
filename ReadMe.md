Jamf Reliable Enrollment
======

This intent of this project is to make the Jamf "enrollmentComplete" event more reliable by waiting for a 'flag' to exist before considering the "enrollment" process to have 'completed.'

Essentially, a LaunchDaemon is created that runs a script.  This script checks to see if the "enrollment done flag" exists, if it doesn't, it runs the enrollmentComplete trigger event.


## Overview

  * Computer Enrolls:
    * Triggers enrollmentComplete
      * This includes the policy to stage the "Reliable Enrollment Framework"
    * If the enrollmentComplete event is interrupted (i.e. by a networkStateChange event)
      * The "Reliable Enrollment Framework" will kick off every ten minutes to run enrollmentComplete until all Enrollment Policies are completed
      * If the "Reliable Enrollment Framework" is not installed on the initial enrollment, then it will be installed on the next Check-in

There is a log that can be viewed for information on this process:
  * /var/log/jamf_ReliableEnrollment.log
    * Open with either console or your favorite text editor


## Setup

##### To utilize this process, you need to do the following: 
  * Upload script to the JPS
  * Create Smart Group
  * Create three policies
  * Create an Extension Attribute

###### Script:
  * Upload the script entitled:  `jamf_DeployReliableEnrollment.sh`

###### Extension Attribute
  * Name example:  Enrollment Status
  * Use the contents of the following script in the EA:  `jamf_ea_JamfEnrollmentDone.sh`

###### Smart Group:
  * Reliable Enrollment Complete
  * Criteria:
    * Enrolled Before Date -- yyyy-mm-dd
      * Pick the date you plan to deploy this solution (I assume you don't want to run enrollmentComplete on devices that have already been enrolled)
    * (or) Enrollment Status <is> "Complete"
      * This is the EA created above

###### Policies:
  * Policy 1 -- for Existing machines
    * Event:  Recurring Check-in
    * Scope:
      * Target:  "Reliable Enrollment Complete" Smart Group
    * Files and Processes Payload
      * Run command:  `touch /var/db/.JamfEnrollmentDone`
  * Policy 2 -- for New Machines
    * Name:  Name the Policy so that it is the very first policy that runs on enrollment, or as close to first as possible
    * Event:
      * Recurring Check-in
      * Enrollment
    * Scope:
      * Target:  All Computers
      * Exclude:  "Reliable Enrollment Complete" Smart Group
    * Scripts Payload
      * Add the `jamf_DeployReliableEnrollment.sh` Script
  * Policy 3 -- for New Machines
    * Name:  Name the Policy so that it is the very last policy that runs on enrollment, or as at least, after all your critical policies have been run
    * Event:
      * Enrollment
    * Scope:
      * Target:  All Computers
    * Files and Processes Payload
      * Run command:  `touch /var/db/.JamfEnrollmentDone`


## Logic

###### Extension Attribute
  * Checks if .done file
    * If it exists
      * Return <result>Enrollment Complete</result>
    * If not
      * Return <result>Pending</result>
      * Triggers enrollment

###### LaunchDaemon
  * Schedule:
    * Runs every 10 minutes
  * Actions:
    * Runs script

###### Script
  * Checks for .JameEnrollmentDone
    * If it exists
      * "Tear Down" begins
        * Stops the LaunchDaemon
        * Deletes LaunchDaemon
        * Deletes Script
  * If not
    * Checks if the JPS and DP are available
    * If they are:
      * Triggers enrollment
    * If not:
      * Suspends until the next interval
