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
    choice = read_line.strip.downcase

    case choice
    when '1', 'student', 's', '3'
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
    name = read_line

    print 'Age: '
    age = read_line

    print 'Parent permission? [Y/N]: '
    permission = read_line

    student = Student.new(age, nil, name, parent_permission: permission)
    @people << student
    student
  end

  def create_teacher
    print 'Name: '
    name = read_line

    print 'Age: '
    age = read_line

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
    book_index = parse_index(read_line)

    puts 'Select a person from the following list by number'
    @people.each_with_index do |person, index|
      puts "#{index}) [#{person.class}] ID: #{person.id}, Name: #{person.name}, Age: #{person.age}"
    end
    person_index = parse_index(read_line)

    unless valid_indices?(person_index, book_index)
      puts 'Invalid selection'
      return nil
    end

    print 'Date [YYYY-MM-DD]: '
    date = read_line
    date = Date.today.to_s if date.strip.empty?

    Rental.new(date, @books[book_index], @people[person_index])
  end

  def list_rentals
    print 'ID of person: '
    person_id = parse_index(read_line)

    person = @people.find { |item| item.id == person_id }

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

  def parse_index(value)
    Integer(value)
  rescue ArgumentError, TypeError
    nil
  end

  def valid_indices?(person_index, book_index)
    return false unless person_index.is_a?(Integer) && book_index.is_a?(Integer)

    person_index >= 0 &&
      person_index < @people.length &&
      book_index >= 0 &&
      book_index < @books.length
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, "#{self.class} must implement #correct_name"
  end
end

class Decorator < Nameable
  attr_accessor :nameable

  def initialize(nameable)
    super()
    @nameable = nameable
  end

  def correct_name
    @nameable.correct_name
  end
end

class TrimmerDecorator < Decorator
  def correct_name
    name = super.to_s
    name.length > 10 ? name[0, 10] : name
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

    if @book
      @book.rentals = [] if @book.rentals.nil?
      @book.rentals << self unless @book.rentals.include?(self)
    end

    return unless @person

    @person.rentals = [] if @person.rentals.nil?
    @person.rentals << self unless @person.rentals.include?(self)
  end
end

class Book
  attr_accessor :title, :author, :rentals

  def initialize(title, author)
    @title = normalize_text(title)
    @author = normalize_text(author)
    @rentals = []
  end

  def add_rental(person, date)
    Rental.new(date, self, person)
  end

  private

  def normalize_text(value)
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
    return if student.nil?

    student.classroom = self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals, :parent_permission

  def initialize(age = 0, name = 'Unknown', parent_permission: true)
    actual_age, actual_name = normalize_constructor_arguments(age, name)

    @id = rand(1..1000)
    @name = self.class.normalize_name(actual_name)
    @age = self.class.normalize_age(actual_age)
    @parent_permission = self.class.normalize_permission(parent_permission)
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

  class << self
    def normalize_age(value)
      age = Integer(value)
      age.negative? ? 0 : age
    rescue ArgumentError, TypeError
      0
    end

    def valid_integer?(value)
      Integer(value)
      true
    rescue ArgumentError, TypeError
      false
    end

    def normalize_name(value)
      name = value.to_s.strip
      name.empty? ? 'Unknown' : name
    end

    def normalize_permission(value)
      return true if value == true
      return false if value == false

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

  private

  def normalize_constructor_arguments(age, name)
    if !self.class.valid_integer?(age) && self.class.valid_integer?(name)
      [name, age]
    else
      [age, name]
    end
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

  def classroom=(classroom)
    @classroom = classroom
    return if classroom.nil?

    classroom.students = [] if classroom.students.nil?
    classroom.students << self unless classroom.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization = nil, name = 'Unknown')
    if !Person.valid_integer?(age) && Person.valid_integer?(name)
      actual_age = name
      actual_name = age
    else
      actual_age = age
      actual_name = name
    end

    super(actual_age, actual_name, parent_permission: true)
    @specialization = specialization.to_s.strip
  end

  def can_use_services?
    true
  end
end