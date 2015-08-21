#!/usr/bin/env ruby
#
# A command line Typekit API client that creates new kits
#
# Copyright 2010 Small Batch Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#This file is from: https://github.com/typekit/typekit-api-examples/blob/master/kitgen/kitgen

require 'rubygems'
require 'optparse'
require 'curb'
require 'json'

# A limited Typekit API client library, based on curb
class Typekit

  # Initialize a new Typekit object.
  #
  # options - A Hash of options:
  #           :token - A String user token to use for authenticated requests.
  #           :debug - Boolean, if true output debugging information
  #
  # Returns a new Typekit instance.
  def initialize(options)
    @token = options[:token]
    @debug = options[:debug]
  end

  # Creates a kit using the Typekit API.
  #
  # name    - A String containing a human readable name for this kit.
  # domains - An Array of hostnames this kit will be used on.
  #
  # Examples
  #
  #  create_kit('My Kit', ['example.com','example.org'])
  #  # => 'nld3fax'
  #
  # Returns the id of the created kit as a String.
  # Raises RuntimeError if the Typekit API returns an error.
  def create_kit(name, domains)
    data = request('POST', '/kits', {
      :name => name,
      :domains => domains.join(',')
    })
    return data['kit']['id']
  end

  # Adds a font family to a kit using the Typekit API.
  # Note: this does not allow you to override the default character subset.
  #
  # kit_id   - The String kit_id.
  # families - An Array of families. Each family should be a String formatted
  #            as "family_id:fvd,fvd".
  #
  # Examples
  #
  #  add_kit_families('nld3fax', ['gkmg:n4,i7','pcpv:n4'])
  #
  # Returns nothing.
  # Raises RuntimeError if the Typekit API returns an error.
  def add_kit_families(kit_id, families)
    families.each do |family|
      family_id, variations = family.split(':')
      request('POST', "/kits/#{kit_id}/families/#{family_id}", {
        'variations' => variations
      })
    end
  end

  # Converts a font family slug into a font family ID using the Typekit API.
  #
  # family_slug - The String family slug.
  #
  # Examples
  #
  #  get_family_id('droid-sans')
  #  # => 'gkmg'
  #
  # Returns the font family ID as a String.
  # Raises RuntimeError if the Typekit API returns an error.
  def get_family_id(family_slug)
    data = request('GET', "/families/#{family_slug}")
    return data['family']['id']
  end

  # Makes a request to the Typekit API.
  #
  # verb     - the String HTTP method to use (GET, POST, DELETE).
  # endpoint - the String API endpoint to request.
  # postdata - a Hash containg POST parameters (default: {}).
  #
  # Examples
  #
  #  request('GET','/kits')
  #  # => { :kit => { :id => 'nld3fax', ... }}
  #
  #  request('POST','/kits', {'domains' => 'example.com', 'name' => example })
  #  # => { :kit => { :id => 'tak8abv', ... }}
  #
  # Returns the data from the API as a nested Hash.
  # Raises RuntimeError if the Typekit API returns an error.
  def request(verb, endpoint, postdata = {})

    curl = Curl::Easy.new("https://typekit.com/api/v1/json#{endpoint}")
    debug("making #{verb} request to #{curl.url}")
    curl.headers["X-Typekit-Token"] = @token

    if verb == "POST"
      curl.post_body = postdata.map{|f,k| "#{curl.escape(f)}=#{curl.escape(k)}"}.join('&')
      debug("  post data is #{curl.post_body}")
    end

    curl.http(verb)
    debug("  response is #{curl.response_code} #{curl.body_str}")

    data = JSON.parse(curl.body_str) or raise "Could not parse response #{curl.body_str}"

    unless [200, 302].include? curl.response_code
      raise data['errors'].first
    end

    data
  end

  # Outputs debugging information if previously requested
  def debug(message)
    warn "debug: #{message}" if @debug
  end

end

# A command line app to generate Typekit kits
class App

  VERSION = '0.1.0'

  # Outputs debugging information if previously requested
  def debug(message)
    warn "debug: #{message}" if @debug
  end

  # Creates a kit based on passed in command line arguments. Outputs
  # descriptive logging messages to STDERR if requested.
  #
  # argv - An Array of command line arguments.
  #
  # Returns nothing.
  # Raises ArgumentError if no token or font variations are supplied.
  def run(argv)

    prog = File.basename($0)
    #
    # parse the options
    #
    options = {
      :domains => [],
      :name    => '',
      :token   => ''
    }
    argv.options do |opts|
      opts.banner = "Usage: #{prog} --token=token [options] family [...]"

      opts.separator ""
      opts.separator "Required options:"

      opts.on('-t', '--token=token', 'Authentication token to use')          { |token| options[:token] = token }
      opts.on('-n', '--name=name',   'Name for generated kit')               { |token| options[:name] = token }
      opts.on('-d', '--domain=domain', 'Domain(s) this kit will be used on') { |domain| options[:domains] << domain }

      opts.on_tail('--debug', 'Enable extra debugging information') { @debug = true }
      opts.on_tail('-h', '--help', 'Show this message')             { puts opts; exit 0; }
      opts.on_tail('-v', '--version', 'Show version')               { puts "#{prog} #{VERSION}"; exit 0}
      opts.parse!
    end or exit 1

    #
    # Check we have all the data we need
    #
    options[:domains] = ['localhost'] if options[:domains].empty?
    options[:name] = options[:domains].first if options[:name].empty?
    abort "#{prog}: missing argument: --token" if options[:token].empty?
    abort "#{prog}: missing family" if argv.empty?
    families = argv

    debug("parsed options")
    debug("  token is #{options[:token]}")
    debug("  name is #{options[:name]}")
    debug("  domains are #{options[:domains].join(' ')}")
    debug("  families are #{families.join(' ')}")

    #
    # create a new Typekit API client
    #
    typekit = Typekit.new(:token => options[:token], :debug => @debug)

    #
    # Iterate over the families, and make sure we have a family id for each
    #
    families.map! do |family|
      family_slug, variations = family.split(':')
      family_id = typekit.get_family_id(family_slug)
      raise "Family #{family_slug} not found" unless family_id
      "#{family_id}:#{variations}"
    end
    debug("processed families are #{families.join(' ')}")

    #
    # create a kit using the name and domains provided
    #
    kit_id = typekit.create_kit(options[:name], options[:domains])

    #
    # add the font families to that kit
    #
    typekit.add_kit_families(kit_id, families)

    #
    # done!
    #
    puts "Kit created; id is #{kit_id}"
    kit_id
  end
 
end
if __FILE__ == $0
App.new.run(ARGV)
exit 0
end