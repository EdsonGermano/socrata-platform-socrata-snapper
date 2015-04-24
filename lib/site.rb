require 'fileutils'
require 'nokogiri'
require 'selenium-webdriver'
require_relative 'snapper_compare'
require_relative 'snapper_error_check'
require_relative 'snapper_page_finder'

# The site class which manages all interactions with a particular website
class Site
  attr_accessor :domain, :_4x4, :user, :password, :routes, :current_url, :data_lens, :processing_messages, :snap_files, :diff_files, :log_dir, :body_files, :body_messages
  GOOD_RESULT = "res/awesome.png"
  BAD_RESULT  = "res/not_awesome.png"

  # Initialize the Site object.
  def initialize(_domain, _4x4, _user, _password, _routes="", _override=false)

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
    @body_files   = ""
    @body_messages = ""
  end

  # build the site comparison report.
  def build_report(site_2)
    puts("Building HTML report")

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

  # function to compare this site snapshots with another
  def compare_to(site_2)
    matching = []

    snap_files.each do |key, value|
      if site_2.snap_files.has_key?(key)
        value2 = site_2.snap_files[key]
        puts("Comparing: #{key} route of #{value} => #{value2}")
        matching << compare_snapshots(key, value, value2)
      else
        puts("Snap route lists don't match. Missing #{key}")
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

    puts("navigating to: #{route_url}")

    begin
      @driver.navigate.to(route_url)
      @driver.manage.window.resize_to(1600, 1200)
      sleep(@wait)
    rescue
      puts("URL not found")
      @driver.close
    end
  end

  # function which visits all site routes taking snapshots and collecting data
  def process_site
    # sign in if required
    if !@user.nil? && !@password.nil?
      sign_in
    else
      puts("Not logging in. No Username or Password provided")
    end

    # visit each route, taking snapshots
    if @routes.nil? || @routes.empty?
      puts("No routes defined for naviation")
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
      puts("No NBE site located for this OBE source")
    end
    @driver.close
  end

  def take_and_archive_snapshot
    # sign in if required
    if !@user.nil? && !@password.nil?
      sign_in
    end

    navigate_to(@current_url, true)
    check_and_capture
    @driver.close
  end

  private

  def check_and_capture
    if !check_for_page_errors
      check_for_javascript_errors
      snap("#{@domain}_snap", @_4x4)
    end
  end

  # sign in to the login page for a domain
  def sign_in
    begin
      puts("Signing in")
      @current_url = "https://#{@domain}/login"
      @driver.navigate.to(@current_url)
      @driver.manage.window.resize_to(1600, 1200)
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

    png_name = route.gsub("/", "_")

    @driver.save_screenshot("#{@log_dir}/#{png_name}_#{_4x4}.png")
    snap_files[route] = "#{@log_dir}/#{png_name}_#{_4x4}.png"

    puts("finished. snap_file count: #{@snap_files.length}")
    return @current_url
  end

  # compare an image with the current image name
  def compare_snapshots(route, image_1, image_2)
    if(image_1 == image_2)
      puts("These are the same image. Skipping comparison")
      @diff_files = {route => GOOD_RESULT}
      return true
    else
      compare = ImageComparison.new(route, image_1, image_2, @log_dir)

      if compare.image_dimensions_match?
        puts("Image dimensions match")
        if compare.detailed_compare_images == 1
          @diff_files[route] = GOOD_RESULT
          return true
        else
          @diff_files[route] = compare.diff_img
          return false
        end
      else
        puts("Image dimensions DON'T match")
        @diff_files[route] = BAD_RESULT
        return false
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

  # check a page for javascript errors
  def check_for_javascript_errors
    errors = ErrorCheck.new()
    if errors.javascript_errors(@current_url, @log_dir)
      if !errors.results.nil?
        puts("Message count: #{errors.results.count}")
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
