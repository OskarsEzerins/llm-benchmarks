require 'date'

class Nameable
  def correct_name
    raise NotImplementedError, 'Subclasses must implement correct_name'
  end
end

class Decorator < Nameable
  attr_accessor :nameable

  def initialize(nameable)
    @nameable = nameable
  end

  def correct_name
    @nameable.correct_name
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

class Person < Nameable
  attr_reader :id, :name, :age, :parent_permission, :rentals

  @next_id = 0

  def self.generate_id
    next_id = Person.instance_variable_get(:@next_id) + 1
    Person.instance_variable_set(:@next_id, next_id)
    next_id
  end

  def initialize(age, name = 'Unknown', parent_permission: true)
    @id = Person.generate_id
    self.name = name
    self.age = age
    self.parent_permission = parent_permission
    @rentals = []
  end

  def name=(value)
    text = value.to_s.strip
    @name = text.empty? ? 'Unknown' : text
  end

  def age=(value)
    parsed = if value.is_a?(Integer)
               value
             elsif value.is_a?(String) && value.strip.match?(/\A\d+\z/)
               value.strip.to_i
             end
    @age = parsed && parsed >= 0 ? parsed : 0
  end

  def parent_permission=(value)
    @parent_permission =
      value == true ||
      (value.is_a?(String) && %w[Y YES TRUE].include?(value.strip.upcase))
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
end

class Student < Person
  attr_reader :classroom

  def initialize(age, classroom = nil, name = 'Unknown', parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    unless room.nil? || room.is_a?(Classroom)
      raise ArgumentError, 'Classroom must be a Classroom or nil'
    end

    @classroom.students.delete(self) if @classroom && @classroom != room
    @classroom = room
    room.students << self if room && !room.students.include?(self)
    room
  end

  alias assign_classroom classroom=
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name = 'Unknown')
    super(age, name)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end

class Classroom
  attr_accessor :label
  attr_reader :students

  def initialize(label)
    @label = label
    @students = []
  end

  def add_student(student)
    student.classroom = self
    student
  end
end

class Book
  attr_accessor :title, :author
  attr_reader :rentals

  def initialize(title, author)
    @title = title
    @author = author
    @rentals = []
  end

  def add_rental(person, date)
    Rental.new(date, self, person)
  end
end

class Rental
  attr_accessor :date
  attr_reader :book, :person

  def initialize(date, book, person)
    unless book.is_a?(Book) && person.is_a?(Person)
      raise ArgumentError, 'A rental requires a book and a person'
    end

    @date = date
    @book = book
    @person = person
    @book.rentals << self
    @person.rentals << self
  end
end

class App
  attr_reader :books, :people, :rentals

  def initialize
    @books = []
    @people = []
    @rentals = []
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
    print 'Create a Student (1) or Teacher (2)? '

    case read_line
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
    age = parse_nonnegative_integer(read_line)
    print 'Parent permission? [Y/N]: '
    permission = read_line&.upcase

    unless valid_name?(name) && !age.nil? && %w[Y N].include?(permission)
      puts 'Invalid student details'
      return nil
    end

    student = Student.new(age, nil, name, parent_permission: permission == 'Y')
    @people << student
    puts 'Student created successfully'
    student
  end

  def create_teacher
    print 'Name: '
    name = read_line
    print 'Age: '
    age = parse_nonnegative_integer(read_line)
    print 'Specialization: '
    specialization = read_line

    unless valid_name?(name) && !age.nil? && valid_name?(specialization)
      puts 'Invalid teacher details'
      return nil
    end

    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    puts 'Teacher created successfully'
    teacher
  end

  def create_book
    print 'Title: '
    title = read_line
    print 'Author: '
    author = read_line

    unless valid_name?(title) && valid_name?(author)
      puts 'Invalid book details'
      return nil
    end

    book = Book.new(title, author)
    @books << book
    puts 'Book created successfully'
    book
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'A book and a person must exist before creating a rental'
      return nil
    end

    puts 'Select a book by its index:'
    @books.each_with_index do |book, index|
      puts "#{index}: #{book.title}, Author: #{book.author}"
    end
    book_index = parse_nonnegative_integer(read_line)

    puts 'Select a person by their index:'
    @people.each_with_index do |person, index|
      puts "#{index}: [#{person.class}] Name: #{person.name}, ID: #{person.id}, Age: #{person.age}"
    end
    person_index = parse_nonnegative_integer(read_line)

    unless valid_indices?(person_index, book_index)
      puts 'Invalid book or person selection'
      return nil
    end

    print 'Date (YYYY-MM-DD): '
    date = read_line
    if date.nil? || date.empty?
      puts 'Invalid date'
      return nil
    end

    begin
      Date.iso8601(date)
    rescue ArgumentError
      puts 'Invalid date'
      return nil
    end

    rental = Rental.new(date, @books[book_index], @people[person_index])
    @rentals << rental
    puts 'Rental created successfully'
    rental
  end

  def list_rentals
    print 'ID of person: '
    person_id = parse_nonnegative_integer(read_line)
    person = @people.find { |entry| entry.id == person_id }

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

  def read_line
    gets&.strip
  end

  def valid_name?(value)
    value.is_a?(String) && !value.strip.empty?
  end

  def parse_nonnegative_integer(value)
    return nil unless value.is_a?(String) && value.match?(/\A\d+\z/)

    value.to_i
  end

  def valid_indices?(person_index, book_index)
    person_index.is_a?(Integer) &&
      book_index.is_a?(Integer) &&
      person_index >= 0 &&
      person_index < @people.length &&
      book_index >= 0 &&
      book_index < @books.length
  end
end