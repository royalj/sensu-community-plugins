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
# Checks etcd node self stats
# ===
#
# DESCRIPTION:
#   This plugin checks that the stats/self url returns 200OK
#
# OUTPUT:
#   plain-text
#
# PLATFORMS:
#   all
#
# DEPENDENCIES:
#   sensu-plugin Ruby gem
#   rest-client Ruby gem
#
# this is a first pass need to figure out all bad responses
#

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'
require 'rest-client'
require 'json'

class EtcdNodeStatus < Sensu::Plugin::Check::CLI

  option :server,
    :description => 'etcd server',
    :short => '-s SERVER',
    :long => '--server SERVER',
    :default => 'localhost'

  def run
    begin
      r = RestClient::Resource.new("http://#{config[:server]}:4001/v2/stats/self", :timeout => 5).get
      if r.code == 200
        ok "etcd is up"
      else
        critical "Etcd is not responding"
      end
    rescue Errno::ECONNREFUSED
      critical "Etcd is not responding"
    rescue RestClient::RequestTimeout
      critical 'Etcd Connection timed out'
    end
  end
end
