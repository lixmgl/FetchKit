#!/usr/bin/env ruby
#
# A command line interface in Ruby to fetch information about kits using the public Typekit APIs:
# https://typekit.com/docs/api/v1/:format/kits

require 'rubygems'
require 'curb'
require 'json'
require 'optparse'

# An interface can fetch data from TypeKit API, based on curb
class FetchKit
  
  # Initialize a new FetchKit object.
  #
  # options - A Hash of options:
  #           :token - A String user token to use for authenticated requests, generated here: https://typekit.com/account/tokens
  #           :debug - Boolean, if true output debugging information
  #
  # Returns a new FetchKit instance.
	def initialize(options)
	  @token = options[:token]
		@debug = options[:debug]
	end

  #Fetch Kit data from https://typekit.com/api/v1/json/kits.
  #
  # Returns the data from the API as a nested Hash.
  # Raises RuntimeError if the Typekit API returns an error.
	def get_kit_data
	  data = request('GET',"/kits")
    data
	end

  #Print the kit, show total number of kits and id and link for each kit.
  def print_data(my_kit)
    puts JSON.pretty_generate(my_kit)
    kit_vals=my_kit['kits']
    puts "You have #{kit_vals.size} kits in total."
    kit_vals.each_with_index do |kit_val,index|
      puts "Number #{index+1} kit information:"
      kit_val.each_pair do |key, value|
        puts "#{key}:#{value}"      
      end
    end
  end

  #Print all data inside each kit.
  def print_all(my_kit)
    puts "Fetch all data in each kit"
    puts JSON.pretty_generate(my_kit)

    kit_vals=my_kit['kits']
    puts "You have #{kit_vals.size} kits in total"

    kit_vals.each_with_index do |kit_val,index|
      puts "Number #{index+1} kit information:"

      kit_val.each_pair do |key, value|
        puts "#{key}:#{value}"        
      end
      id, id_number = kit_vals[index].first
      details = get_more_data(id_number)
      print_more_data(details)
    end
  end


  #Fetch Kit data from hhttps://typekit.com/api/v1/json/kits/#{id_number}.
  #
  # Returns the data from the API as a nested Hash.
  # Raises RuntimeError if the Typekit API returns an error.
  def get_more_data(id_number)
    data = request('GET',"/kits/#{id_number}")
    data
  end

  #Delete Kit 
  def delete_data(id_number)
    request('DELETE',"/kits/#{id_number}")
  end


  #Print detail data for this kit.
  def print_more_data(data)
    puts JSON.pretty_generate(data)
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
  # Returns the data from the API as a nested Hash.
  # Raises RuntimeError if the TypeKit API returns an error.
	def request(verb, endpoint, postdata = {})

    curl = Curl::Easy.new("https://typekit.com/api/v1/json#{endpoint}")
    debug("making #{verb} request to #{curl.url}")
    curl.headers["X-Typekit-Token"] = @token

    curl.http(verb)
    debug("  response is #{curl.response_code} #{curl.body_str}")

    data = JSON.parse(curl.body_str) or raise "Could not parse response #{curl.body_str}"

    unless [200, 302].include? curl.response_code
      raise data['errors'].first
    end

    data
  end

  def debug(message)
    warn "debug: #{message}" if @debug
  end

end


#A command line interface to fetch kit information from API.
class CLI

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

    argv.options do |opts|
      opts.banner = "Usage: #{prog} --token=token [options]"
      opts.on('-t', '--token=token', 'Authentication token to use') {|my_token| @token = my_token}
      opts.on_tail('--debug', 'Enable extra debugging information') { @debug = true }
      opts.on_tail('-h', '--help', 'Show this message')             { puts opts; exit 0; }    
      opts.parse!
    end or exit 1
        
    #
    # Check token data we need 
    #
    abort "#{prog}: missing argument: --token" if @token.empty?
    debug("parsed options")
    debug("  token is #{@token}")

    #
    # create a new FetchKit interface client
    #
    my_kit = FetchKit.new(:token => @token, :debug => @debug)
    #
    # Fetch information from your Kit
    #
    my_data = my_kit.get_kit_data
    my_kit.print_data(my_data)
    #
    # Array contains ids and links for all kits.
    #
    kits_val=my_data['kits']
        
    #Provide different options for users to fetch kit information.
    kits_val.each_with_index do |kit_val,index|
      while true do
        puts "Please input:\n the number of the kit you want to see \n or 'q' for quit:\n or 'p' for print all kits"
        num = gets.chomp
        exit 0 if num == 'q'
        if num == 'p'
          my_kit.print_all(my_data)
        elsif num.to_i > kits_val.size || num.to_i <= 0
          puts "Wrong number, please select another kit:" 
        else
          id, id_number = kits_val[num.to_i-1].first
          my_id = id_number
          puts "Fetch more information for Number #{index+1} kit:"
          my_details = my_kit.get_more_data(id_number)
          my_kit.print_more_data(my_details)
        end
      end
    end   
    
  end
 

end

if __FILE__ == $0
 CLI.new.run(ARGV)
 exit 0
end