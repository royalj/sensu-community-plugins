
#! /usr/bin/env ruby
#
#
# DESCRIPTION:
#
# OUTPUT:
#   plain-text
#
# PLATFORMS:
#   all
#
# DEPENDENCIES:
#   gem: sensu-plugin
#
# #YELLOW
# needs usage
#
# USAGE:
#
# NOTES:
#
# LICENSE:
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#
#!/usr/bin/env ruby
#
# Check NTP offset - yeah this is horrible.
#
# warning and critical values are offsets in milliseconds.
#

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'

class CheckNTP < Sensu::Plugin::Check::CLI

  option :warn,
    :short => '-w WARN',
    :proc => proc {|a| a.to_i },
    :default => 10

  option :crit,
    :short => '-c CRIT',
    :proc => proc {|a| a.to_i },
    :default => 100

  def run
    begin
      offset = `ntpq -c "rv 0 offset"`.split('=')[1].strip.to_i
    rescue
      unknown "NTP command Failed"
    end

    critical if offset >= config[:crit] || offset <= -config[:crit]
    warning if offset >= config[:warn] || offset <= -config[:warn]
    ok

  end
end
