require 'rubygems'
require 'mechanize'
require 'nokogiri'

PAGE_URL = "https://www.campusexplorer.com/api/publisher/activity_summary/" + 
		   # "?begin_date=today" + "&end_date=today" + 
		   # "?begin_date=yesterday" + "&end_date=yesterday" +
		   "?begin_date=January 1, 2015" + "&end_date=January 31, 2015" +
		   "&grouping=%25Y-%25m-%25d+%25a" + 
		   "&group_by_source_code=1" + 
		   "&format=html"

def fetch_data
	agent = Mechanize.new
	#puts "\nFetching #{PAGE_URL}"
	page = agent.get(PAGE_URL)
	login_form = page.form(:action => "https://www.campusexplorer.com/panel/signin/submit/")
	login_form.emailaddr = "username_here"
	login_form.password = "password_here"
	data_page = agent.submit(login_form)

	data = []
	counter = 0
	data_page.search("table tr").each do |row|
		cols = row.search('td/text()').map(&:to_s)
		row_data = {
			:grouping => cols[0],
			:widget_impressions => cols[1],
			:lead_request_users => cols[2],
			:lead_request_user_per_impressions => cols[3],
			:lead_users => cols[4],
			:leads => cols[5],
			:leads_per_lead_user => cols[6],
			:lead_revenue => cols[7],
			:clickout_impressions => cols[8],
			:clickouts => cols[9],
			:clickthrough_rate => cols[10],
			:clickout_revenue => cols[11],
			:total_revenue => cols[12],
			:source_code => cols[13],
			:tracking_code => cols[14]
		}
		if !row_data[:source_code].nil?
			data << row_data 
		end
	end

	return data
end

def calculate_adjusted_ad_revenue(data)
	adjusted_revenue = 0
	data.each do |entry|
		if entry[:source_code].include?("lp*") && entry[:grouping] != "TOTAL"
			adjusted_revenue += entry[:lead_revenue].to_f * 0.80
			adjusted_revenue += entry[:clickout_revenue].to_f
		end
	end
	adjusted_revenue
end

def calculate_total_ad_revenue(data)
	adjusted_revenue = 0
	data.each do |entry|
		if entry[:source_code].include?("lp*") && entry[:grouping] != "TOTAL"
			adjusted_revenue += entry[:lead_revenue].to_f
			adjusted_revenue += entry[:clickout_revenue].to_f
		end
	end
	adjusted_revenue
end

def calculate_total_revenue(data)
	adjusted_revenue = 0
	data.each do |entry|
		if entry[:grouping] != "TOTAL"
			adjusted_revenue += entry[:lead_revenue].to_f
			adjusted_revenue += entry[:clickout_revenue].to_f
		end
	end
	adjusted_revenue
end

def calculate_adjusted_revenue(data)
	adjusted_revenue = 0
	data.each do |entry|
		if entry[:grouping] != "TOTAL"
			adjusted_revenue += entry[:lead_revenue].to_f * 0.80
			adjusted_revenue += entry[:clickout_revenue].to_f
		end
	end
	adjusted_revenue
end

def calculate_adjusted_organic_revenue(data)
	adjusted_revenue = 0
	data.each do |entry|
		if !entry[:source_code].include?("lp*") && entry[:grouping] != "TOTAL"
			adjusted_revenue += entry[:lead_revenue].to_f * 0.80
			adjusted_revenue += entry[:clickout_revenue].to_f
		end
	end
	adjusted_revenue
end

def calculate_total_organic_revenue(data)
	adjusted_revenue = 0
	data.each do |entry|
		if !entry[:source_code].include?("lp*") && entry[:grouping] != "TOTAL"
			adjusted_revenue += entry[:lead_revenue].to_f
			adjusted_revenue += entry[:clickout_revenue].to_f
		end
	end
	adjusted_revenue
end


start_time = Time.now
puts "Starting Script..."

ad_sound_file_path = "/Users/csalvato/Development/Libraries\ and\ Utilities/Koodlu/ruby-campus-explorer-reader/cha-ching.mp3"
organic_sound_file_path = "/Users/csalvato/Development/Libraries\ and\ Utilities/Koodlu/ruby-campus-explorer-reader/door-bell.mp3"

previous_adjusted_ad_revenue = nil
previous_total_ad_revenue = nil
previous_adjusted_organic_revenue = nil
previous_total_organic_revenue = nil
previous_adjusted_revenue = nil
previous_total_revenue = nil

sleep_time = 5

while true
	data = fetch_data

	adjusted_ad_revenue = calculate_adjusted_ad_revenue(data)
	total_ad_revenue = calculate_total_ad_revenue(data)
	adjusted_organic_revenue = calculate_adjusted_organic_revenue(data)
	total_organic_revenue = calculate_total_organic_revenue(data)
	adjusted_revenue = calculate_adjusted_revenue(data)
	total_revenue = calculate_total_revenue(data)

	system "clear"
	puts PAGE_URL
	puts "\n******\n"
	puts "Adjusted Ad Revenue:\t$" + adjusted_ad_revenue.round(2).to_s
	puts "Total Ad Revenue:\t$" + total_ad_revenue.round(2).to_s
	puts "\n******\n"
	puts "Adjusted Organic Revenue:\t$" + adjusted_organic_revenue.round(2).to_s
	puts "Total Organic Revenue:\t\t$" + total_organic_revenue.round(2).to_s
	puts "\n******\n"
	puts "Adjusted Revenue:\t$" + adjusted_revenue.round(2).to_s
	puts "Total Revenue:\t\t$" + total_revenue.round(2).to_s
	puts "\n******\n"
	print "Refreshing in: " + sleep_time.to_s

	if previous_total_ad_revenue != total_ad_revenue
		pid = fork{ exec 'afplay', ad_sound_file_path }
		previous_total_ad_revenue = 0 if previous_total_ad_revenue.nil?
		say_string = (total_ad_revenue - previous_total_ad_revenue).round(2).to_s + " Advertising Dollars"
		`say "#{say_string}"`
	end

	if previous_total_organic_revenue != total_organic_revenue
		pid = fork{ exec 'afplay', organic_sound_file_path }
		previous_total_organic_revenue = 0 if previous_total_organic_revenue.nil?
		say_string = (total_organic_revenue - previous_total_organic_revenue).round(2).to_s + " Organic Dollars"
		`say "#{say_string}"`
	end

	previous_adjusted_ad_revenue = adjusted_ad_revenue
	previous_total_ad_revenue = total_ad_revenue
	previous_adjusted_organic_revenue = adjusted_organic_revenue
	previous_total_organic_revenue = total_organic_revenue
	previous_adjusted_revenue = adjusted_revenue
	previous_total_revenue = total_revenue

	counter = 0
	while counter < sleep_time
		counter += 1
		sleep(1)
		print "\r"
		print "Refreshing in: " + (sleep_time - counter).to_s
	end
end

puts "Script Complete!"
puts "Time elapsed: #{Time.now - start_time} seconds"