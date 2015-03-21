# includes
require 'snapper_compare'
require 'snapper_error_check'
require 'snapper_page_finder'
require 'fileutils'
require 'nokogiri'
require 'selenium-webdriver'

class Snapper
  attr_accessor :sites
  HTTPS = "https://"
  @sites = []

  # initialize the class
  def initialize(_sites=nil)
    @sites = _sites
    puts("sites length: #{@sites.length}")
  end

  def snap_shot
    @sites.each do |site|
      puts("Snapshoting: #{site.current_url}")
      site.take_and_archive_snapshot
    end
  end

  def process_sites
    @sites.each do |site|
      site.process_site
    end

    if @sites.length == 2
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
        return 1 #pass
      else
        puts("the sites are not the same")
        return 0 #fail
      end
    else
      puts("Invalid number of sites")
      return 2 #not tested
    end
  end
end

class Site
  attr_accessor :domain, :_4x4, :user, :password, :routes, :current_url, :data_lens, :processing_messages, :snap_files, :diff_files, :log_dir, :body_files, :body_messages
  HTTPS = "https://"

  def initialize(_domain, _4x4, _user, _password, _routes="")

    profile = Selenium::WebDriver::Firefox::Profile.new
    begin
      profile.add_extension("res", "JSErrorCollector.xpi")
      puts("JSErrorCollected loaded")
      @loaded = "true"
    rescue => why
      puts("JSErrorCollector failed to load")
      puts("ERROR: #{why.message}")
    end

    @domain       = _domain
    @driver       = Selenium::WebDriver.for :firefox, :profile => profile
    @password     = _password.nil? ? "" : _password
    @routes       = _routes.nil? ? "" : _routes.split(':')
    @user         = _user.nil? ? "" : _user
    @working_dir  = Dir.pwd
    @_4x4         = _4x4
    @data_lens    = ''
    @log_dir      = "logs"
    @wait         = 5
    @current_url  = "#{HTTPS}#{@domain}/d/#{@_4x4}"
    @processing_messages = {}
    @snap_files   = {}
    @diff_files   = {}
    @body_files   = ""
    @body_messages = ""
  end

  def build_report(site_2)
    puts("Building HTML report")

    self.snap_files.each do |key, value|
      site1_file = value
      site2_file = (site_2.snap_files.has_key? key) ? site_2.snap_files[key] : ""
      diff_file = "res/awesome.png"

      if(!@diff_files.nil? && @diff_files.has_key?(key))
        diff_file = (!@diff_files[key].empty?) ? "#{@diff_files[key]}" : "res/not_awesome.png"
      end

      @body_files   << "<br>"
      @body_files   << "<h3 align='center'>Domain: <a href='https://#{@domain}'>#{@domain}</a>"
      @body_files   << "<h3 align='center'>File: <a href='../#{site1_file}'>#{site1_file}</a> compared with <a href='../#{site2_file}'>#{site2_file}</a></h3>"
      @body_files   << "<table border=2 width='900' align='center'>"
      @body_files   << "<tr>"
      @body_files   << "<td><a href='../#{site1_file}'><img src='../#{site1_file}' alt='#{site1_file}' width='300'></a></td>"
      @body_files   << "<td><a href='../#{site2_file}'><img src='../#{site2_file}' alt='#{site2_file}' width='300'></a></td>"
      @body_files   << "<td><a href='../#{diff_file}'><img src='../#{diff_file}' alt='#{diff_file}' width='300'></a></td>"
      @body_files   << "</table>"
      @body_files   << "<br>"
      @body_files   << ""
    end

    if(!@processing_messages.nil?)
      puts("Processing message count: #{@processing_messages.count}")
      @body_messages << "<tr>"

      processing_messages.each { |key, value|
        @body_messages << "<td width='30%'><font size='2'>#{key}</font></td>"
        @body_messages << "<td width='70%'><font size='2'>#{value}</font></td>"
        @body_messages << "</tr>"
        @body_messages << "<tr bgcolor='black'></tr>"
      }
    end
  end

  # check a page for javascript errors
  def check_for_javascript_errors
    @processing_messages[@current_url] = ""
    errors = ErrorCheck.new()
    if errors.javascript_errors(@current_url, @log_dir, @driver)
      if(!errors.results.nil?)
        puts("Message count: #{errors.results.count}")
        @processing_messages[@current_url] = errors.results.join(" ")
        return true
      end
    else
        return false
    end
  end

  # function to compare this site snapshots with another
  def compare_to(site_2)
    matching = true

    self.snap_files.each do |key, value|
      if site_2.snap_files.has_key?(key)
        value2 = site_2.snap_files[key]
        puts("Comparing: #{key} route of #{value} => #{value2}")
        matching |= compare_snapshots(key, value, value2)
      else
        puts("Snap route lists don't match. Missing #{key}")
        matching |= false
      end
    end
    return matching
  end

  # compare an image with the current image name
  def compare_snapshots(route, image_1, image_2)
    if(image_1 == image_2)
      puts("These are the same image. Skipping comparison")
      @diff_files = {route => "res/awesome.png"}
      true
    else
      compare = ImageComparison.new(route, image_1, image_2, @log_dir)

      if compare.image_dimensions_match?
        puts("Image dimensions match")
        if compare.detailed_compare_images == 1
          @diff_files[route] = "res/awesome.png"
        else
          @diff_files[route] = compare.diff_img
        end
      else
        puts("Image dimensions DON'T match")
        @diff_files[route] = "res/not_awesome.png"
      end
    end
  end

  # get the nbe datalens url & 4x4 from obe 4x4
  def get_nbe_datalens_url_from_obe
    begin
      pf = PageFinder.new(@domain, @user, @password, false)
      @data_lens = pf.get_nbe_page(@current_url, @_4x4)
    rescue => why
      puts("An error occured while looking for a NBE datalens URL. Message: #{why.message}")
    end
  end

  # navigate to a particular page
  def navigate_to(route, full_path=false)
    route_url = route

    if !full_path
      route_url = "#{HTTPS}#{@domain}/#{route}"
    end

    puts("navigating to: #{route_url}")

    begin
      @driver.navigate.to(route_url)
      sleep(@wait)
    rescue
      puts("URL not found")
      @driver.close
    end
  end

  # function which visits all site routes taking snapshots and collecting data
  def process_site
    # sign in if required
    if !@user.empty? && !@password.empty?
      sign_in
    else
      puts("Not logging in. No Username or Password provided")
    end

    # visit each route, taking snapshots
    @routes.each do |route|
      navigate_to(route)
      check_for_javascript_errors
      snap(route, @_4x4)
    end

    @current_url = get_nbe_datalens_url_from_obe

    if !@current_url.nil? && !@current_url.empty?
      navigate_to(@current_url, true)
      check_for_javascript_errors
      snap("data_lens", @_4x4)
    else
      puts("No NBE site located for this OBE source")
    end
    @driver.close
  end

  def take_and_archive_snapshot
    target_url = @current_url
    # sign in if required
    if !@user.empty? && !@password.empty?
      sign_in
    end

    @current_url = target_url
    navigate_to(@current_url, true)

    check_for_javascript_errors
    snap("#{@domain}_snap", @_4x4)
    @driver.close
  end

  # sign in to the login page for a domain
  def sign_in
    begin
      puts("Signing in")
      @current_url = "#{HTTPS}#{@domain}/login"
      @driver.navigate.to(@current_url)
      check_for_javascript_errors
      puts("Done looking for javascript errors")
      snap("sign_in", @_4x4)

      puts("Input user")
      # enter user in username field
      element = @driver.find_element(:id, 'user_session_login')
      element.clear
      element.send_keys(@user)

      puts("Input password")
      # enter password
      element = @driver.find_element(:id, 'user_session_password')
      element.clear
      element.send_keys(@password)

      puts("Click commit")
      # click submit button
      element = @driver.find_element(:name, 'commit')
      element.click
      sleep(@wait)
      check_for_javascript_errors
      @current_url = @driver.current_url
      puts("Now On #{@driver.current_url}")
      snap("dataset", @_4x4)
    rescue => why
      puts("Unable to complete operation. Message: #{why.message}")
      puts("Operation terminated")
      snap("dataset", @_4x4)
    end
  end

  # snap an image from a website and write it locally
  def snap(route, _4x4)
    puts("snapping #{@current_url} for route #{route}")

    # give it x seconds for the page to load
    sleep(@wait)

    FileUtils.mkdir_p(@log_dir) unless File.exists?(@log_dir)

    puts("writing file here #{@log_dir}/#{route}_#{_4x4}.png")

    @driver.save_screenshot("#{@log_dir}/#{route}_#{_4x4}.png")
    self.snap_files[route] = "#{@log_dir}/#{route}_#{_4x4}.png"

    puts("finished. snap_file count: #{@snap_files.length}")
    return @current_url
  end
end
