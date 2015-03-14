#!/usr/bin/env ruby

$:.unshift(File.expand_path(File.dirname(__FILE__), 'lib'))

require 'optparse'
require 'snapper'

options = {}

OptionParser.new do |opts|
  opts.banner = "Usage: <script.rb> [options]"

  opts.on('-s', '--source_site ENVIRONMENT:SOURCE_SITE', 'The site to migrate from') do |source_site|
    options[:source_environment] = source_site.split(":").first
    options[:source_site] = source_site.split(":").last
  end

  opts.on('-d', '--destination_site ENVIRONMENT:DESTINATION_SITE', 'The site to migrate to') do |destination_site|
    options[:destination_environment] = destination_site.split(":").first
    options[:destination_site] = destination_site.split(":").last
  end

  opts.on('-4', '--4x4 OBE 4x4', 'The Old Backend 4x4 ID to use to find the NBE 4x4s') do |four_by_four|
    options[:four_by_four] = four_by_four
  end

  opts.on('-n', '--navigation_steps STEP:STEP:STEP...', 'The paths within a site to visit') do |navigation_steps|
    options[:navigation_steps] = navigation_steps
  end

  opts.on('-u', '--user USER', 'The user to login with') do |user|
    options[:user] = user
  end

  opts.on('-p', '--password PASSWORD', 'The the password for the user') do |password|
    options[:password] = password
  end

  opts.on('-l', '--log_dir LOGDIR', 'The directory to write files to') do |log_dir|
    options[:log_dir] = log_dir
  end

  opts.on('-o', '--output_png OUTPUTING', 'The name of the file to write') do |output_png|
    options[:output_png] = output_png
  end

  opts.on('-c', '--compare COMPARE_PNGS', 'The automated comparison function') do |compare_pngs|
    options[:compare_pngs] = compare_pngs
  end

  opts.on('-h', '--help', 'Display Help') do
    puts(opts)
    exit
  end
end.parse!

a = Snapper.new(options[:source_site], options[:four_by_four], options[:user], options[:password])
a.sign_in
a.navigate_to("profile")
a.snap("profile_#{options[:source_environment]}_#{options[:output_png]}", options[:log_dir])

b = Snapper.new(options[:source_site], options[:four_by_four], options[:user], options[:password])
b.sign_in
b.navigate_to("view/#{options[:four_by_four]}")
b.snap("newui_#{options[:source_environment]}_#{options[:output_png]}", options[:log_dir])

c = Snapper.new(options[:source_site], options[:four_by_four], options[:user], options[:password])
c .sign_in
c.navigate_to("profile")
c.snap("profile_#{options[:destination_environment]}_#{options[:output_png]}", options[:log_dir])

d = Snapper.new(options[:source_site], options[:four_by_four], options[:user], options[:password])
d.sign_in
d.navigate_to("view/#{options[:four_by_four]}")
d.snap("newui_#{options[:destination_environment]}_#{options[:output_png]}", options[:log_dir])

a.write_html(options[:log_dir])

#ruby snapper-caller.rb -s azure_rc:opendata-demo.test-socrata.com -d azure_staging:opendata-demo.test-socrata.com -u joe.nunnelley@socrata.com -p Und3rd0g -l logs -o snappit.png
#ruby snapper-caller.rb -s azure_rc:opendata-demo.test-socrata.com -4 b7hm-7vvu -d azure_staging:opendata-demo.test-socrata.com -u joe.nunnelley@socrata.com -p Und3rd0g -l logs -o snappit.png
#https://opendata-demo.test-socrata.com/view/c9fk-nidx
