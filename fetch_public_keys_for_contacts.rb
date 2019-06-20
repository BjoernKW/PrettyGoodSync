#!/usr/bin/env ruby
# encoding: utf-8

require 'rubygems'
require 'net/http'
require 'uri'

if ARGV.length < 2
  puts 'Usage: fetch_public_keys_for_contacts.rb VCARD_INPUT_FILE OUTPUT_DIR'

  exit
end

Dir.mkdir(ARGV[1]) unless File.exists?(ARGV[1])

email_addresses = {}
key_queries = {}

input_file = File.open(ARGV[0])
input = input_file.read
input.each_line do |line|
	if line =~ /:(\S+@\S+)\s+$/
		email_address = $1
		
		puts "Searching keys for #{email_address} ..."

		begin
			uri = URI.parse("https://pgp.surf.nl/pks/lookup?search=#{URI::encode(email_address)}&op=index")
			http = Net::HTTP.new(uri.host, uri.port)
			request = Net::HTTP::Get.new(uri.request_uri)
			response = http.request(request)

			response.body.each_line do |response_line|
			  if response_line =~ /<a href="\/pks\/lookup\?op=get&amp;search=(.+?)">(.+?)<\/a>/
			  	key_query = $1
			    key_id = $2

			    puts "Key found: #{key_query} / ID: #{key_id}"

			    if response_line =~ /KEY REVOKED/
			    	puts "Key has been revoked, hence won't be processed."
			    else
				    key_queries[key_id] = key_query
				    email_addresses[key_id] = email_address
				  end
			  end
			end
		rescue Timeout::Error
		rescue URI::InvalidURIError
		end
	end
end
input_file.close

puts "Now retrieving #{key_queries.length} key(#{key_queries.length > 1 ? 's' : ''}) ..."

all_contacts_output_file = File.open("#{ARGV[1]}/all_contacts.asc", 'w')
key_queries.each do |key_id, key_query|
	begin
	  unless key_query.nil? || key_query == ''
	  	puts "Retrieving key: #{key_query} / ID: #{key_id}, eMail address: #{email_addresses[key_id]}"

		  key_uri = URI.parse("https://pgp.surf.nl/pks/lookup?op=get&search=#{key_query}")
			key_http = Net::HTTP.new(key_uri.host, key_uri.port)
			key_request = Net::HTTP::Get.new(key_uri.request_uri)
			key_response = key_http.request(key_request)

			is_key_block = false
			key_block = ''
			key_response.body.each_line do |response_line|
				if is_key_block
					key_block += "#{response_line}"
				end
				if response_line =~ /<pre>/
					is_key_block = true
				end
				if response_line =~ /-----END PGP PUBLIC KEY BLOCK-----/
					is_key_block = false
				end
			end
			
			single_contact_output_file = File.open("#{ARGV[1]}/#{email_addresses[key_id]}-#{key_id}.asc", 'w') { |file| file.write(key_block) }
			all_contacts_output_file.puts(key_block)
		end
	rescue Timeout::Error
	rescue URI::InvalidURIError
	end
end
all_contacts_output_file.close
