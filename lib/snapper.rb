require 'nokogiri'
require 'selenium-webdriver'
require_relative 'snapper_compare'
require_relative 'snapper_error_check'
require_relative 'snapper_page_finder'
require_relative 'utils'

# Class that drives the processing of commands to the library
class Snapper
  attr_accessor :sites
  @sites

  # initialize the class
  def initialize(_sites=[], verbose=false)
    @sites = _sites
    verbosity = verbose ? Logger::DEBUG : Logger::INFO
    @log = Utils::Log.new(true, true, verbosity)
    @log.debug("Sites length: #{@sites.length}")
  end

  # snap shot a site
  def snap_shot
    mismatches = 0

    # take the snapshot. if we set the tool to re-baseline the site, do that and don't run a comparison
    # else, run the comparison against the previous baseline and report
    @sites.each do |site|
      site.take_and_save_snapshot
      if !site.make_baseline_snapshot
        if site.matches_with_baseline?
          @log.info("Snap matches baseline")
        else
          @log.warn("Snap does not match baseline")
          mismatches = mismatches + 1
        end
      else
        @log.info("No baseline comparisons requested")
      end
    end

    mismatches
  end

  # run through the site list, processing them
  def process_sites
    @sites.each do |site|
      site.process_site
    end

    if @sites.length == 2
      if compare_sites
        @log.info("Comparison of images showed a match")
        return 0 # passing return code for Jenkins
      else
        @log.warn("Comparison of images showed a mismatch")
        return 1 # failing return code for Jenkins
      end
    else
      @log.warn("Skipping snapshot comparison. Incorrect number of sites.")
    end
  end

  # given two png files, compare them for size and graphical differences
  def compare_snapshots(domain_name, baseline_img, candidate_img, log_dir="logs")
    compare_pictures = ImageComparison.new(domain_name, baseline_img, candidate_img, log_dir)
    if compare_pictures.image_dimensions_match?
      compare_pictures.detailed_compare_images
    else
      return 1 #images differ. failing return code for Jenkins
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

    @log.info("Report: #{@sites[0].log_dir}/snap_comparison.html")

    if result == true
      @log.debug("The sites are the same")
      return result #pass
    else
      @log.warn("The sites are not the same")
      return result #fail
    end
  end
end
