require "httparty"
require "colorize"
require "fileutils"
require "json"
require "selenium-webdriver"
require_relative "voter/kata"
require_relative "voter/user"


class Voter
  attr_reader :katas
  def initialize(user, token:nil, instances:1, timeout:5)
    @user = user
    @token = token || ENV['CODEWARS_TOKEN']
    @instances = instances
    @paged_katas = Katas.page(user.katas, instances)
    @timeout = 5
  end

  def setup_browser
    browser = Selenium::WebDriver.for :chrome
    browser.navigate.to "https://www.codewars.com/users/#{@user.name}"
    browser.manage.add_cookie(:name => "remember_user_token", :value => @token)
    browser
  end

  def vote_color(i)
    "#{%w(neutral satisfied unsatisfied)[i]}".colorize([:yellow, :green, :red][i])
  end

  def update_user
    @user.katas = Katas.merge(@paged_katas)
  end

  def log_failed_ids(errors)
    file_name = "#{Time.now.strftime('%Y-%m-%d-%H-%M-%S')}_failed.json"
    File.open(File.join('user_data', @user.name, file_name), 'w') { |f| f.write(JSON.pretty_generate(errors)) }
    puts "\n"+"failed ids logged to #{file_name}".colorize(:background=>:red)
  end


  def vote
    wait = Selenium::WebDriver::Wait.new(:timeout => @timeout)
    errors = {}
    count = 0
    total = Katas.filter(@user.katas).length
    threads = []
    puts "\nvotable katas: #{total}\n".colorize(:green)

    (0...@instances).each do |i|
      threads << Thread.new do
        browser = setup_browser
        logged_in = wait.until { browser.find_element(:class, "profile-pic") }
        katas, filtered_katas = @paged_katas[i], Katas.filter(@paged_katas[i])
        puts "\n" + "instance #{i} is voting on #{filtered_katas.size} katas.".colorize(:background=>:magenta)

        filtered_katas.each do |id, data|
          msg = ""
          browser.navigate.to "https://www.codewars.com/kata/#{id}/discuss"

          begin
            vote_panel = wait.until { browser.find_element(:class, "vote-assessment") }
          rescue Exception => err
            puts "err.class: #{err.class}"
            errors[id] = err.message
            puts "\n" + "id: #{id}, Exception: #{err}".colorize(:background=>:red) + "\n"
            next
          end

          voted = vote_panel.find_element(:class, "is-active") rescue nil
          if voted
            katas[id]['rank'] = voted.attribute("data-value").to_i
            msg = "already voted " + vote_color(katas[id]['rank']) + "\n"
          else
            vote_panel.find_element(:css, "li > *").click
            katas[id]['rank'] = 1
            msg = "voted " + vote_color(katas[id]['rank']) + "\n"
          end

          puts "\nkata_id: #{id},  instance: #{i}\n" + msg + "kata: #{count+=1}/#{total}"
        end

        puts "\n" + "instance: #{i} is Finished!".colorize(:background=>:magenta)
        browser.quit
      end
    end
    threads.each { |t| t.join}
    p errors
    log_failed_ids(errors) unless errors.empty?
    update_user
  end

end
