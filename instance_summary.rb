#!/usr/bin/ruby

result = nil
IO.popen('docker container ls --format "table {{.ID}}\t{{.Names}}" -a 2>&1') do |io|
  result = io.read
end


unless result.nil?
  summary = {}
  result.each_line do |container|
    id, name_size = container.split
    name = name_size.split("-")[0]

    next if name == "ID"


    path_to_config = "/var/www/#{name}/config/config.rb"

    backend_port = nil
    IO.popen("grep 'AppConfig\\[:backend_url\\]' #{path_to_config} 2>&1  | grep -v '#'") do |io|
      backend_port = io.read.gsub('"', "").strip!
    end

    if backend_port =~ /grep/
      instance_number = nil
    else
      backend_port = backend_port.split("localhost:")[1]
      instance_number = backend_port.gsub('089','')
    end

    summary[name] = instance_number
  end

  puts "INSTANCE SUMMARY"
  puts "\n"
  puts "Total instances: #{summary.count}"
  puts "\n"
  puts "Instance Number\t\tInstance Name"
  puts "==============================================="
 
  summary.each do |key, value|
    if value.nil?
      puts "Unknown\t\t\t#{key}"
    else
      puts "#{value}\t\t\t#{key}"
    end
  end

  used = summary.values.map {|num| num.to_i}
  possible = (1..65).to_a

  puts "\n"
  puts "Available instance numbers: "
  puts (possible - used).inspect
  puts "\n"
  puts "\n"
end

