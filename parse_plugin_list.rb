# Requiring JSON parsing tools
require 'json'
# httparty is a separate gem - use `gem install httparty` to install
require 'httparty'
# Readline provides autocomplete functionality for file paths
require 'readline'

# Take the input for the filename to parse
puts 'Enter the file name: '
file_path = Readline.readline("> ", true).rstrip

# Validation the file exists
if File.file?(file_path) == false
  puts "The file #{file_path} doesn't exist or is not a file. Please try again."
  exit
end

# This is our JSON file we're parsing
# Generate this from CLI using this CLI command:
# java -jar jenkins-cli.jar -s http://controller-url -webSocket -auth user:PassOrToken list-plugins-v2 > plugins.json
file = File.read(file_path)

# Parse the file from JSON into a hash
installed_plugin_list = JSON.parse(file)

# Plugin List hash
pl = {
  'proprietary': {'count': 0, 'list': [], 'desc': 'Proprietary/Verified (Tier 1) Plugins'},
  'compatible': {'count': 0, 'list': [], 'desc': 'Compatible (Tier 2) Plugins'},
  'community': {'count': 0, 'list': [], 'desc': 'Community (Tier 3) Plugins'},
  'unsupported': {'count': 0, 'list': [], 'desc': 'Unsupported Plugins'},
  'overall': {'count': 0}
}

# Loop our list of plugins hash
installed_plugin_list['data'].each do |key, _value|
  # Increment overall count number
  pl[:overall][:count] += 1
  # Var builds our URL
  url = "https://docs.cloudbees.com/api/search?provider=ci-plugins&filters%5Btext%5D=#{key['id']}&filters%5Bcategory%5D="
  # HTTParty simplifies retrieving JSON results from a URL
  begin
    response = HTTParty.get(url)
  rescue => error
    puts error
    puts "Failed to get URL Please try again."
    exit
  end
  # If it's not in the CI plugins list, it is missing
  if response['count'] == 0
    # Pushes plugin to the unsupported list
    (pl[:unsupported][:list] ||= []) << key['id']
    # Increment unsupported count
    pl[:unsupported][:count] += 1
  else
    # checking to validate the slug matches the plugin id for accuracy
    # create result hash [empty]
    result = {}

    # check each result to ensure it matches our slug
    response['results'].each do |k,v|
      if k['metadata']['artifactId'] == key['id'] 
        # Slug matches a result
        # assign correct entry to result var
        result = k['metadata']
      end
    end

    if result.empty?
      # Slug doesn't match any results
      # Pushes plugin to the unsupported list
      (pl[:unsupported][:list] ||= []) << key['id']
      # Increment unsupported count
      pl[:unsupported][:count] += 1
      # skip to next iteration of each()
      next
    end
    # verified is Tier 1, so we force it to "proprietary" for the type
    result['tier'] == 'verified' ? type = :proprietary : type = result['tier'].to_sym
    # Pushes the plugin to the list for the type
    (pl[type][:list] ||= []) << key['id']
    # Increments the count of the plugin type
    pl[type][:count] += 1
  end
end

# Header for the output
puts "Plugins List - #{pl[:overall][:count]} Total"

# Loop each grouping and write to output
pl.each do |k, _v|
  # Skip if it's the overall entry
  next if k == :overall
  puts "\n#{pl[k][:desc]} [#{pl[k][:count]}]:"
  puts "====================\n\n"
  puts pl[k][:list]
end
