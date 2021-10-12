# Hacktoberfest: Analyzing CloudBees CI Plugins List for Support Level
For Hacktoberfest, I decided my project this year was going to be useful to those who are administrators of a CloudBees CI environment and are always being pestered about Plugins and their Support level (Tier 1, 2, 3 or completely off the radar) to encourage those administrators of Controllers to manage their Plugins more effectively.

With the advent of the Plugin Usage Analyzer Plugin from CloudBees, this job is made much easier, but it’s still all processed through a UI and as an administrator in a past life I realize the value and speed and efficiency gained by using command line tools.

With that, I present my project in two parts – first, a script written in Ruby that parses a Plugins list from a Controller generated via the Jenkins CLI and returns a few lists containing which Plugins fit into which category. Second, a script written in Ruby that parses the `analysis.json` file output by the CloudBees Plugin Usage Analyzer and returns not only a few lists with which Plugins fit into which Support level, but also how many Pipelines have referenced the plugin and how long ago it was last referenced.

## Before We Begin
You can find this code on my site at https://simplytim.io.

## Running the Scripts
To run these scripts, you’ll need the following:

* Ruby (the latest version will do)
* The HTTParty gem (`gem install httparty`)
* An output of the Plugins List from a Controller for the first script – `java -jar jenkins-cli.jar -s http://controller-url -webSocket -auth user:PassOrToken list-plugins-v2 > plugins.json`
* An output of the Plugin Usage Analyzer from the UI (`analysis.json` by default)