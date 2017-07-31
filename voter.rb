require "selenium-webdriver"
require "httparty"
require "colorize"


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


api_url = "https://www.codewars.com/api/v1/users/" + username
response = HTTParty.get(api_url).parsed_response
total_items = response['codeChallenges']['totalCompleted']
total_pages = (total_items + 200 - 1) / 200
puts "total_items: #{total_items}, total_pages: #{total_pages}".colorize(:green)+ "\nfetching katas:\n"
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


puts "How many browser instances(1-8):".colorize(:color=>:blue, :background=>:white)
instances = [[(STDIN.gets.to_i).abs, 1].max, 8].min

paged_katas = kata_ids.each_slice(kata_ids.length/instances).to_a
paged_katas[instances-2].concat(paged_katas.pop) if paged_katas[instances-1] && instances > 1
paged_katas.map! { |katas| Hash[katas.zip(Array.new(katas.length, nil))] }


wait = Selenium::WebDriver::Wait.new(:timeout => 5)
errors = {}
count = 0
threads = []

(0...instances).each do |i|
  threads << Thread.new do
    browser = Selenium::WebDriver.for :chrome
    browser.navigate.to "https://www.codewars.com/users/#{username}"
    cookie = browser.manage.add_cookie(:name => "remember_user_token", :value => token)
    browser.navigate.to "https://www.codewars.com/users/#{username}"
    logged_in = wait.until { browser.find_element(:class, "profile-pic") }
    katas = paged_katas[i]
    puts "\n" + "instance #{i} is voting on #{katas.size} katas.".colorize(:background=>:magenta)
    katas.each do |id, rank|
      msg = ""
      browser.navigate.to "https://www.codewars.com/kata/#{id}/discuss"
      begin
        vote_panel = wait.until { browser.find_element(:class, "vote-assessment") }
      rescue Exception => err
        puts "\n" + "id: #{id}, Exception: #{err}".colorize(:background=>:red) + "\n"
        errors[id] = err
        next
      end
      voted = vote_panel.find_element(:class, "is-active") rescue nil
      if voted
        rank = voted.attribute("data-value").to_i
        katas[id] = rank
        msg = "already voted " + "#{%w(neutral satisfied unsatisfied)[rank]}"
                .colorize([:yellow, :green, :red][rank]) + "\n"
      else
        vote_panel.find_element(:css, "li > *").click
        msg = "voted " + "satisfied".colorize(:green) + "\n"
      end
      puts "\nkata_id: #{id},  instance: #{i}\n" + msg + "kata: #{count+=1}/#{total_items}"
    end
    puts "\n" + "instance: #{i} is Finished!".colorize(:background=>:magenta)
    browser.quit
  end
end
threads.each { |t| t.join}


puts "Finished!\nPress RETURN to quit"
STDIN.gets
