require 'parallel'
coms = [
  'ruby parser.rb a_example.txt',
  'ruby parser.rb b_read_on.txt',
  'ruby parser.rb c_incunabula.txt',
  'ruby parser.rb d_tough_choices.txt',
  'ruby parser.rb e_so_many_books.txt',
  'ruby parser.rb f_libraries_of_the_world.txt',
]
Parallel.each(coms) do |command|
  `#{command}`
  puts "#{command} done!"
end
puts `cat results_a_example.txt`
