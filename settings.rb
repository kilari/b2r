#
# settings.rb.example
#
# copy this file to "settings.rb" and modify
# the settings
#

#
# connection data for your bugzilla database
#

BUGZILLA_HOST='localhost'
BUGZILLA_DB='elp'
BUGZILLA_USER='elp'
BUGZILLA_PASSWORD='elp123'

#
# connection data for your redmine database
#

REDMINE_HOST='localhost'
REDMINE_DB='pol'
REDMINE_USER='pol'
REDMINE_PASSWORD='pol123'

#
# this is the path where the attachments 
# are written to.
# replace this with your redmine attachment path.
# this path is the $redmine_home/files directory.
#

ATTACHMENT_PATH="/var/redmine/ilsw-admin/files"

#
# Bugzilla priority to Redmine priority map
# this mapping is language dependent
# if you have been altering your bugzilla settings
# please check the contents of the "priority"-Table 
# in your bugzilla database
#

ISSUE_PRIORITIES = {       
  "P1" => 7,
  "P2" => 6,
  "P3" => 4,
  "P4" => 3,
  "P5" => 3 }

#
# Bugzilla severity to Redmine tracker map
# this mapping is language dependent
# if you have been altering your bugzilla settings
# please check the contents of the "bug_severity"-Table 
# in your bugzilla database
#

ISSUE_TRACKERS = {
  "critical" => 1,
  "trivial" => 1,
  "minimal" => 1,
  "major" => 1,
  "normal" => 1,
  "blocker" => 1,
  "enhancment" => 1
}

#
# Bugzilla status to Redmine status map
#
# this mapping is language dependent
# if you have been altering your bugzilla settings
# please check the contents of the "bug_status"-Table 
# in your bugzilla database
#

ISSUE_STATUS = {
  "UNCONFIRMED"   => 1,
  "NEW"           => 1,
  "ASSIGNED"      => 2,
  "REOPENED"      => 7,
  "RESOLVED"      => 5,
  "VERIFIED"      => 2,
  "CLOSED"        => 5
}

