require "selenium-webdriver"
require "httparty"
require "io/console"

browser = Selenium::WebDriver.for :chrome
wait = Selenium::WebDriver::Wait.new(:timeout => 1)

loop do
  browser.navigate.to "https://www.github.com/login/"
  puts "Enter Github login:"
  login = STDIN.gets
  puts "Enter Github password:"
  password = STDIN.noecho(&:gets)

  login_user = wait.until { browser.find_element(:name, "login") }
  login_pass = wait.until { browser.find_element(:name, "password") }

  login_user.send_keys(login.chomp)
  login_pass.send_keys(password.chomp)
  login_pass.submit

  logged_in = wait.until { browser.find_element(:class, "logged-in") } rescue nil
  puts logged_in  ? "login success!" : "login failed, retrying"
  break if logged_in
end

browser.navigate.to "https://www.codewars.com/users/preauth/github/signin"
profile_link = wait.until { browser.find_element(:id, "header_profile_link") }
username = profile_link.attribute("href").sub("https://www.codewars.com/users/", '')

api_url = "https://www.codewars.com/api/v1/users/" + username
response = HTTParty.get(api_url).parsed_response
total_items = response['codeChallenges']['totalCompleted']
total_pages = (total_items + 200 - 1) / 200
kata_ids = {}

puts "total_pages: #{total_pages}, total_items: #{total_items}\nfetching katas:"
threads = []
(0...total_pages).each do |i|
  threads << Thread.new do
    url = api_url + "/code-challenges/completed?page=#{i}"
    HTTParty.get(url).parsed_response['data'].each { |kata| kata_ids[kata['id']] = nil }
    puts "request completed: #{url}\n#{kata_ids.size}/#{total_items} received\n"
  end
end
threads.each { |t| t.join }

puts "Received all #{total_items} katas.\nvoting on katas:\n"
kata_ids.each do |id, rank|
  puts "\nkata: #{id}"
  browser.navigate.to "https://www.codewars.com/kata/#{id}/discuss"
  begin
    vote_panel = wait.until { browser.find_element(:class, "vote-assessment") }
  rescue Exception => err
    puts err
    next
  end
  voted = vote_panel.find_element(:class, "is-active") rescue nil
  if voted
    rank = voted.attribute("data-value").to_i
    kata_ids[id] = rank
    puts "already voted #{%w(neutral satisfied unsatisfied)[rank]}"
  else
    vote_panel.find_element(:css, "li > *").click
    kata_ids[id] = 1
    puts "voted satisfied"
  end
end

puts "Finished!\nPress RETURN to quit"
STDIN.gets
browser.quit
