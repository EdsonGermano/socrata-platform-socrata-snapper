require 'fileutils'
require 'nokogiri'
require 'uri'
require_relative 'snapper_compare'
require_relative 'snapper_error_check'
require_relative 'snapper_page_finder'
require_relative 'utils'

# The site class which manages all interactions with a particular website
class Site
  attr_accessor :domain, :_4x4, :user, :password, :routes, :current_url, :data_lens, :processing_messages, :snap_files, :diff_files, :log_dir, :body_files, :body_messages, :run_page_checks, :make_baseline_snapshot
  GOOD_RESULT = "res/awesome.png"
  BAD_RESULT  = "res/not_awesome.png"

  # Initialize the Site object.
  def initialize(_domain, _4x4, _user, _password, _routes="", _override=false, _verbose=false)

    verbosity = _verbose ? Logger::DEBUG : Logger::INFO
    @log = Utils::Log.new(true, true, verbosity)

    @domain       = _domain
    @driver       = Utils::WebBrowser.new(false)
    @password     = _password
    @routes       = _routes.nil? ? "" : _routes.split(':')
    @user         = _user
    @working_dir  = Dir.pwd
    @_4x4         = _4x4
    @data_lens
    @log_dir      = "logs"
    @wait         = 5
    #if you override you are planning to explicitly tell what URL to snap by assigning the full URL to this variable as an explicit assignment
    @current_url  = _override ? nil : "https://#{@domain}/d/#{@_4x4}"
    @processing_messages = []
    @snap_files   = {}
    @diff_files   = {}
    @baseline_files = {}
    @body_files   = ""
    @body_messages      = ""
    @run_page_checks    = true
    @make_baseline_snapshot  = false
  end

  # build the site comparison report.
  def build_report(site_2)
    @log.debug("Building HTML report")

    snap_files.each do |key, value|
      site1_file = value
      site2_file = (site_2.snap_files.has_key? key) ? site_2.snap_files[key] : ""
      diff_file = GOOD_RESULT

      if(!@diff_files.nil? && @diff_files.has_key?(key))
        diff_file = (!@diff_files[key].empty?) ? "#{@diff_files[key]}" : BAD_RESULT
      end

      @body_files   << [
        "<br>",
        "<h3 align='center'>Domain: <a href='https://#{@domain}'>#{@domain}</a>",
        "<h3 align='center'>File: <a href='../#{site1_file}'>#{site1_file}</a> compared with <a href='../#{site2_file}'>#{site2_file}</a></h3>",
        "<table border=2 width='900' align='center'>",
        "<tr>",
        "<td><a href='../#{site1_file}'><img src='../#{site1_file}' alt='#{site1_file}' width='300'></a></td>",
        "<td><a href='../#{site2_file}'><img src='../#{site2_file}' alt='#{site2_file}' width='300'></a></td>",
        "<td><a href='../#{diff_file}'><img src='../#{diff_file}' alt='#{diff_file}' width='300'></a></td>",
        "</table>",
        "<br>"
      ].join('')
    end

    if(!@processing_messages.nil?)
      @log.debug("Processing message count: #{@processing_messages.count}")
      @body_messages << "<tr>"

      processing_messages.each { |key, value|
        @body_messages << "<td width='30%'><font size='2'>#{key}</font></td>"
        @body_messages << "<td width='70%'><font size='2'>#{value}</font></td>"
        @body_messages << "</tr>"
        @body_messages << "<tr bgcolor='black'></tr>"
      }
    end
  end

  # function to compare this site snapshots with another
  def compare_to(site_2)
    matching = []

    snap_files.each do |key, value|
      if site_2.snap_files.has_key?(key)
        value2 = site_2.snap_files[key]
        @log.info("Comparing: #{key} route of #{log_dir}/#{value} => #{log_dir}/#{value2}")
        matching << compare_snapshots(key, "#{log_dir}/#{value}", "#{log_dir}/#{value2}")
      else
        @log.info("Snap route lists don't match. Missing #{key}")
        matching << false
      end
    end

    if matching.include? false
      return false
    else
      return true
    end
  end

  # navigate to a particular page
  def navigate_to(route, full_path=false)
    route_url = route

    if !full_path
      route_url = "https://#{@domain}/#{route}"
    end

    @log.info("Navigating to: #{route_url}")

    begin
      @driver.browser.navigate.to(route_url)
      @driver.browser.manage.window.resize_to(1600, 1200)
      sleep(@wait)
    rescue
      @log.info("URL not found")
      @driver.browser.close
    end
  end

  # function which visits all site routes taking snapshots and collecting data
  def process_site
    # sign in if required
    if !@user.nil? && !@password.nil?
      sign_in
    else
      @log.debug("Not logging in. No Username or Password provided")
    end

    # visit each route, taking snapshots
    if @routes.nil? || @routes.empty?
      @log.debug("No routes defined for naviation")
    else
      @routes.each do |route|
        navigate_to(route)
        check_and_capture
      end
    end

    @current_url = get_nbe_datalens_url_from_obe

    if !@current_url.nil?
      navigate_to(@current_url, true)
      check_and_capture
    else
      @log.warn("No NBE site located for this OBE source")
    end
    @driver.browser.close
  end

  # function to sign in (if requested), navigate and check and capture page
  def take_and_save_snapshot
    # sign in if required
    if !@user.nil? && !@password.nil?
      if @current_url.include?("/view/")
        sign_in_data_lens
      elsif @current_url.include?("/dataset/")
        sign_in
      else
        @log.warn("Login credentials provided for an unsupported page: #{@current_url}")
      end
    end

    navigate_to(@current_url, true)
    check_and_capture
    @driver.browser.close
  end

  # check for baseline mismatches when doing delta comparisons
  # find all the baseline files that may exist in the log directory
  def matches_with_baseline?
    png_files = Dir.glob("#{@log_dir}/*.baseline.png")
    mismatches = 0
    baseline_found = false
    baseline_files = []
    png_files.each do |png|
      @snap_files.each do |key, element|
        elements = element.split('.')
        if png.include?(elements[0]) && png.include?("baseline")
          @log.debug("Baseline found >> #{png}")
          baseline_found = true
          baseline_files << png
          if !compare_snapshots(@domain, "#{@log_dir}/#{element}", png)
            mismatches = mismatches + 1
          end
        end
      end
    end

    if !baseline_found
      @log.info("No baseline file found")
    end

    if mismatches > 0
      return true
    else
      return false
    end
  end

  private

  # run page and javascript checks and then snap picture
  def check_and_capture
    if run_page_checks
      if !check_for_page_errors
        check_for_javascript_errors
        snap("#{@domain}", @_4x4)
      end
    else
      snap("#{@domain}", @_4x4)
    end
  end

  # sign in to the login page for a domain
  def sign_in
    begin
      @log.debug("Signing in")
      @current_url = "https://#{@domain}/login"
      navigate_to_sign_in
      generic_sign_in
      snap("dataset", @_4x4)
    rescue => why
      @log.error("Unable to complete operation. Message: #{why.message}")
      @log.error("Operation terminated")
      snap("dataset", @_4x4)
    end
  end

  # sign in to a datalens page
  def sign_in_data_lens
    begin
      @log.debug("Browsing to DataLens")
      @current_url = @domain.include?("http") ? "#{@domain}" : "https://#{@domain}"
      navigate_to_sign_in

      # datalens specific UI
      @log.debug("Sign in")
      element = @driver.browser.find_element(:link, 'Sign In')
      element.click

      generic_sign_in
      snap("view", @_4x4)
    rescue => why
      @log.error("Unable to complete operation. Message: #{why.message}")
      @log.error("Operation terminated")
      snap("view", @_4x4)
    end
  end

  def navigate_to_sign_in
    @driver.browser.navigate.to(@current_url)
    @driver.browser.manage.window.resize_to(1600, 1200)
    check_for_javascript_errors
    @log.debug("Done looking for javascript errors")
    @log.debug("Logging into DataLens")
    snap("sign_in", @_4x4)
  end

  def generic_sign_in
    # enter user in username field
    @log.info("Input username")
    element = @driver.browser.find_element(:id, 'user_session_login')
    element.clear
    element.send_keys(@user)

    @log.info("Input password")
    # enter password
    element = @driver.browser.find_element(:id, 'user_session_password')
    element.clear
    element.send_keys(@password)

    @log.info("Click commit")
    # click submit button
    element = @driver.browser.find_element(:name, 'commit')
    element.click
    sleep(@wait)

    @current_url = @driver.browser.current_url
    @log.debug("Now On #{@driver.browser.current_url}")
  end

  # snap an image from a website and write it locally
  def snap(route, _4x4)
    @log.info("Snapping [#{@current_url}] for route [#{route}]")

    # give it x seconds for the page to load
    sleep(@wait)

    File.mkdir(@log_dir) unless File.exists?(@log_dir)

    if route.nil? || route.empty?
      url = URI.escape(@current_url)
      uri = URI.parse(url)
      route = uri.host
    end

    _4x4 = _4x4.nil? ? "override" : _4x4.strip
    png_name = route.gsub(".", "_")
    png_name = png_name.gsub("http://","").gsub("https://", "")

    snap_file = "#{png_name}_#{_4x4}.png"
    snap_file = snap_file.gsub('/', '_')

    @driver.browser.save_screenshot("#{@log_dir}/#{snap_file}")
    snap_files[route] = snap_file

    @log.info("Snap finished. File written: #{snap_files[route]} snap_file count: #{@snap_files.length}")
    @log.debug("Make new baseline requested? #{@make_baseline_snapshot}")

    if @make_baseline_snapshot
      set_baseline_image(snap_files[route])
    end
    return snap_files[route]
  end

  # compare an image with the current image name
  def compare_snapshots(route, image_1, image_2)
    if(image_1 == image_2)
      @log.info("These are the same image. Skipping comparison")
      @diff_files = {route => GOOD_RESULT}
      return true
    else
      compare = ImageComparison.new(route, image_1, image_2, @log_dir)

      if compare.image_dimensions_match?
        @log.info("Image dimensions match")
        if compare.detailed_compare_images == 1
          @diff_files[route] = GOOD_RESULT
          return true
        else
          @diff_files[route] = compare.diff_img
          return false
        end
      else
        @log.info("Image dimensions DON'T match")
        @diff_files[route] = BAD_RESULT
        return false
      end
    end
  end

  # get the nbe datalens url & 4x4 from obe 4x4
  def get_nbe_datalens_url_from_obe
    begin
      pf = PageFinder.new(@domain, @user, @password, false)
      @data_lens = pf.get_nbe_page_id_from_obe_uri(@current_url, @_4x4)
    rescue => why
      @log.error("An error occured while looking for a NBE datalens URL. Message: #{why.message}")
    end
  end

  # move a logged image to the backup folder
  def archive_image(image, log_dir="logs/backup")
    now = Time.now.to_i
    if !Dir.exists? log_dir
      Dir.mkdir(log_dir, 0766)
    end

    archived_image = "#{Dir.pwd}/#{log_dir}/" << File.basename(image, ".png") << ".#{now.to_s}.png"
    @log.info("Archiving file #{image} to #{archived_image}")
    File.rename(image, archived_image)
  end

  # archive the old baseline and set a new one
  def set_baseline_image(image)
    baseline_file_name = File.basename(image, ".png") << ".baseline.png"
    baseline_img_path = "#{Dir.pwd}/#{log_dir}/" << baseline_file_name

    if File.exists? baseline_img_path
      @log.info("File: #{baseline_img_path} exists. Archiving.")
      archive_image(baseline_img_path)
    end

    File.rename("#{@log_dir}/#{image}", baseline_img_path)
    @log.debug("Renamed file: #{Dir.pwd}/#{@log_dir}/#{image} to: #{baseline_img_path}")
  end

  # check a page for javascript errors
  def check_for_javascript_errors
    errors = ErrorCheck.new()
    if errors.javascript_errors(@current_url, @log_dir)
      if !errors.results.nil?
        @log.error("Message count: #{errors.results.count}")
        @processing_messages << @current_url << errors.results.join(" ")
        return true
      else
        @processing_messages << @current_url << " No javascript errors found"
      end
    else
      return false
    end
  end

  # check for page response errors
  def check_for_page_errors
    errors = ErrorCheck.new()
    if errors.page_errors?(@current_url, @log_dir)
      @processing_messages = @current_url << " Error page result found"
      return true
    else
      @processing_messages << @current_url << " Page result OK"
      return false
    end
  end
end
