#!/usr/bin/env ruby
#
#  Notify mutator
# ===
#
# DESCRIPTION:
#   Check against custom parameters within the check to determine if the
#   handler should alert. Assumes 7 days a week.
#
# OUTPUT:
#   mutated JSON event
#
# USAGE:
#   TODO
#
#PLATFORM:
#   all
#
# DEPENDENCIES:
#
#   json and time Ruby gems
#
# LICENSE:
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'json'
require 'time'

# GOAL/REQUIREMENTS
# Pass in an array via the check that contains 2 elements
#   1st element is ALWAYS the start time
#   2nd element is ALWAYS the end time
# Also check can be set to notify overnight with notify_overnight flag == true in custom check param
# Start/end times in 24 hour clock format
# If array does not exist, notify = true, meaning check
# will notify 24x7
# If array exists and time.now.between start/end time then notify = true (add validation for time format)
# Special logic to handle overnight periods
# merge element into event => notify: <true/false>
#
# Within default handler just need to utilize the notify_period and notify_overnight(optional) variable
# e.g. unless notify == false then alert
# Example usage:
#   sensu::check { 'example':
#     ensure  => true,
#     command => '...',
#     ...
#     custom  => {
#       ...
#       notify_period => ['8:00', '17:00']
#     }
#
#   sensu::check { 'example2':
#     ensure  => true,
#     command => '...',
#     ...
#     custom  => {
#       ...
#       notify_period => ['19:00', '7:00'],
#       notify_overnight => true
#     }
# For each handler, we would then add a couple lines of logic to check if the event should alert
# e.g.  unless @event['check']['notify']
#         exit(0)
#       end
#
# NOTES:
# What happens if Sensu server goes down messages in queue that need to alert don't hit the notification period?


event       = JSON.parse(STDIN.read, symbolize_names: true)
@t          = Time.now
@notify     = true

# If notify_period is not set then assume 24x7 notification period and exit
unless event[:check][:notify_period]
  event.merge!(notify: true)
  puts event.to_json
  exit(0)
end

@start_time   = event[:check][:notify_period][0]
@end_time     = event[:check][:notify_period][1]
@overnight    = event[:check][:notify_overnight] || false
reg_validate  = /\d{1,2}:\d{2}/

# Check to see if the event timestamp is within the notification period given
def notification_period? 
  if @t.between?(Time.parse("#{@start_time}"), Time.parse("#{@end_time}"))
    @notify
  else
    @notify == false
  end
  # An overnight notification period (where @end_time < @start_time, e.g. 18:00 - 6:00) will
  # throw an error so we need to catch the error and check if we want to notify overnight or not.
  rescue ArgumentError
    overnight?  
end


def overnight?
  if @overnight && @end_time <= @t && @t >= @start_time
    true
  else
    raise ArgumentError
      puts "[ERROR] Start time is after End time, overnight periods must have notify_overnight flag set"
      exit(2)
  end
end

def validate_period
  unless @start_time == reg_validate || @end_time == reg_validate
    raise ArgumentError
      puts "[ERROR] notify period times need to be formatted in <hour>:<minute>"
      exit(2)
  end
end

validate_period

# mutate the event based on whether it should alert or not
if notification_period?
  event.merge!(notify: true)
else
  event.merge!(notify: false)
end

# output modified event
puts event.to_json
exit(0)
