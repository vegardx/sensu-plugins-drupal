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
require 'open4'

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
    # Grab data from Drupal using drush
    pid, _stdin, stdout, _stderr = Open4.popen4 "drush ups --format=json --security-only --root=#{config[:path]}"
    _ignored, status = Process.waitpid2 pid

    # Make sure we go criical if drush returns non-zero value
    critical 'Drush not found in local path or exited with a non-zero value' unless status.exitstatus == 0

    # Read the incoming JSON data from stdout.
    events = JSON.parse(stdout.read) unless stdout.read.nil? || stdout.read.empty?

    # Filter out excluded keys
    events.delete_if { |key| key.to_s.match(/#{config[:exclude]}/) } unless config[:exclude].nil?

    # Trigger based on events
    if events
      events.each do |key, value|
        puts "#{key} - #{value['existing_version']} -> #{value['candidate_version']}"
      end
      critical
    else
      ok 'No security updates available.'
    end
  end
end
