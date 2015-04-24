require 'optparse'
require_relative 'lib/snapper'
require_relative 'lib/site'

options = {}

OptionParser.new do |opts|
  opts.banner = "Usage: <script.rb> [options]"

  opts.on('-m', '--mode MODE', 'The operation to execute') do |mode|
    options[:mode] = mode
  end

  opts.on('-s', '--site1 SITE_1|4x4', 'The site to get snaps from') do |site_1|
    elements = site_1.split("|", 2)
    options[:site_1]  = elements[0]
    options[:_4x4_1]  = elements[1]
  end

  opts.on('-d', '--site2 SITE_2|4x4', 'The second site to get snaps fromm') do |site_2|
    elements = site_2.split("|", 2)
    options[:site_2]  = elements[0]
    options[:_4x4_2]  = elements[1]
  end

  opts.on('-r', '--routes ROUTE:ROUTE:ROUTE...', 'The routes within each site to visit') do |routes|
    options[:routes] = routes
  end

  opts.on('-u', '--user USER', 'The user to login to the sites with') do |user|
    options[:user] = user
  end

  opts.on('-p', '--password PASSWORD', 'The the password for the user') do |password|
    options[:password] = password
  end

  opts.on('-o', '--override', 'Override the URL for the site and use a full URL to take a snapshot') do |override|
    options[:override] = true
  end

  opts.on('-c', '--compare_files DOMAIN#FILE_PATH#FILE_PATH', 'Compare two snapshot files already written and report if they are identical. Separate by #') do |compare_files|
      elements = compare_files.split("#", 3)
      options[:domain]  = elements[0]
      options[:pic_1]   = elements[1]
      options[:pic_2]   = elements[2]
  end

  opts.on('-h', '--help', 'Display Help') do
    puts(opts)
    exit
  end
end.parse!

siteArray ||= []

if options[:mode] == 'snap'
  siteArray << Site.new(options[:site_1], options[:_4x4_1], options[:user], options[:password], options[:route])

  if !options[:override].nil?
    puts("page: #{options[:site_1]}")
    siteArray[0].current_url = options[:site_1]
  end

  snapper = Snapper.new(siteArray)
  snapper.snap_shot

elsif options[:mode] == 'diff'
  siteArray << Site.new(options[:site_1], options[:_4x4_1], options[:user], options[:password], options[:routes])
  siteArray << Site.new(options[:site_2], options[:_4x4_2], options[:user], options[:password], options[:routes])
  snapper = Snapper.new(siteArray)
  snapper.process_sites
elsif options[:mode] == 'compare_files'
  snapper = Snapper.new(siteArray)
  puts("Comparing #{options[:pic_1]} to #{options[:pic_2]} from domain #{options[:domain]}")
  snapper.compare_snapshots(options[:domain], options[:pic_1], options[:pic_2])
else
  puts("Invalid request.")
  puts(opts)
end
