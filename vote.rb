require "optparse"
require_relative "lib/voter"


module Vote
  def self.clamp(i=1)
    [[i||1.abs, 1].max, 8].min
  end

  def self.read_token(token)
    token ||= ENV['CODEWARS_TOKEN']
  end
end

options = {}
OptionParser.new do |opt|
  opt.on('-u', '--user USER', 'Your Codewars username') { |o| options[:user] = o }
  opt.on('-t', '--token TOKEN', 'Codewars login token(check README)') { |o| options[:token] = o }
  opt.on('-f', '--load PATH_TO_FILE', 'Path to json file') { |o| options[:file_path] = o }
  opt.on('-i', '--instances INSTANCES', 'Number of Chrome windows(1-8)') { |o| options[:instances] = o.to_i }
  opt.on('-g', '--get', 'Fetch katas without voting') { |o| options[:fetch] = true }
end.parse!

puts `ruby vote.rb --help` if options.empty?
raise "USER is required" unless options[:user]
user = User.new(options[:user]) if options[:user]
instances = Vote.clamp(options[:instances])

if options[:user] && options[:fetch]
  puts "Fetching:\n"
  user.katas
  user.save
elsif options[:user] && options[:fetch].nil?
  if options[:file_path]
    puts "Voting with data from \"#{options[:file_path]}\"\n"
    user.load_data(options[:file_path])
  else
    puts "Voting with data from API:\n"
    user.katas
    puts "Saving initial user data:\n"
    user.save
  end
  token = Vote.read_token(options[:token])
  Voter.new(user, token:token, instances:instances).vote
  puts "Saving vote results:\n"
  user.save
end
