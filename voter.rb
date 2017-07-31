require "selenium-webdriver"
require "httparty"
require "colorize"

browser = Selenium::WebDriver.for :chrome
wait = Selenium::WebDriver::Wait.new(:timeout => 1)

puts "Enter Codewars username:".colorize(:color=>:blue, :background=>:white)
username = STDIN.gets.chomp
token = ENV['CODEWARS_TOKEN']
if token
  puts "CODEWARS_TOKEN read from Environment Variable".colorize(:green)
else
  puts "Environment variable: \"CODEWARS_TOKEN\" not found. Enter Codewars auth token:"
          .colorize(:color=>:blue, :background=>:white)
  token = STDIN.gets.chomp
end


browser.navigate.to "https://www.codewars.com/users/#{username}"
cookie = browser.manage.add_cookie(:name => "remember_user_token", :value => token)
browser.navigate.to "https://www.codewars.com/users/#{username}"

api_url = "https://www.codewars.com/api/v1/users/" + username
response = HTTParty.get(api_url).parsed_response
total_items = response['codeChallenges']['totalCompleted']
total_pages = (total_items + 200 - 1) / 200
puts "total_items: #{total_items}, total_pages: #{total_pages}\nfetching katas:".colorize(:green)
kata_ids = []
threads = []


(0...total_pages).each do |i|
  threads << Thread.new do
    url = api_url + "/code-challenges/completed?page=#{i}"
    HTTParty.get(url).parsed_response['data'].each { |kata| kata_ids << kata['id'] }
    puts "request completed: #{url}\n#{kata_ids.size}/#{total_items} received\n".colorize(:green)
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
