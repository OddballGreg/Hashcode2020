if ARGV.first.nil?
  puts "Please provide file path...!"
  exit
end

class Library
  @id : Int64
  @weight : Int64 | Nil
  @max_possible_score : Int64 | Nil
  @book_count : Int64
  @time_to_sign_up : Int64
  @books_scanned_per_day : Int64
  @max_scannable_books : Int64 | Nil
  @books : Array(Int64) | Nil

  getter :id, :weight, :book_count, :time_to_sign_up, :books_scanned_per_day, :books, :max_scannable_books

  def initialize(@id, @book_count, @time_to_sign_up, @books_scanned_per_day)
    # @id = id.to_i64
    # @book_count = book_count.to_i64
    # @time_to_sign_up = time_to_sign_up.to_i64
    # @books_scanned_per_day = books_scanned_per_day.to_i64
    # @max_scannable_books = (days - @time_to_sign_up - current_day) * @books_scanned_per_day
  end

  def add_books(lib_books, all_books)
    # optimize book order to scan:
    @books = lib_books.sort { |a, b| all_books[b.to_i64] <=> all_books[a.to_i64] }
  end

  def weight!(highest_available_weighted_lib_id, days, libraries, current_day, all_books)
    @max_scannable_books = (days.to_i64 - @time_to_sign_up.to_i64 - current_day.to_i64) * @books_scanned_per_day.to_i64
    books = @books
    if books.is_a?(Array(Int64))
      books = books.reject { |b| all_books[b.to_i64].zero? }.sort { |a, b| all_books[b.to_i64] <=> all_books[a.to_i64] }
      @books = books
      used_books = books[0..@max_scannable_books]
      weight = (used_books.map { |book_id| all_books[book_id.to_i64] }.sum) * @books_scanned_per_day
      @weight = weight
      @max_possible_score = used_books.map { |book_id| all_books[book_id.to_i64] }.sum
      id
    end
  end

  def inspect
    "#{id} => #{@max_possible_score}"
  end

  def lock_in_books!(all_books)
    used_books = @books
    if used_books.is_a?(Array(Int64))
      used_books = used_books[0..@max_scannable_books]
      used_books.each do |book_id|
        all_books[book_id.to_i64] == 0
      end
    else
      raise "Shouldn't happen"
    end
  end
end

all_books = {} of Int64 => Int64
libraries = {} of Int64 => Library

book_count = 0
libary_count = 0
days = 0
current_day = 0

filename = ARGV.first

# stream input file

last_lib = nil
line_num = -1
File.each_line(filename) do |line|
  line_num += 1
  next if line.size.zero? || line == "\n"
  if line_num.zero?
    segments = line.split(' ')
    book_count = segments[0].to_i64
    libary_count = segments[1].to_i64
    days = segments[2].to_i64
  elsif line_num == 1
    segments = line.split(' ')
    segments.each.with_index do |score, book_id|
      all_books[book_id.to_i64] = score.to_i64
    end
  elsif line_num.even?
    segments = line.split(' ')
    id = ((line_num / 2) - 1).to_i64
    libraries[id] = Library.new(id, segments[0].to_i64, segments[1].to_i64, segments[2].to_i64)
    last_lib = libraries[id]
  elsif line_num.odd?
    if last_lib.is_a?(Library)
      last_lib.add_books(line.split(' ').map(&.to_i64), all_books)
    else
      raise "No Last Lib"
    end
  else
    puts "How did you get here?"
  end
end

# libs_by_weight = {}
# libraries.each do |id, lib|
#   libs_by_weight[lib.max_scannable_books] ||= []
#   libs_by_weight[lib.max_scannable_books] << lib
#   # used_lib_count += 1
# end

highest_available_weighted_lib_id = nil
working_libraries = libraries
libs_by_weight = {} of Int64 => Array(Library)
while working_libraries.any?
  to_remove = [] of Int64
  working_libraries.each do |id, library|
    library_id = library.weight!(highest_available_weighted_lib_id, days, libraries, current_day, all_books)
    current_highest_weight = libraries[highest_available_weighted_lib_id].weight unless highest_available_weighted_lib_id.nil?
    lib_weight = library.weight
    if lib_weight.is_a?(Int64)
      highest_available_weighted_lib_id = library_id if highest_available_weighted_lib_id.nil? || (current_highest_weight.is_a?(Int64) && (lib_weight > current_highest_weight))
    end
    lib_weight = library.weight
    if lib_weight.is_a?(Int64)
      to_remove << id unless lib_weight > 0
    end
  end
  to_remove.each do |id|
    working_libraries.delete(id)
  end
  break unless highest_available_weighted_lib_id
  library = libraries[highest_available_weighted_lib_id]
  lib_weight = library.weight
  if lib_weight.is_a?(Int64)
    libs_by_weight[lib_weight] ||= [] of Library
    libs_by_weight[lib_weight] << library
    library.lock_in_books!(all_books)
    current_day += library.time_to_sign_up
    working_libraries.delete(highest_available_weighted_lib_id)
    highest_available_weighted_lib_id = nil
  end
end

# libs_by_weight.sort.each do |_weight, libs|
#   libs.each(&:weight!)
# end

# output results

# libs_by_weight = {}
# libraries.each do |id, lib|
#   libs_by_weight[lib.weight] ||= []
#   libs_by_weight[lib.weight] << lib
# end

final_string = ""

current_day = 0
used_lib_count = 0
libs_by_weight.each do |_weight, libs|
  # libs_by_weight.sort.reverse.each do |_weight, libs|
  libs.each do |library|
    scannable_days = days - current_day - library.time_to_sign_up
    next if scannable_days < 0
    max_books_scanned = [(scannable_days * library.books_scanned_per_day).floor, library.book_count].min
    next unless max_books_scanned > 0

    used_lib_count += 1
    final_string += "#{library.id} #{max_books_scanned}\n"
    library_books = library.books
    if library_books.is_a?(Array(Int64))
      final_string += "#{library_books[0..max_books_scanned - 1].join(" ")}\n"
    end
    current_day += library.time_to_sign_up
  end
end

final_string = "#{used_lib_count.to_s}\n" + final_string
File.write("results_#{filename.split(".").first}.txt", final_string)
