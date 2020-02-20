if ARGV.first.nil?
  puts "Please provide file path...!"
  exit
end

class Thing

end

class Thing2

end

class Thing3

end

$things = {}
$things2 = {}
$things3 = {}


filename = ARGV.first

# stream input file

File.foreach(filename).with_index do |line, line_num|
   puts "Line #{line_num}: #{line}"
end


# output results

file = File.open("#{Time.now.strftime('%I_%M_%S')}_#{filename.split('.').first}_results.txt", 'w')