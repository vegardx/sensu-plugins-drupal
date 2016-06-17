#! /usr/bin/env ruby
#
#   check-drupal-modules.rb
#
# DESCRIPTION:
#   Checks for secruity updates to Drupal Core and contrib modules.
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
#   ./check-drupal-modules.rb -p /var/www
#   ./check-drupal-modules.rb -p /var/www -e annoying,modules
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

class CheckDrupalModules < Sensu::Plugin::Check::CLI
  option :path,
         short: '-p PATH',
         long: '--path PATH',
         required: true,
         description: 'Path to Drupal project root.'

  option :exclude,
         short: '-e PATTERN',
         long: '--exclude PATTERN',
         description: 'Exclude based on regexp. Use with caution.'

  def run
    # Get output from drush
    cmd = "drush ups --format=json --security-only --root=#{config[:path]}"
    stdout = `#{cmd}`

    # Read the incoming JSON data from stdout.
    events = JSON.parse(stdout)

    # Filter out excluded keys
    unless config[:exclude].nil?
      events.delete_if { |key, value| key.to_s.match(/#{config[:exclude]}/) }
    end

    # Trigger based on events
    unless events.nil?
      events.each do |key, value|
        puts "#{key} - #{value['existing_version']} -> #{value['candidate_version']}"
      end
      critical
    else
      ok 'No security updates available.'
    end
  end
end
