#!/usr/bin/env ruby

require_relative 'fetchKit'
require_relative 'kitgen'
require 'minitest/autorun'

class TestCLI < Minitest::Test
  def setup
    @token = 'a946de0ea6cf7147233d783c2c520dab254c15e2'
    @debug = true
    @options = {
      :domains => ['localhost'],
      :name    => 'localhost'
    }
    @families = [
      'droid-sans:n4'
    ]
end
  
  def test_fetch_kit
    #Delete the exsiting kits from https://typekit.com/account/tokens
  	my_kit = FetchKit.new(:token => @token, :debug => @debug)
  	my_data = my_kit.get_kit_data
  	if(my_data['kits'][0]!=nil)
  	  puts my_data['kits'][0]['id']
  	  fetch_kit_id = my_data['kits'][0]['id']
  	  puts fetch_kit_id.class
  	  if fetch_kit_id != nil
  	    my_kit.delete_data(fetch_kit_id)
  	  end
  	end

  	#Create a new kit
  	typekit = Typekit.new(:token => @token, :debug => @debug)
  	kit_id = typekit.create_kit(@options[:name], @options[:domains])
  	typekit.add_kit_families(kit_id, @families)

  	#Fetch information from the new kit just created
  	my_data = my_kit.get_kit_data
  	puts my_data['kits'][0]['id']
  	fetch_kit_id = my_data['kits'][0]['id']
    assert_equal kit_id, fetch_kit_id
  end

end