class User
  attr_reader :name, :authored, :file_name
  attr_writer :info, :katas

  def initialize(username)
    @name = username
  end

  def info
    @info ||= get_info
  end

  def katas
    info unless @info
    @authored ||= authored_katas
    @katas ||= Katas.mark_authored(Katas.fetch(info['api_url'],
      info['total_completed'],
      Katas.calculate_pages(info['total_completed']),
      'completed'), authored
    )
  end

  def save
    save_data = {name:name, info:info, data:{completed:katas, authored:authored}}
    path = File.join('user_data', name)
    @file_name ||= "#{Time.now.strftime('%Y-%m-%d-%H-%M-%S')}.json"
    FileUtils.mkdir_p(path) unless File.exist?(path)
    File.open(File.join(path, @file_name),"w") { |f| f.write(JSON.pretty_generate(save_data)) }
    puts "user data saved to \"#{File.join(path, file_name)}\"".colorize(:green)
  end

  def load_data(path)
    data = JSON.parse(File.read(path))
    raise "no info/kata data in \"#{path}\"" unless data['info'] && data['data']
    @info, @katas, @authored = data['info'], data['data']['completed'], data['data']['authored']
    puts "user data loaded from \"#{path}\" successfully!".colorize(:green)
  end

  private
  def authored_katas
    items = info['total_authored']
    authored_katas ||= Katas.fetch(info['api_url'], items, Katas.calculate_pages(items), 'authored')
  end
  def get_info
    puts "fetching user_info for #{name}:"
    api_url = "https://www.codewars.com/api/v1/users/" + @name
    response = HTTParty.get(api_url).parsed_response
    total_completed = response['codeChallenges']['totalCompleted']
    total_authored = response['codeChallenges']['totalAuthored']
    @info = {'api_url'=>api_url, 'total_completed'=>total_completed, 'total_authored'=>total_authored}
  end
end
