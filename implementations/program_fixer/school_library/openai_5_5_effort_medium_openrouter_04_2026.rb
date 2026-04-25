require 'date'

class Nameable
  def correct_name
    raise NotImplementedError, 'correct_name must be implemented'
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

class Book
  attr_accessor :title, :author, :rentals

  def initialize(title, author)
    @title = title.to_s
    @author = author.to_s
    @rentals = []
  end

  def add_rental(person, date)
    Rental.new(date, self, person)
  end
end

class Classroom
  attr_accessor :label, :students

  def initialize(label)
    @label = label.to_s
    @students = []
  end

  def add_student(student)
    return if student.nil?

    @students << student unless @students.include?(student)
    student.classroom = self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals, :parent_permission

  def initialize(age = 0, name = 'Unknown', parent_permission: true)
    if age.is_a?(String) && !integer_string?(age) && integer_like?(name)
      age, name = name, age
    end

    @id = rand(1..1000)
    @name = normalize_name(name)
    @age = normalize_age(age)
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

  def of_age?
    @age >= 18
  end

  def normalize_name(value)
    name = value.to_s.strip
    name.empty? ? 'Unknown' : name
  end

  def normalize_age(value)
    age = integer_like?(value) ? value.to_i : 0
    age.negative? ? 0 : age
  end

  def normalize_permission(value)
    return true if value == true
    return false if value == false || value.nil?

    case value.to_s.strip.downcase
    when 'y', 'yes', 'true'
      true
    else
      false
    end
  end

  def integer_like?(value)
    value.to_s.strip.match?(/\A-?\d+\z/)
  end

  def integer_string?(value)
    value.to_s.strip.match?(/\A-?\d+\z/)
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
    return if room.nil?

    @classroom = room
    room.students = [] if room.students.nil?
    room.students << self unless room.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age = 0, specialization = '', name = 'Unknown')
    if age.is_a?(String) && !age.to_s.strip.match?(/\A-?\d+\z/) && name.to_s.strip.match?(/\A-?\d+\z/)
      actual_name = age
      actual_age = name
      actual_specialization = specialization
    else
      actual_age = age
      actual_specialization = specialization
      actual_name = name
    end

    super(actual_age, actual_name)
    @specialization = actual_specialization.to_s
  end

  def can_use_services?
    true
  end
end

class Rental
  attr_accessor :date, :book, :person

  def initialize(date, book, person)
    if date.is_a?(Book)
      actual_date = person
      actual_book = date
      actual_person = book
    elsif date.is_a?(Person)
      actual_date = book
      actual_book = person
      actual_person = date
    else
      actual_date = date
      actual_book = book
      actual_person = person
    end

    @date = actual_date.to_s
    @book = actual_book
    @person = actual_person

    @book.rentals = [] if @book && @book.rentals.nil?
    @person.rentals = [] if @person && @person.rentals.nil?

    @book.rentals << self if @book && !@book.rentals.include?(self)
    @person.rentals << self if @person && !@person.rentals.include?(self)
  end
end

class App
  attr_reader :books, :people

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
    choice = safe_gets.downcase

    case choice
    when '1', '3', 'student', 's'
      create_student
    when '2', 'teacher', 't'
      create_teacher
    else
      puts 'Invalid selection'
      nil
    end
  end

  def create_student
    print 'Name: '
    name = safe_gets

    print 'Age: '
    age = parse_age(safe_gets)

    print 'Has parent permission? [Y/N]: '
    parent_permission = parse_parent_permission(safe_gets)

    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
    student
  end

  def create_teacher
    print 'Name: '
    name = safe_gets

    print 'Age: '
    age = parse_age(safe_gets)

    print 'Specialization: '
    specialization = safe_gets

    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    teacher
  end

  def create_book
    print 'Title: '
    title = safe_gets

    print 'Author: '
    author = safe_gets

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
    @books.each_with_index { |book, index| puts "#{index}: Title: #{book.title}, Author: #{book.author}" }
    book_index = parse_integer(safe_gets)

    puts 'Select a person from the following list by number'
    @people.each_with_index do |person, index|
      puts "#{index}: [#{person.class}] ID: #{person.id}, Name: #{person.name}, Age: #{person.age}"
    end
    person_index = parse_integer(safe_gets)

    unless valid_indices?(person_index, book_index)
      puts 'Invalid selection'
      return nil
    end

    print 'Date: '
    date = safe_gets
    date = Date.today.to_s if date.empty?

    Rental.new(date, @books[book_index], @people[person_index])
  end

  def list_rentals
    print 'ID of person: '
    person_id = parse_integer(safe_gets)

    if person_id.nil?
      puts 'Invalid ID'
      return
    end

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

  def safe_gets
    input = gets
    input.nil? ? '' : input.chomp.strip
  end

  def parse_integer(value)
    string_value = value.to_s.strip
    return nil unless string_value.match?(/\A-?\d+\z/)

    string_value.to_i
  end

  def parse_age(value)
    age = parse_integer(value)
    return 0 if age.nil? || age.negative?

    age
  end

  def parse_parent_permission(value)
    case value.to_s.strip.downcase
    when 'y', 'yes', 'true'
      true
    else
      false
    end
  end

  def valid_indices?(person_index, book_index)
    return false unless person_index.is_a?(Integer) && book_index.is_a?(Integer)

    person_index >= 0 &&
      person_index < @people.length &&
      book_index >= 0 &&
      book_index < @books.length
  end
end