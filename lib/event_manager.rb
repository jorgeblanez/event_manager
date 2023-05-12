require "csv"
require 'google/apis/civicinfo_v2'
require "erb"
require "time"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def get_legislator_name(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def output_form_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_homephone(homephone)
  homephone.gsub!(/[^0-9]/, '')

  if homephone.length > 11
    homephone = "Bad Number"
  elsif homephone.length == 11 && homephone[0] != "1"
    homephone = "Bad Number"
  elsif homephone.length == 11
    homephone[1..-1]
  elsif homephone.length < 10
    homephone = "Bad Number"
  else
    homephone
  end

end

def registration_hour_counter(time,register_hour)
  hour = Time.strptime(time,"%D %k:%M").strftime("%k").strip
  register_hour[hour] += 1  
end

def save_hour(register_hour)
  CSV.open("hour_registration.csv","wb") do |csv| 
    csv << ["Hour","Counter"]
    register_hour.to_a.each {|elem| csv << elem}
  end
end

def registration_weekday(day,register_day)
  day = Date.strptime(day,"%D").strftime("%A").strip
  register_day[day] += 1  
end

def save_day (register_day)
  CSV.open("weekday_registration.csv","wb") do |csv| 
    csv << ["Weekday","Counter"]
    register_day.to_a.each {|elem| csv << elem}
  end
end


register_hour = Hash.new(0)
register_day = Hash.new(0)

content = CSV.open(
  "event_attendees.csv", 
  headers: true,
  header_converters: :symbol  
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

content.each do |line|

  #zipcode = clean_zipcode(line[:zipcode])
  #name = line[:first_name].split(/ |\_/).map(&:capitalize).join(" ")
  #legislators = get_legislator_name(zipcode)
  #output_form_letter(line[0],erb_template.result(binding))
  #phone = clean_homephone(line[:homephone])
  registration_hour_counter(line[:regdate],register_hour)
  registration_weekday(line[:regdate],register_day)
end

save_hour(register_hour)
save_day(register_day)