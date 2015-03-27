#!/usr/bin/env ruby

$:.unshift(File.expand_path(File.dirname(__FILE__), 'lib'))

require 'optparse'
require 'snapper'
require 'site'

options = {}

OptionParser.new do |opts|
  opts.banner = "Usage: <script.rb> [options]"

  opts.on('-m', '--mode MODE', 'The operation to execute') do |mode|
    options[:mode] = mode
  end

  opts.on('-s', '--site1 SITE_1:4x4', 'The site to get snaps from') do |site_1|
    elements = site_1.split(":", 2)
    options[:site_1] = elements[0]
    options[:_4x4_1] = elements[1]
  end

  opts.on('-d', '--site2 SITE_2:4x4', 'The second site to get snaps fromm') do |site_2|
    elements = site_2.split(":", 2)
    options[:site_2] = elements[0]
    options[:_4x4_2] = elements[1]
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

  opts.on('-h', '--help', 'Display Help') do
    puts(opts)
    exit
  end
end.parse!

siteArray ||= []

if options[:mode] == 'snap'
  siteArray << Site.new(options[:site_1], options[:_4x4_1], options[:user], options[:password], options[:route])
  snapper = Snapper.new(siteArray)
  snapper.snap_shot

elsif options[:mode] == 'diff'
  siteArray << Site.new(options[:site_1], options[:_4x4_1], options[:user], options[:password], options[:routes])
  siteArray << Site.new(options[:site_2], options[:_4x4_2], options[:user], options[:password], options[:routes])
  snapper = Snapper.new(siteArray)
  snapper.process_sites

else
  puts("Invalid request.")
  puts(opts)
end
