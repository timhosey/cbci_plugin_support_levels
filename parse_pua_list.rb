# Requiring JSON parsing tools
require 'json'
# httparty is a separate gem - use `gem install httparty` to install
require 'httparty'
# Readline provides autocomplete functionality for file paths
require 'readline'

# Function for parsing number of occurrences
def count_occ(usages_list)
  count = 0
  usages_list.each do |k,v|
    if k['location']['type'] == 'pipeline'
      count += 1
    end
  end
  return count
end

def days_since(usages_list)
  # Returns the last usage of the plugin in a pipeline
  date_stamp = 0
  usages_list.each do |k,v|
    if k['location']['type'] == 'pipeline' && k['instant']['epochSecond'] > date_stamp
      date_stamp = k['instant']['epochSecond'] 
    end
  end
  now = Time.now.to_i
  date_stamp = now if date_stamp == 0 || date_stamp == nil
  since = (now - date_stamp.to_i) / (24 * 60 * 60)
  output = since > 0 ? "- #{since} days ago" : ""
  return output
end

puts 'Enter the file name: '
file_path = Readline.readline("> ", true).rstrip

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
installed_plugin_list['usages'].each do |key, value|
  # Increment overall count number
  pl[:overall][:count] += 1
  # Var builds our URL
  url = "https://docs.cloudbees.com/api/search?provider=ci-plugins&filters%5Btext%5D=#{key}&filters%5Bcategory%5D="
  # HTTParty simplifies retrieving JSON results from a URL
  begin
    response = HTTParty.get(url)
  rescue => error
    puts error
    puts "Failed to get URL Please try again."
    exit
  end
  # If it's not in update center, it is missing

  # TODO: Find the last ['instant']['epochSecond'] entry (most recent) and then find how many days since

  if response['count'] == 0
    # Pushes plugin to the unsupported list
    (pl[:unsupported][:list] ||= []) << "#{key} [#{count_occ(value)}] #{days_since(value)}"
    # Increment unsupported count
    pl[:unsupported][:count] += 1
  else
    # checking to validate the slug matches the plugin id for accuracy
    # create result hash [empty]
    result = {}

    # check each result to ensure it matches our slug
    response['results'].each do |k,v|
      if k['metadata']['artifactId'] == key
        # Slug matches a result
        # assign correct entry to result var
        result = k['metadata']
      end
    end

    if result.empty?
      # Slug doesn't match any results
      # Pushes plugin to the unsupported list
      (pl[:unsupported][:list] ||= []) << "#{key} [#{count_occ(value)}] #{days_since(value)}"
      # Increment unsupported count
      pl[:unsupported][:count] += 1
      # skip to next iteration of each()
      next
    end
    # verified is Tier 1, so we force it to "proprietary" for the type
    result['tier'] == 'verified' ? type = :proprietary : type = result['tier'].to_sym
    # Pushes the plugin to the list for the type
    (pl[type][:list] ||= []) << "#{key} [#{count_occ(value)}] #{days_since(value)}"
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
