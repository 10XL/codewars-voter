module Katas
  def self.fetch(api_url, items, pages, type)
    puts "total_items: #{items}, total_pages: #{pages}".colorize(:green)+ "\nfetching #{type} katas:\n"
    katas = {}
    threads = []
    (0...pages).each do |i|
      threads << Thread.new do
        url = api_url + "/code-challenges/#{type}?page=#{i}"
        HTTParty.get(url).parsed_response['data'].each do |kata|
          katas[kata['id'].to_sym] = {'name'=>kata['name'], 'rank'=>nil}
        end
        puts "request completed: #{url}\n#{katas.size}/#{items} received\n".colorize(:green)
      end
    end
    threads.each { |t| t.join }
    katas
  end

  def self.calculate_pages(len, page_length=200)
    (len + page_length - 1) / 200
  end

  def self.mark_authored(katas, authored)
    authored.each { |id, data| katas[id]['owner'] = true }
    katas
  end

  def self.page(katas, pages)
    paged = katas.each_slice(katas.size/pages).to_a
    paged[-2].concat(paged.pop) if paged[pages] && pages > 1
    paged.map!(&:to_h)
  end

  def self.filter(katas)
    katas.select { |id, data| data['name'] && data['owner'].nil? && data['rank'].nil? }
  end

  def self.merge(paged_katas)
    paged_katas.reduce({}, :merge) if paged_katas.size > 1
  end

end
