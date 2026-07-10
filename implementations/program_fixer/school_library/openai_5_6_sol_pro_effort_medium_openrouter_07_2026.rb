require 'date'

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
    print 'Student (1) or Teacher (2)? '
    choice = safe_gets

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
    name = safe_gets

    print 'Age: '
    age = parse_age(safe_gets)

    print 'Parent permission? [Y/N]: '
    permission = parse_permission(safe_gets)
    if permission.nil?
      puts 'Invalid parent permission response'
      return nil
    end

    student = Student.new(age, nil, name, parent_permission: permission)
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
    if @books.empty? || @people.empty?
      puts 'A book and a person are required to create a rental'
      return nil
    end

    puts 'Select a book'
    @books.each_with_index do |book, index|
      puts "#{index}: #{book.title}"
    end
    book_index = parse_index(safe_gets)

    puts 'Select a person'
    @people.each_with_index do |person, index|
      puts "#{index}: #{person.name}"
    end
    person_index = parse_index(safe_gets)

    unless valid_indices?(person_index, book_index)
      puts 'Invalid book or person selection'
      return nil
    end

    Rental.new(Date.today, @books[book_index], @people[person_index])
  end

  def list_rentals
    print 'ID of person: '
    person_id = parse_integer(safe_gets)

    person = @people.find { |candidate| candidate.id == person_id }
    unless person
      puts 'Person not found'
      return
    end

    if person.rentals.empty?
      puts 'No rentals found'
      return
    end

    person.rentals.each do |rental|
      puts "#{rental.date} - #{rental.book.title} by #{rental.book.author}"
    end
  end

  private

  def safe_gets
    input = gets
    input.nil? ? '' : input.chomp
  end

  def parse_integer(value)
    Integer(value, 10)
  rescue ArgumentError, TypeError
    nil
  end

  def parse_age(value)
    age = parse_integer(value)
    age && age >= 0 ? age : 0
  end

  def parse_index(value)
    index = parse_integer(value)
    index && index >= 0 ? index : nil
  end

  def parse_permission(value)
    case value.to_s.strip.downcase
    when 'y', 'yes'
      true
    when 'n', 'no'
      false
    end
  end

  def valid_indices?(person_index, book_index)
    person_index.is_a?(Integer) &&
      book_index.is_a?(Integer) &&
      person_index.between?(0, @people.length - 1) &&
      book_index.between?(0, @books.length - 1)
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, 'Subclasses must implement correct_name'
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
  attr_reader :date, :book, :person

  def initialize(date, book, person)
    @date = date
    @book = book
    @person = person

    @book.rentals << self unless @book.rentals.include?(self)
    @person.rentals << self unless @person.rentals.include?(self)
  end
end

class Book
  attr_accessor :title, :author
  attr_reader :rentals

  def initialize(title, author)
    @title = normalize_text(title, 'Untitled')
    @author = normalize_text(author, 'Unknown')
    @rentals = []
  end

  def add_rental(person, date)
    Rental.new(date, self, person)
  end

  private

  def normalize_text(value, default)
    text = value.to_s.strip
    text.empty? ? default : text
  end
end

class Classroom
  attr_accessor :label
  attr_reader :students

  def initialize(label)
    @label = label.to_s
    @students = []
  end

  def add_student(student)
    return nil unless student.is_a?(Student)

    @students << student unless @students.include?(student)
    student.classroom = self unless student.classroom.equal?(self)
    student
  end

  def remove_student(student)
    @students.delete(student)
  end
end

class Person < Nameable
  attr_accessor :name
  attr_reader :id, :age, :rentals, :parent_permission

  @@next_id = 1

  def initialize(age = 0, name = 'Unknown', parent_permission: true)
    @id = @@next_id
    @@next_id += 1

    self.age = age
    self.name = name
    @parent_permission = normalize_permission(parent_permission)
    @rentals = []
  end

  def age=(value)
    parsed_age = Integer(value)
    @age = parsed_age.negative? ? 0 : parsed_age
  rescue ArgumentError, TypeError
    @age = 0
  end

  def name=(value)
    normalized_name = value.to_s.strip
    @name = normalized_name.empty? ? 'Unknown' : normalized_name
  end

  def parent_permission=(value)
    @parent_permission = normalize_permission(value)
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

  def normalize_permission(value)
    return value if value == true || value == false

    %w[y yes true].include?(value.to_s.strip.downcase)
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
    return @classroom if room.equal?(@classroom)
    return @classroom unless room.nil? || room.is_a?(Classroom)

    previous_classroom = @classroom
    @classroom = room

    previous_classroom&.remove_student(self)
    room&.add_student(self)

    @classroom
  end

  def assign_classroom(room)
    self.classroom = room
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name = 'Unknown')
    super(age, name, parent_permission: true)
    normalized_specialization = specialization.to_s.strip
    @specialization = normalized_specialization.empty? ? 'Unknown' : normalized_specialization
  end

  def can_use_services?
    true
  end
end