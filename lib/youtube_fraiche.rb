require 'open-uri'
require 'nokogiri'

class YoutubeFraiche

  USER_AGENT = "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_5; en-US) AppleWebKit/534.7 (KHTML, like Gecko) Chrome/7.0.517.44 Safari/534.7"

  attr_accessor :data_path, :username, :password

  def initialize(base_path = Dir.pwd)
    self.data_path = base_path
  end

  def download(url)
    videos = []
    doc = Nokogiri::HTML::Document.parse(open(url))
    skrips = doc.search('//script').to_s
    #parse stream urls
    if skrips.match(/"fmt_url_map": "(.*\d)"/)
      fmt_map = $1.split(',').first.split(',')
      fmt_map.each do |fmt|
        number, stream_url = fmt.split('|')
        videos << { :number => number.to_i, :stream_url => stream_url.gsub('\\','')}
      end
      #sort by quality
      videos = videos.sort_by { |x| x[:number] }
      
      #get the highest quality
      puts "downloading " << videos.last[:stream_url]
      url = URI.parse(videos.last[:stream_url])
      http = Net::HTTP.new(url.host, 80)
      http.use_ssl = false
      http.start do |http|
        req = Net::HTTP::Get.new("#{url.path}?#{url.query}", {"User-Agent" => USER_AGENT})
        response = http.request(req)
        File.open('download.flv', 'wb') { |x| x.print response.body }
      end      
    end
  end

end
