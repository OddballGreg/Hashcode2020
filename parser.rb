if ARGV.first.nil?
  puts "Please provide file path...!"
  exit
end

require 'pry'

class Libary
  attr_reader :id, :weight, :book_count, :time_to_sign_up, :books_scanned_per_day, :books, :max_scannable_books
  
  def initialize(id, book_count, time_to_sign_up, books_scanned_per_day)
    @id = id.to_i
    @book_count = book_count.to_i
    @time_to_sign_up = time_to_sign_up.to_i
    @books_scanned_per_day = books_scanned_per_day.to_i
    @max_scannable_books = ($days - @time_to_sign_up - $current_day) * @books_scanned_per_day
    # @max_scannable_books = ($days - @time_to_sign_up) * @books_scanned_per_day
  end
  
  def add_books(lib_books)
    #optimize book order to scan:
    @books = lib_books.sort{|a, b| $books[b.to_i] <=> $books[a.to_i]}
  end
  
  def weight!
    @books = @books.reject{|b| $books[b.to_i].zero?}.sort{|a, b| $books[b.to_i] <=> $books[a.to_i]}
    used_books = @books[0..@max_scannable_books]
    @weight = (used_books.map{|book_id| $books[book_id.to_i] }.sum) * @books_scanned_per_day
    $highest_available_weighted_lib_id = @id if $highest_available_weighted_lib_id.nil? || @weight > $libraries[$highest_available_weighted_lib_id].weight
    @max_possible_score = used_books.map{|book_id| $books[book_id.to_i] }.sum
  end
  
  def inspect
    "#{id} => #{@max_possible_score}"
  end
  
  def lock_in_books!
    @books[0..@max_scannable_books].each do |book_id|
      $books[book_id.to_i] == 0
    end
  end
end

$book_occurances = Hash.new(0)
$book_allocations = Hash.new(0)
$books = {}
$libraries = {}

book_count = 0
libary_count = 0 
$days = 0
$current_day = 0

filename = ARGV.first

# stream input file


File.foreach(filename).with_index do |line, line_num|
  next if line.length.zero? || line == "\n"
  if line_num.zero?
    segments = line.split(' ')
    book_count = segments[0].to_i
    libary_count = segments[1].to_i
    $days = segments[2].to_i
  elsif line_num == 1
    segments = line.split(' ')
    segments.each.with_index do |score, book_id|
      $books[book_id] = score.to_i
    end
  elsif line_num.even?
    segments = line.split(' ')
    id = (line_num / 2) -1
    $libraries[id] = Libary.new(id, segments[0], segments[1], segments[2])
    $last_lib = $libraries[id]
  elsif line_num.odd?
    $last_lib.add_books(line.split(' '))
  else
    puts 'How did you get here?'
  end
end


# libs_by_weight = {}
# $libraries.each do |id, lib|
#   libs_by_weight[lib.max_scannable_books] ||= []
#   libs_by_weight[lib.max_scannable_books] << lib
#   # used_lib_count += 1
# end


$highest_available_weighted_lib_id = nil
working_libraries = $libraries
libs_by_weight = {}
while working_libraries.any?
  to_remove = []
  working_libraries.each do |_id, lib| 
    lib.weight!
    to_remove << _id unless lib.weight.positive?
  end
  to_remove.each do |id|
    working_libraries.delete(id)
  end
  break unless $highest_available_weighted_lib_id
  lib = $libraries[$highest_available_weighted_lib_id]
  libs_by_weight[lib.weight] ||= [] 
  libs_by_weight[lib.weight] << lib
  lib.lock_in_books!
  $current_day += lib.time_to_sign_up
  working_libraries.delete($highest_available_weighted_lib_id)
  $highest_available_weighted_lib_id = nil
end

# libs_by_weight.sort.each do |_weight, libs|
#   libs.each(&:weight!)
# end


# output results

# libs_by_weight = {}
# $libraries.each do |id, lib|
#   libs_by_weight[lib.weight] ||= []
#   libs_by_weight[lib.weight] << lib
# end

# binding.pry


final_string = ''

$current_day = 0
used_lib_count = 0
libs_by_weight.sort.reverse.each do |_weight, libs|
  libs.each do |library|
    scannable_days = $days - $current_day - library.time_to_sign_up
    next if scannable_days.negative?
    max_books_scanned = [(scannable_days * library.books_scanned_per_day).floor, library.book_count].min
    next unless max_books_scanned.positive?
    
    used_lib_count += 1
    final_string += "#{library.id} #{max_books_scanned}\n"
    final_string += "#{library.books[0..max_books_scanned -1].join(' ')}\n"
    $current_day += library.time_to_sign_up
  end
end

final_string = "#{used_lib_count.to_s}\n" + final_string
File.write("results_#{filename.split('.').first}.txt", final_string)

