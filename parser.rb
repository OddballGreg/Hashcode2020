if ARGV.first.nil?
  puts "Please provide file path...!"
  exit
end

filename = ARGV.first

File.foreach(filename).with_index do |line, line_num|
   puts "Line #{line_num}: #{line}"
end
