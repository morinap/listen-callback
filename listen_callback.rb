require 'listen'
require 'optparse'
require 'net/http'
require 'json'

options = {
  url: nil,
  dirs: [],
  ignores: []
}

OptionParser.new do |opts|
  opts.banner = 'Usage: listen_callback.rb [options]'

  opts.on('-uURL', '--url=URL', 'The URL to callback to') { |u| options[:url] = u }
  opts.on('-dDIR', '--dir=DIR', 'A directory to monitor') { |d| options[:dirs] << d }
  opts.on('-iIGNORE', '--ignore=IGNORE', 'A pattern to ignore') { |i| options[:ignores] << Regexp.new(i) }
end.parse!

if options[:url].nil? || options[:url].empty?
  puts 'No callback URL specified, exiting'
  exit
end

if options[:dirs].empty?
  puts 'No directories specified, exiting'
  exit
end

uri = URI(options[:url])
options[:ignores] = []
listener = Listen.to(*options[:dirs], ignore: options[:ignores]) do |modified, added, removed|
  puts "Files modified: #{modified.inspect}" unless modified.empty?
  puts "Files added: #{added.inspect}" unless added.empty?
  puts "Files removed: #{removed.inspect}" unless removed.empty?

  Thread.new do
    req = Net::HTTP::Post.new(uri)
    req['Content-Type'] = 'application/json'
    req.body = { modified: modified, added: added, removed: removed }.to_json

    Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: uri.scheme == 'https',
      verify_mode: OpenSSL::SSL::VERIFY_NONE) do |https|
        https.request(req)

      rescue => ex
        puts "Error calling callback: #{ex.message}"
    end
  rescue => ex
    puts "Error calling callback: #{ex.message}"
  end
end

# Loop until interrupt
puts "Listening at #{options[:dirs].inspect}..."
listener.start
sleep
