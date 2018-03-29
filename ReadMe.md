Jamf Reliable Enrollment
======

This intent of this project is to make the Jamf "enrollmentComplete" event more reliable by waiting for a 'flag' to exist before considering the "enrollment" process to have 'completed.'

Essentially, a LaunchDaemon is created that runs a script.  This script checks to see if the "enrollment done flag" exists, if it doesn't, it runs the enrollmentComplete trigger event.


#### Overview ####

To utilize this process, you need to do the following: 
  * Upload script to the JPS
  * Create Smart Group
  * Create x policies
  * Create an Extension Attribute


## Setup ##

Script:
  * Upload the script entitled:  `jamf_DeployReliableEnrollment.sh`

Smart Group:
  * Enrolled Before Date -- yyyy-mm-dd
    * Pick the date you plan to deploy this solution (I assume you don't want to run enrollmentComplete on devices that have already been enrolled)

Extension Attribute
  * Name example:  Enrollment Status
  * Use the contents of the following script in the EA:  `jamf_ea_JamfEnrollmentDone.sh`

Policies:
  * Policy 1 -- for Existing machines
    * Event:  Recurring Check-in
    * Scope:
      * Target:  Enrolled before date
    * Files and Processes Payload
      * Run command:  `touch /var/db/.JamfEnrollmentDone`
  * Policy 2 -- for New Machines
    * Name:  Name the Policy so that it is the very first policy that runs on enrollment, or as close to first as possible.
    * Event:
      * Recurring Check-in
      * Enrollment
    * Scope:
      * Target:  All Computers
      * Exclude:  Enrolled before date
    * Scripts Payload
      * Add the `jamf_DeployReliableEnrollment.sh` Script
  * Policy 3 -- for New Machines
    * Name:  Name the Policy so that it is the very last policy that runs on enrollment, or as at least, after all your critical policies have been run.
    * Event:
      * Enrollment
    * Scope:
      * Target:  All Computers
    * Files and Processes Payload
      * Run command:  `touch /var/db/.JamfEnrollmentDone`
