#! /usr/bin/env ruby
#
#   check-drupal-status.rb
#
# DESCRIPTION:
#   Verifies that all components of Drupal is working as intended using drush
#   locally.
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux, Windows, BSD, Solaris, etc
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: json
#   package: drush
#
# USAGE:
#   ./check-drupal-status.rb -p /var/www
#   ./check-drupal-status.rb -p /var/www -s 2
#   ./check-drupal-status.rb -p /var/www -s -1 -e update_contrib,update_core
#
#
# NOTES:
#   Assumes that you have drush installed and that it's available in the local
#   path.
#
# LICENSE:
#   Vegard Hansen vegard.x@gmail.com
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'json'
require 'open4'

class CheckDrupalStatus < Sensu::Plugin::Check::CLI
  option :path,
         short: '-p PATH',
         long: '--path PATH',
         required: true,
         description: 'Path to Drupal project root'

  option :severity,
         short: '-s SEVERITY',
         long: '--severity SEVERITY',
         default: 1,
         description: 'Filter based on severity greater than or equal to. Values from -1 to 2.'

  option :exclude,
         short: '-e LIST',
         long: '--exclude LIST',
         description: 'Comma-separated list to ignore.'

  def run
    # Grab data from Drupal using drush
    pid, _stdin, stdout, _stderr = Open4.popen4 "drush core-requirements --format=json --severity=1 --root=#{config[:path]} --ignore=#{config[:exclude]}"
    _ignored, status = Process.waitpid2 pid

    # Make sure we go criical if drush returns non-zero value
    critical 'Drush not found in local path or exited with a non-zero value' unless status.exitstatus == 0

    # Read the incoming JSON data from stdout.
    events = JSON.parse(stdout.read) unless stdout.read.nil? || stdout.read.empty?

    # Trigger based on events
    if events
      events.each do |key, value|
        puts "#{key} - #{value['title']}: #{value['value'].nil? ? value['description'] : value['value']}"
      end
      critical
    else
      ok 'No reported errors of severity higher than: ' + config[:severity].to_s
    end
  end
end
