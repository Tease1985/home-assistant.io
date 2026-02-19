require "rubygems"
require "bundler/setup"
require "stringex"
require 'net/http'
require 'json'

# Fetch JSON from a URL with timeout and error handling.
def fetch_json(url)
  uri = URI(url)
  response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https',
                                                 open_timeout: 10, read_timeout: 30) do |http|
    http.get(uri.request_uri)
  end
  raise "HTTP #{response.code} #{response.message} fetching #{url}" unless response.is_a?(Net::HTTPSuccess)

  JSON.parse(response.body)
rescue SocketError, Errno::ECONNREFUSED, Timeout::Error => e
  raise "Network error fetching #{url}: #{e.message}"
rescue JSON::ParserError => e
  raise "Failed to parse JSON from #{url}: #{e.message}"
end

## -- Misc Configs -- ##
public_dir      = "public/"   # compiled site directory
source_dir      = "source"    # source file directory
server_port     = "4000"      # port for preview server eg. localhost:4000

unless (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM).nil?
  puts '## Set the codepage to 65001 for Windows machines'
  `chcp 65001`
end

#######################
# Working with Jekyll #
#######################

desc "Generate jekyll site"
task :generate do
  raise "### You haven't set anything up yet. First run `rake install`." unless File.directory?(source_dir)

  puts "## Generating Site with Jekyll"
  success = system "compass compile --css-dir #{source_dir}/stylesheets"
  abort("Generating CSS failed") unless success
  success = system "rake analytics_data"
  abort("Generating analytics data failed") unless success
  success = system "rake alerts_data"
  abort("Generating alerts data failed") unless success
  success = system "rake version_data"
  abort("Generating version data failed") unless success
  success = system "rake blueprint_exchange_data"
  abort("Generating blueprint exchange data failed") unless success
  success = system "jekyll build"
  abort("Generating site failed") unless success
  if ENV["CONTEXT"] != 'production'
    File.open("#{public_dir}robots.txt", 'w') do |f|
      f.write "User-agent: *\n"
      f.write "Disallow: /\n"
    end
  end
  public_dir
end

desc "Watch the site and regenerate when it changes"
task :watch do
  raise "### You haven't set anything up yet. First run `rake install`." unless File.directory?(source_dir)

  puts "Starting to watch source with Jekyll and Compass."
  system "compass compile --css-dir #{source_dir}/stylesheets" unless File.exist?("#{source_dir}/stylesheets/screen.css")
  jekyll_pid = Process.spawn({ "OCTOPRESS_ENV" => "preview" }, "jekyll build --watch --incremental")
  compass_pid = Process.spawn("compass watch")

  trap("INT") do
    [jekyll_pid, compass_pid].each do |pid|
      Process.kill(9, pid)
    rescue StandardError
      Errno::ESRCH
    end
    exit 0
  end

  [jekyll_pid, compass_pid].each { |pid| Process.wait(pid) }
end

desc "preview the site in a web browser"
task :preview, :listen do |_t, args|
  listen_addr = args[:listen] || '127.0.0.1'
  listen_addr = '0.0.0.0' unless ENV['DEVCONTAINER'].nil?
  raise "### You haven't set anything up yet. First run `rake install`." unless File.directory?(source_dir)

  puts "Starting to watch source with Jekyll and Compass."
  puts "Now listening on http://localhost:#{server_port}"
  system "compass compile --css-dir #{source_dir}/stylesheets" unless File.exist?("#{source_dir}/stylesheets/screen.css")
  system "rake analytics_data"
  system "rake version_data"
  system "rake alerts_data"
  system "rake blueprint_exchange_data"
  jekyll_pid = Process.spawn({ "OCTOPRESS_ENV" => "preview" }, "jekyll build -t --watch --incremental")
  compass_pid = Process.spawn("compass watch")
  rackup_pid = Process.spawn("rackup --port #{server_port} --host #{listen_addr}")

  trap("INT") do
    [jekyll_pid, compass_pid, rackup_pid].each do |pid|
      Process.kill(9, pid)
    rescue StandardError
      Errno::ESRCH
    end
    exit 0
  end

  [jekyll_pid, compass_pid, rackup_pid].each { |pid| Process.wait(pid) }
end

desc "Download data from analytics.home-assistant.io"
task :analytics_data do
  remote_data = fetch_json('https://analytics.home-assistant.io/data.json')
  File.write("#{source_dir}/_data/analytics_data.json", JSON.generate(remote_data['current']))
  puts "## analytics_data: OK"
end

desc "Download data from alerts.home-assistant.io"
task :alerts_data do
  remote_data = fetch_json('https://alerts.home-assistant.io/alerts.json')
  File.write("#{source_dir}/_data/alerts_data.json", JSON.generate(remote_data))
  puts "## alerts_data: OK"
end

desc "Download version data from version.home-assistant.io"
task :version_data do
  remote_data = fetch_json('https://version.home-assistant.io/stable.json')
  File.write("#{source_dir}/_data/version_data.json", JSON.generate(remote_data))
  puts "## version_data: OK"
end

desc "Download data from the blueprint exchange @ community.home-assistant.io"
task :blueprint_exchange_data do
  remote_data = fetch_json('https://community.home-assistant.io/c/blueprints-exchange/53/l/top.json?period=all')
  File.write("#{source_dir}/_data/blueprint_exchange_data.json", JSON.generate(remote_data['topic_list']['topics']))
  puts "## blueprint_exchange_data: OK"
end
