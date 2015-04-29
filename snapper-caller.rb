require 'csv'
require 'optparse'
require_relative 'lib/snapper'
require_relative 'lib/site'
require_relative 'lib/utils'

options = {}
log = Utils::Log.new(true, true)

OptionParser.new do |opts|
  opts.banner = "Usage: <script.rb> [options]"

  opts.on('-m', '--mode MODE', 'The operation to execute') do |mode|
    options[:mode] = mode
  end

  opts.on('-s', '--site1 SITE_1#4x4', 'The site to get snaps from') do |site_1|
    elements = site_1.split("#", 2)
    options[:site_1]  = elements[0]
    options[:_4x4_1]  = elements[1]
  end

  opts.on('-d', '--site2 SITE_2#4x4', 'The second site to get snaps fromm') do |site_2|
    elements = site_2.split("#", 2)
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

  opts.on('-c', '--compare_files DOMAIN#FILE_PATH_TO_BASELINE_IMG#FILE_PATH_TO_CANDIDATE_IMG', 'Compare two snapshot files already written and report if they are identical. Separate by #') do |compare_files|
      elements = compare_files.split("#", 3)
      options[:domain]  = elements[0]
      options[:baseline_img]   = elements[1]
      options[:candidate_img]   = elements[2]
  end

  opts.on('-f', '--file FULL_FILE_PATH', 'The csv file to consume for site baselining') do |csv_file|
    options[:csv_file] = csv_file
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
    log.info("page: #{options[:site_1]}")
    siteArray[0].current_url = options[:site_1]
  end

  snapper = Snapper.new(siteArray)
  snapper.snap_shot

elsif options[:mode] == 'diff'
  siteArray << Site.new(options[:site_1], options[:_4x4_1], options[:user], options[:password], options[:routes])
  siteArray << Site.new(options[:site_2], options[:_4x4_2], options[:user], options[:password], options[:routes])
  snapper = Snapper.new(siteArray)
  snapper.process_sites
elsif options[:mode] == 'compare_files_csv'
  if File.exists? options[:csv_file]
    CSV.foreach(options[:csv_file]) do |row|
      log.info(row.to_s)
      site_new = Site.new(options[:site_1], row[0].split('/').last, options[:user], options[:password], options[:route])
      site_new.current_url = row[0].to_s
      site_new.run_page_checks = false
      site_new.baseline_snapshot = row[1].to_s.strip == "true" ? true : false
      siteArray << site_new
      log.info row[0].to_s << " " << siteArray.length
    end

    snapper = Snapper.new(siteArray)
    if snapper.snap_shot > 0
      log.warn("Sites in CSV differ from baseline")
      1 # failure case for Jenkins
    else
      log.info("Sites in CSV don't differ from baseline")
      0 # success case for Jenkins
    end
  else
    log.error("File: #{csv_file} not found.")
    1 # failure case for Jenkins
  end


elsif options[:mode] = 'compare_files'
  snapper = Snapper.new(siteArray)
  log.info("Comparing baseline: #{options[:baseline_img]} to candidate: #{options[:candidate_img]} from domain #{options[:domain]}")
  snapper.compare_snapshots(options[:domain], options[:baseline_img], options[:candidate_img])
else
  log.error("Invalid request.")
  log.error(opts)
  1 # failure case for Jenkins
end
