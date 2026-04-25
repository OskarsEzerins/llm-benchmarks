require 'date'

class App
  attr_accessor :books, :people

  def initialize
    @books = []
    @people = []
  end

  def list_books
    if @books.empty?
      puts 'No books available'
      return
    end

    @books.each do |book|
      puts "Title: #{book.title}, Author: #{book.author}"
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
      return
    end

    @people.each do |person|
      puts "[#{person.class}] ID: #{person.id}, Name: #{person.name}, Age: #{person.age}"
    end
  end

  def create_person
    print 'Do you want to create a student (1) or a teacher (2)? [Input the number]: '
    choice = read_line

    case choice
    when '1'
      create_student
    when '2'
      create_teacher
    else
      puts 'Invalid selection'
      nil
    end
  end

  def create_student
    print 'Name: '
    name = read_line

    print 'Age: '
    age = normalize_integer(read_line)

    print 'Parent permission? [Y/N]: '
    parent_permission = parse_permission(read_line)

    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
    student
  end

  def create_teacher
    print 'Name: '
    name = read_line

    print 'Age: '
    age = normalize_integer(read_line)

    print 'Specialization: '
    specialization = read_line

    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    teacher
  end

  def create_book
    print 'Title: '
    title = read_line

    print 'Author: '
    author = read_line

    book = Book.new(title, author)
    @books << book
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
    @books.each_with_index { |book, index| puts "#{index}) Title: #{book.title}, Author: #{book.author}" }
    book_index = normalize_integer(read_line)

    puts 'Select a person from the following list by number'
    @people.each_with_index do |person, index|
      puts "#{index}) [#{person.class}] ID: #{person.id}, Name: #{person.name}, Age: #{person.age}"
    end
    person_index = normalize_integer(read_line)

    unless valid_indices?(person_index, book_index)
      puts 'Invalid selection'
      return nil
    end

    rental = Rental.new(Date.today.to_s, @books[book_index], @people[person_index])
    puts 'Rental created successfully'
    rental
  end

  def list_rentals
    print 'ID of person: '
    person_id = normalize_integer(read_line)

    person = @people.find { |registered_person| registered_person.id == person_id }

    if person.nil?
      puts 'Person not found'
      return
    end

    if person.rentals.empty?
      puts 'No rentals found'
      return
    end

    person.rentals.each do |rental|
      puts "Date: #{rental.date}, Book: #{rental.book.title} by #{rental.book.author}"
    end
  end

  private

  def read_line
    input = gets
    input.nil? ? '' : input.chomp
  end

  def normalize_integer(value)
    integer = Integer(value)
    integer.negative? ? 0 : integer
  rescue ArgumentError, TypeError
    0
  end

  def parse_permission(value)
    case value.to_s.strip.downcase
    when 'y', 'yes', 'true'
      true
    when 'n', 'no', 'false'
      false
    else
      false
    end
  end

  def valid_indices?(person_index, book_index)
    person_index.is_a?(Integer) &&
      book_index.is_a?(Integer) &&
      person_index >= 0 &&
      book_index >= 0 &&
      person_index < @people.length &&
      book_index < @books.length
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end
end

class Decorator < Nameable
  def initialize(nameable)
    @nameable = nameable
  end

  def correct_name
    @nameable.correct_name
  end
end

class TrimmerDecorator < Decorator
  def correct_name
    super.to_s[0, 10]
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    super.to_s.capitalize
  end
end

class Rental
  attr_accessor :date, :book, :person

  def initialize(date, book, person)
    @date = date
    @book = book
    @person = person

    @book.rentals = [] if @book && @book.respond_to?(:rentals) && @book.rentals.nil?
    @person.rentals = [] if @person && @person.respond_to?(:rentals) && @person.rentals.nil?

    @book.rentals << self if @book && @book.respond_to?(:rentals)
    @person.rentals << self if @person && @person.respond_to?(:rentals)
  end
end

class Book
  attr_accessor :title, :author, :rentals

  def initialize(title, author)
    @title = sanitize_text(title)
    @author = sanitize_text(author)
    @rentals = []
  end

  def add_rental(person, date)
    Rental.new(date, self, person)
  end

  private

  def sanitize_text(value)
    text = value.to_s.strip
    text.empty? ? 'Unknown' : text
  end
end

class Classroom
  attr_accessor :label, :students

  def initialize(label)
    @label = label.to_s.strip
    @students = []
  end

  def add_student(student)
    return nil if student.nil?

    @students << student unless @students.include?(student)
    student.classroom = self if student.respond_to?(:classroom=)
    student
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals, :parent_permission

  def initialize(age = 0, name = 'Unknown', parent_permission: true)
    actual_age, actual_name = normalize_constructor_arguments(age, name)

    @id = rand(1..1000)
    @name = sanitize_name(actual_name)
    @age = sanitize_age(actual_age)
    @parent_permission = normalize_permission(parent_permission)
    @rentals = []
  end

  def can_use_services?
    of_age? || @parent_permission
  end

  def correct_name
    @name
  end

  def add_rental(book, date)
    Rental.new(date, book, self)
  end

  private

  def normalize_constructor_arguments(age, name)
    if non_numeric_string?(age) && numeric_value?(name)
      [name, age]
    else
      [age, name]
    end
  end

  def sanitize_name(value)
    text = value.to_s.strip
    text.empty? ? 'Unknown' : text
  end

  def sanitize_age(value)
    integer = Integer(value)
    integer.negative? ? 0 : integer
  rescue ArgumentError, TypeError
    0
  end

  def normalize_permission(value)
    case value
    when true
      true
    when false, nil
      false
    else
      case value.to_s.strip.downcase
      when 'y', 'yes', 'true'
        true
      when 'n', 'no', 'false'
        false
      else
        false
      end
    end
  end

  def numeric_value?(value)
    Integer(value)
    true
  rescue ArgumentError, TypeError
    false
  end

  def non_numeric_string?(value)
    value.is_a?(String) && !numeric_value?(value)
  end

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
    return nil if room.nil?

    @classroom = room
    room.students = [] if room.respond_to?(:students) && room.students.nil?
    room.students << self if room.respond_to?(:students) && !room.students.include?(self)
    room
  end

  def assign_classroom(room)
    self.classroom = room
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age = 0, specialization = nil, name = 'Unknown')
    actual_age = age
    actual_name = name

    if age.is_a?(String) && !numeric_value_for_teacher?(age) && numeric_value_for_teacher?(name)
      actual_name = age
      actual_age = name
    end

    super(actual_age, actual_name, parent_permission: true)
    @specialization = sanitize_specialization(specialization)
  end

  def can_use_services?
    true
  end

  private

  def numeric_value_for_teacher?(value)
    Integer(value)
    true
  rescue ArgumentError, TypeError
    false
  end

  def sanitize_specialization(value)
    text = value.to_s.strip
    text.empty? ? 'Unknown' : text
  end
end