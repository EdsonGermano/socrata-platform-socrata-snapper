require 'fileutils'
require 'nokogiri'
require 'selenium-webdriver'
require_relative 'snapper_compare'
require_relative 'snapper_error_check'
require_relative 'snapper_page_finder'

# Class that drives the processing of commands to the library
class Snapper
  attr_accessor :sites
  HTTPS = "https://"
  @sites

  # initialize the class
  def initialize(_sites=[])
    @sites = _sites
    puts("sites length: #{@sites.length}")
  end

  # snap shot a site
  def snap_shot
    @sites.each do |site|
      puts("Snapshoting: #{site.current_url}")
      site.take_and_archive_snapshot
    end
  end

  # run through the site list, processing them
  def process_sites
    @sites.each do |site|
      site.process_site
    end

    if @sites.length == 2
      if compare_sites
        puts("Comparison of images showed a match")
        return true
      else
        puts("Comparison of images showed a mismatch")
        return false
      end
    else
      puts("Skipping snapshot comparison. Incorrect number of sites.")
    end
  end

private

  # call the comparison operation on two sites.
  def compare_sites
    result = @sites[0].compare_to(@sites[1])
    @sites[0].build_report(@sites[1])
    @sites[1].build_report(@sites[0])

    # build comparison html
    head = "<html>
    <head>
      <style>
        body {background-color:white}
        h1   {color:black}
        h2   {color:blue}
        h3   {color:blue}
        h4   {color:blue}
        p    {color:green}
        td   {color:blue}
      </style>
    </head>
    <body>
    <h1 align=center>Snap Comparisons: #{@sites[0].log_dir}</h1>"

    body =
      @sites[0].body_files <<
      "<H4 align='center'>Javascript Error Messages</H4><table align='center' width=975><table border=2 align='center' width=975>" <<
      @sites[0].body_messages <<
      @sites[1].body_messages <<
      "</table><br>"

    tail =   "</body></html>"

    doc = "#{head}#{body}#{tail}"

    File.open("#{@sites[0].log_dir}/snap_comparison.html", 'w') do |f1|
      f1.puts(doc)
    end

    puts("report: #{@sites[0].log_dir}/snap_comparison.html")

    if result == true
      puts("the sites are the same")
      return result #pass
    else
      puts("the sites are not the same")
      return result #fail
    end
  end
end
