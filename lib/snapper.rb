# includes
require 'selenium-webdriver'
require 'nokogiri'
require 'fileutils'
require 'snapper_page_finder'

class Snapper

  attr_accessor :domain, :user, :password, :driver, :working_dir, :current_url

  # initialize the class
  def initialize(_domain, _obe_id, _user, _password)
    @domain = _domain
    @obe_id = _obe_id
    @user = _user
    @password = _password
    @driver = Selenium::WebDriver.for :chrome
    @working_dir = Dir.pwd
    @current_url = "https://#{@domain}"
    load_wait
  end

  def load_wait
      driver.navigate.to("file:///#{Dir.pwd}/res/pleasewait.html")
  end

  # sign in to the login page for a domain
  def sign_in(signin_wait=5)
    puts("Signing in")
    @current_url = "https://#{@domain}/login"
    driver.navigate.to(@current_url)

    # enter user in username field
    element = driver.find_element(:id, 'user_session_login')
    element.clear
    element.send_keys(@user)

    # enter password
    element = driver.find_element(:id, 'user_session_password')
    element.clear
    element.send_keys(@password)

    # click submit button
    element = driver.find_element(:name, 'commit')
    element.click
    sleep(signin_wait)
    @current_url = driver.current_url
    puts("Now On #{driver.current_url}")
  end

  def navigate_to_new_ux
    begin
      driver.navigate.to(@current_url)
      element = driver.find_element(:id, 'new_ux_link.icon_cards')
      element.click
      sleep(signin_wait)
    rescue
      puts("URL or element not found")
    end
  end

  def snapshot_nbe
    pf = PageFinder.new(@domain, @user, @password, false)
    @current_url = pf.get_nbe_page(@current_url, @obe_id)
  end

  def navigate_to(next_page="", wait=5)
    @current_url =  "https://#{@domain}/" << next_page
    puts("navigating to: #{@current_url}")

    begin
      driver.navigate.to(@current_url)
      sleep(wait)
    rescue
      puts("URL not found")
      driver.close
    end
  end

  # snap an image from a website and write it locally
  def snap(output_file="output.png", log_dir="logs", wait=6)
    # go to URL
    puts("snapping #{@current_url}")
    driver.navigate.to("#{@current_url}")

    # give it 6 seconds to load
    sleep(wait)

    FileUtils.mkdir_p(log_dir) unless File.exists?(log_dir)

    puts("writing file here #{log_dir}/#{output_file}")
    driver.save_screenshot("#{log_dir}/#{output_file}")
    driver.quit();
    puts("finished")
  end

  def write_html(directory)
      head = "<html><body><h1 align=center>Snap Comparisons: #{directory}</h1>"
      body = ""
      tail = "</body></html>"
      @files = []

      Dir.glob("#{directory}/*.png") do |file|
        puts("adding file #{file}")
        @files << file
      end

      (0...@files.length).step(2).each do |index|
        body << "<br>"
        body << "<h3>Domain: <a href='https://#{@domain}'>#{@domain}</a>"
        body << "<h3>File: <a href='../#{@files[index]}'>#{@files[index]}</a> compared with <a href='../#{@files[index + 1]}'>#{@files[index + 1]}</a></h3>"
        body << "<table border=2 width='800'>"
        body << "<tr>"
        body << "<td><img src='../#{@files[index]}' alt='#{@files[index]}' width='700'></td>"
        body << "<td><img src='../#{@files[index +1]}' alt='#{@files[index + 1]}' width='700'></td>"
        body << "</tr>"
        body << "</table>"
        body << "<br>"
      end

      doc = "#{head}#{body}#{tail}"
      File.open("#{directory}/snap_comparison.html", 'w') do |f1|
        f1.puts(doc)
      end
  end
end
