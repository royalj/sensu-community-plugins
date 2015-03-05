#!/usr/bin/env ruby
#
#  Notify mutator
# ===
#
# DESCRIPTION:
#   This mutator allows a custom notification period to be passed in via a custom check
#   parameter(notify_period). The notify_period parameter must be an array that contains exactly
#   two string values. The first value will always be the start time for the notification period.
#   The second parameter will always be the end time. The start/end times should be formatted in
#   24 hour clock format with hours and minutes seperated by a comma. If you are defining an
#   overnight notification period you must also set the custom check parameter
#   notify_overnight => true.
#
# OUTPUT:
#   mutated JSON event
#
# USAGE: (Buckle specific)
#   Within puppet check definitions:
#     sensu::check { 'example':
#       ensure  => true,
#       command => '...',
#       ...
#       custom  => {
#         ...
#         notify_period => ['8:00', '17:00']
#       }
#
#     sensu::check { 'example2':
#       ensure  => true,
#       command => '...',
#       ...
#       custom  => {
#         ...
#         notify_period => ['19:00', '7:00'],
#         notify_overnight => true
#       }
#   Within puppet handler defintion:
#     sensu::handler { 'default':
#       type      => 'set',
#       command   => true,
#       handlers  => $default_handler_array,
#       mutator   => 'notify'
#       config    => {
#         dashboard_link => $dashboard_link,
#       }
#     }
#
# PLATFORM:
#   all
#
# DEPENDENCIES:
#
#   json and time Ruby gems
#
# LICENSE:
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.

# Example usage:

# For each handler, we would then add a couple lines of logic to check if the event should alert
# e.g.  unless @event['check']['notify']
#         puts 'Event not within notification period'
#         exit(0)
#       end
#
# NOTES:
# What happens if Sensu server goes down messages in queue that need to alert don't hit the notification period?

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'json'
require 'time'

##### MAIN #####

validate_period

event       = JSON.parse(STDIN.read, symbolize_names: true)
@time       = Time.now
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

# mutate the event based on whether it should alert or not
if notification_period?
  event.merge!(notify: true)
else
  event.merge!(notify: false)
end

# output modified event
puts event.to_json
exit(0)

# Check to see if the event timestamp is within the notification period given
def notification_period? 
  if @time.between?(Time.parse("#{@start_time}"), Time.parse("#{@end_time}"))
    @notify
  else
    !@notify
  end
  # An overnight notification period (where @end_time < @start_time, e.g. 18:00 - 6:00) will
  # throw an error so we need to catch the error and check if we want to notify overnight or not.
  rescue ArgumentError
    overnight?  
end


def overnight?
  if @overnight && @end_time <= @time && @time >= @start_time
    true
  else
    raise ArgumentError
  end
end

def validate_period
  unless @start_time == reg_validate || @end_time == reg_validate
    raise ArgumentError.new('Invalid start and/or end time')
  end
end
