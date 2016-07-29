require "csv"
require "sunlight/congress"
require "erb"

Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

# Clean and validate phone numbers
def valid_phone(phone)
  phone.gsub!(/\D/, "")
  if phone.length == 10
    puts phone
  elsif phone.length == 11 && phone[0] == "1"
    puts phone[1..10]
  else
    puts "INVALID PHONE NUMBER"
  end
end

# Returns the hour from the registration date
def reg_hours(reg_date)
  date = DateTime.strptime(reg_date, "%m/%d/%y %H:%M")
  date.hour
end

# Takes the registration hours hash and lists the hour starting with the most popular 
def peak_hours(hours)
  puts "\nPeak Registration Hours"
  puts "-------------------------------"
  hours.each do |k,v|
    puts "Hour: #{k},\tFrequency: #{v}"
  end
end

# Returns the day of the week from the registration date
def reg_day_of_week(reg_date)
  date = DateTime.strptime(reg_date, "%m/%d/%y %H:%M")
  # This line produces the full weekday name instead of just the day of week number.
  date.strftime("%A")
end

# Takes the registration days hash and lists the day and count starting with the most popular 
def peak_reg_days(days)
  puts "\nPeak Registration Days"
  puts "--------------------------------"
  days.each do |k,v|
    puts "Day: #{k},\tFrequency: #{v}"
  end
end

def legislators_by_zipcode(zipcode)
  legislators = Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def save_form_letter(id, form_letter)
  Dir.mkdir("output") unless Dir.exists? "output"

  filename = "output/thanks_#{id}.html"

  File.open(filename, "w") do |file|
    file.puts form_letter
  end
end

puts "EventManager Initialized!"

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

hours_hash = Hash.new(0)
day_of_week_hash = Hash.new(0)

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])
  valid_phone(row[:homephone])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_form_letter(id, form_letter)

  h = reg_hours(row[:regdate])
  hours_hash[h] += 1

  d = reg_day_of_week(row[:regdate])
  day_of_week_hash[d] += 1

end

hours_sorted = hours_hash.sort_by { |k,v| v }.reverse.to_h
peak_hours(hours_sorted)

day_of_week_sorted = day_of_week_hash.sort_by { |k,v| v }.reverse.to_h
peak_reg_days(day_of_week_sorted)
