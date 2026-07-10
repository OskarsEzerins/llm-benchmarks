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
    choice = gets&.chomp

    case choice
    when '1', '3'
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
    name = gets&.chomp

    print 'Age: '
    age = parse_age(gets)

    permission = read_parent_permission
    return nil if permission.nil?

    student = Student.new(age, nil, name, parent_permission: permission)
    @people << student
    student
  end

  def create_teacher
    print 'Name: '
    name = gets&.chomp

    print 'Age: '
    age = parse_age(gets)

    print 'Specialization: '
    specialization = gets&.chomp

    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    teacher
  end

  def create_book
    print 'Title: '
    title = gets&.chomp

    print 'Author: '
    author = gets&.chomp

    book = Book.new(title, author)
    @books << book
    book
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'Books and people must be available to create a rental'
      return nil
    end

    puts 'Select a book'
    @books.each_with_index { |book, index| puts "#{index}: #{book.title}" }
    book_index = parse_index(gets)

    puts 'Select a person'
    @people.each_with_index do |person, index|
      puts "#{index}: #{person.name}"
    end
    person_index = parse_index(gets)

    unless valid_indices?(person_index, book_index)
      puts 'Invalid book or person selection'
      return nil
    end

    print 'Date: '
    input_date = gets&.chomp
    date = input_date.nil? || input_date.empty? ? Date.today.to_s : input_date

    Rental.new(date, @books[book_index], @people[person_index])
  end

  def list_rentals
    print 'ID of person: '
    person_id = integer_or_nil(gets)

    person = @people.find { |candidate| candidate.id == person_id }

    unless person
      puts 'Person not found'
      return []
    end

    person.rentals.each do |rental|
      puts "#{rental.date} - #{rental.book.title}"
    end

    person.rentals
  end

  private

  def read_parent_permission
    loop do
      print 'Parent permission? [Y/N]: '
      response = gets
      return nil if response.nil?

      case response.chomp.downcase
      when 'y', 'yes'
        return true
      when 'n', 'no'
        return false
      else
        puts 'Please enter Y or N'
      end
    end
  end

  def parse_age(value)
    age = integer_or_nil(value)
    age && age >= 0 ? age : 0
  end

  def parse_index(value)
    integer_or_nil(value)
  end

  def integer_or_nil(value)
    text = value&.strip
    return nil unless text&.match?(/\A[+-]?\d+\z/)

    text.to_i
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
    raise ArgumentError, 'A nameable object is required' unless nameable.respond_to?(:correct_name)

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
    raise ArgumentError, 'A book is required' unless book.is_a?(Book)
    raise ArgumentError, 'A person is required' unless person.is_a?(Person)

    @date = date
    @book = book
    @person = person

    book.rentals << self unless book.rentals.include?(self)
    person.rentals << self unless person.rentals.include?(self)
  end
end

class Book
  attr_accessor :title, :author
  attr_reader :rentals

  def initialize(title, author)
    @title = normalize_text(title, 'Unknown')
    @author = normalize_text(author, 'Unknown')
    @rentals = []
  end

  def add_rental(person, date)
    Rental.new(date, self, person)
  end

  private

  def normalize_text(value, fallback)
    text = value&.to_s&.strip
    text.nil? || text.empty? ? fallback : text
  end
end

class Classroom
  attr_accessor :label
  attr_reader :students

  def initialize(label)
    @label = label&.to_s || ''
    @students = []
  end

  def add_student(student)
    raise ArgumentError, 'A student is required' unless student.is_a?(Student)

    @students << student unless @students.include?(student)
    student.classroom = self unless student.classroom.equal?(self)
    student
  end
end

class Person < Nameable
  attr_reader :id, :rentals
  attr_accessor :name

  @next_id = 1

  class << self
    attr_accessor :next_id

    def generate_id
      Person.next_id ||= 1
      id = Person.next_id
      Person.next_id += 1
      id
    end
  end

  def initialize(age = 0, name = 'Unknown', parent_permission: true)
    @id = Person.generate_id
    @name = normalize_name(name)
    self.age = age
    @parent_permission = parent_permission == true
    @rentals = []
  end

  def age
    @age
  end

  def age=(value)
    parsed = parse_integer(value)
    @age = parsed && parsed >= 0 ? parsed : 0
  end

  def parent_permission
    @parent_permission
  end

  def parent_permission=(value)
    @parent_permission = value == true
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
    text = value&.to_s&.strip
    text.nil? || text.empty? ? 'Unknown' : text
  end

  def parse_integer(value)
    return value if value.is_a?(Integer)

    text = value&.to_s&.strip
    return nil unless text&.match?(/\A[+-]?\d+\z/)

    text.to_i
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
    unless room.nil? || room.is_a?(Classroom)
      raise ArgumentError, 'Classroom must be a Classroom object'
    end

    if @classroom && !@classroom.equal?(room)
      @classroom.students.delete(self)
    end

    @classroom = room
    room.students << self if room && !room.students.include?(self)
    room
  end

  alias assign_classroom classroom=
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name = 'Unknown')
    super(age, name, parent_permission: true)
    text = specialization&.to_s&.strip
    @specialization = text.nil? || text.empty? ? 'Unknown' : text
  end

  def can_use_services?
    true
  end
end