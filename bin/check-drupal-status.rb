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
    # Get output from drush
    cmd = "drush core-requirements --format=json --severity=1 --root=#{config[:path]} --ignore=#{config[:exclude]}"
    stdout = `#{cmd}`

    # Read the incoming JSON data from stdout.
    events = JSON.parse(stdout)

    # Trigger based on events
    unless events.nil?
      events.each do |key, value|
        puts "#{key} - #{value['title']}: #{value['value'].nil? ? value['description'] : value['value']}"
      end
      critical
    else
      ok 'No reported errors of severity higher than: ' + config[:severity]
    end
  end
end
