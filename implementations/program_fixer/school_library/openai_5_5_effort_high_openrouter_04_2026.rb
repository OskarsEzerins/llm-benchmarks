require 'date'

module LibrarySanitizer
  module_function

  def integer_like?(value)
    return true if value.is_a?(Integer)
    return false if value.nil?

    value.to_s.strip.match?(/\A[+-]?\d+\z/)
  end

  def non_negative_integer(value, default = 0)
    return default unless integer_like?(value)

    integer = value.is_a?(Integer) ? value : value.to_s.strip.to_i
    integer.negative? ? default : integer
  end

  def string(value, default = 'Unknown')
    return default if value.nil?

    text = value.to_s.chomp.strip
    text.empty? ? default : text
  end

  def boolean(value, default = false)
    return value if value == true || value == false
    return default if value.nil?

    case value.to_s.strip.downcase
    when 'y', 'yes', 'true', '1'
      true
    when 'n', 'no', 'false', '0'
      false
    else
      default
    end
  end

  def blank?(value)
    value.nil? || value.to_s.strip.empty?
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end
end

class Decorator < Nameable
  attr_accessor :nameable

  def initialize(nameable)
    @nameable = nameable
  end

  def correct_name
    return '' unless @nameable.respond_to?(:correct_name)

    @nameable.correct_name.to_s
  end
end

class TrimmerDecorator < Decorator
  def correct_name
    super[0, 10]
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    super.capitalize
  end
end

class Book
  attr_reader :rentals
  attr_accessor :title, :author

  def initialize(title, author)
    self.title = title
    self.author = author
    self.rentals = []
  end

  def title=(value)
    @title = LibrarySanitizer.string(value)
  end

  def author=(value)
    @author = LibrarySanitizer.string(value)
  end

  def rentals=(value)
    @rentals = value.is_a?(Array) ? value : []
  end

  def add_rental(person, date)
    Rental.new(date, self, person)
  end
end

class Classroom
  attr_reader :students
  attr_accessor :label

  def initialize(label)
    self.label = label
    self.students = []
  end

  def label=(value)
    @label = LibrarySanitizer.string(value)
  end

  def students=(value)
    @students = value.is_a?(Array) ? value : []
  end

  def add_student(student)
    return nil if student.nil?

    if student.respond_to?(:classroom=)
      student.classroom = self
    else
      @students << student unless @students.include?(student)
    end

    student
  end
end

class Person < Nameable
  attr_reader :id, :age, :parent_permission, :rentals
  attr_accessor :name

  def initialize(age = 0, name = 'Unknown', parent_permission: true)
    actual_age, actual_name = self.class.normalize_age_and_name(age, name)

    @id = Random.rand(1..1000)
    self.name = actual_name
    self.age = actual_age
    self.parent_permission = parent_permission
    self.rentals = []
  end

  def self.normalize_age_and_name(age_value, name_value)
    if !LibrarySanitizer.integer_like?(age_value) &&
       (LibrarySanitizer.integer_like?(name_value) || LibrarySanitizer.string(name_value) == 'Unknown')
      actual_age = LibrarySanitizer.integer_like?(name_value) ? name_value : 0
      actual_name = age_value
      [actual_age, actual_name]
    else
      [age_value, name_value]
    end
  end

  def id=(value)
    new_id = LibrarySanitizer.non_negative_integer(value, nil)
    @id = new_id&.positive? ? new_id : Random.rand(1..1000)
  end

  def name=(value)
    @name = LibrarySanitizer.string(value)
  end

  def age=(value)
    @age = LibrarySanitizer.non_negative_integer(value, 0)
  end

  def parent_permission=(value)
    @parent_permission = LibrarySanitizer.boolean(value, false)
  end

  def rentals=(value)
    @rentals = value.is_a?(Array) ? value : []
  end

  def can_use_services?
    of_age? || @parent_permission
  end

  def correct_name
    @name.to_s
  end

  def add_rental(book, date)
    Rental.new(date, book, self)
  end

  private

  def of_age?
    @age >= 18
  end
end

class Student < Person
  attr_reader :classroom

  def initialize(age, classroom = nil, name = 'Unknown', parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom unless classroom.nil?
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    if room.nil?
      @classroom = nil
      return nil
    end

    @classroom = room
    room.students = [] unless room.students.is_a?(Array)
    room.students << self unless room.students.include?(self)
    room
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization = 'Unknown', name = 'Unknown')
    super(age, name, parent_permission: true)
    self.specialization = specialization
  end

  def specialization=(value)
    @specialization = LibrarySanitizer.string(value)
  end

  def can_use_services?
    true
  end
end

class Rental
  attr_accessor :date, :book, :person

  def initialize(date, book, person)
    actual_date, actual_book, actual_person = normalize_arguments(date, book, person)

    @date = LibrarySanitizer.blank?(actual_date) ? Date.today.to_s : actual_date
    @book = actual_book
    @person = actual_person

    append_to_rentals(@book)
    append_to_rentals(@person)
  end

  private

  def normalize_arguments(first, second, third)
    if first.is_a?(Book)
      second.is_a?(Person) ? [third, first, second] : [second, first, third]
    elsif first.is_a?(Person)
      second.is_a?(Book) ? [third, second, first] : [second, third, first]
    elsif second.is_a?(Person) && third.is_a?(Book)
      [first, third, second]
    else
      [first, second, third]
    end
  end

  def append_to_rentals(object)
    return if object.nil? || !object.respond_to?(:rentals)

    object.rentals = [] if object.respond_to?(:rentals=) && !object.rentals.is_a?(Array)
    object.rentals << self if object.rentals.is_a?(Array) && !object.rentals.include?(self)
  end
end

class App
  attr_reader :books, :people

  def initialize
    self.books = []
    self.people = []
  end

  def books=(value)
    @books = value.is_a?(Array) ? value : []
  end

  def people=(value)
    @people = value.is_a?(Array) ? value : []
  end

  def list_books
    if @books.empty?
      puts 'No books available'
      return []
    end

    @books.each do |book|
      puts "Title: #{book.title}, Author: #{book.author}"
    end

    @books
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
      return []
    end

    @people.each do |person|
      puts "[#{person.class}] ID: #{person.id}, Name: #{person.name}, Age: #{person.age}"
    end

    @people
  end

  def create_person
    print 'Do you want to create a student (1) or a teacher (2)? [Input the number]: '
    choice = read_line.strip.downcase

    case choice
    when '1', 'student', 's'
      create_student
    when '2', 'teacher', 't'
      create_teacher
    else
      puts 'Invalid choice'
      nil
    end
  end

  def create_student
    print 'Name: '
    name = read_string

    print 'Age: '
    age = read_age

    print 'Parent permission? [Y/N]: '
    parent_permission = LibrarySanitizer.boolean(read_line, false)

    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
    puts 'Student created successfully'
    student
  end

  def create_teacher
    print 'Name: '
    name = read_string

    print 'Age: '
    age = read_age

    print 'Specialization: '
    specialization = read_string

    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    puts 'Teacher created successfully'
    teacher
  end

  def create_book
    print 'Title: '
    title = read_string

    print 'Author: '
    author = read_string

    book = Book.new(title, author)
    @books << book
    puts 'Book created successfully'
    book
  end

  def create_rental
    if @books.empty?
      puts 'No books available'
      return nil
    end

    if @people.empty?
      puts 'No people available'
      return nil
    end

    puts 'Select a book from the following list by number'
    @books.each_with_index { |book, index| puts "#{index}: #{book.title} by #{book.author}" }
    book_index = parse_index(read_line)

    puts 'Select a person from the following list by number'
    @people.each_with_index do |person, index|
      puts "#{index}: [#{person.class}] Name: #{person.name}, ID: #{person.id}, Age: #{person.age}"
    end
    person_index = parse_index(read_line)

    unless valid_indices?(person_index, book_index)
      puts 'Invalid selection'
      return nil
    end

    print 'Date (YYYY-MM-DD): '
    date_input = read_line
    date = LibrarySanitizer.blank?(date_input) ? Date.today.to_s : date_input

    rental = Rental.new(date, @books[book_index], @people[person_index])
    puts 'Rental created successfully'
    rental
  end

  def list_rentals
    print 'ID of person: '
    person_id = parse_index(read_line)
    person = @people.find { |person_object| person_object.id == person_id }

    unless person
      puts 'No rentals found'
      return []
    end

    rentals = person.rentals.is_a?(Array) ? person.rentals : []

    if rentals.empty?
      puts 'No rentals found'
      return []
    end

    rentals.each do |rental|
      book_title = rental.book&.title || 'Unknown'
      book_author = rental.book&.author || 'Unknown'
      puts "Date: #{rental.date}, Book: #{book_title} by #{book_author}"
    end

    rentals
  end

  private

  def valid_indices?(person_index, book_index)
    person_index = parse_index(person_index)
    book_index = parse_index(book_index)

    return false if person_index.nil? || book_index.nil?

    person_index >= 0 &&
      person_index < @people.length &&
      book_index >= 0 &&
      book_index < @books.length
  end

  def read_line
    input = gets
    input.nil? ? '' : input.chomp
  end

  def read_string
    LibrarySanitizer.string(read_line)
  end

  def read_age
    LibrarySanitizer.non_negative_integer(read_line, 0)
  end

  def parse_index(value)
    return value if value.is_a?(Integer)
    return nil unless LibrarySanitizer.integer_like?(value)

    value.to_s.strip.to_i
  end
end