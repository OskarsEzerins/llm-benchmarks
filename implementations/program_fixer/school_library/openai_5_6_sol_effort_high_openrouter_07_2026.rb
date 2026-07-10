require 'date'

class Nameable
  def correct_name
    raise NotImplementedError, "#{self.class} must implement #correct_name"
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

class Person < Nameable
  attr_reader :id, :age, :rentals, :parent_permission
  attr_accessor :name

  def initialize(age = 0, name = 'Unknown', parent_permission: true)
    @id = rand(1..1000)
    self.age = age
    self.name = name
    self.parent_permission = parent_permission
    @rentals = []
  end

  def name=(value)
    value = value.to_s
    @name = value.strip.empty? ? 'Unknown' : value
  end

  def age=(value)
    @age = normalize_age(value)
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

  def normalize_age(value)
    age =
      case value
      when Integer
        value
      when Float
        value.finite? && value == value.to_i ? value.to_i : 0
      when String
        value.strip.match?(/\A[+-]?\d+\z/) ? value.to_i : 0
      else
        0
      end

    age.negative? ? 0 : age
  end

  def normalize_permission(value)
    return true if value == true
    return false if value == false || value.nil?

    %w[y yes true 1].include?(value.to_s.strip.downcase)
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
    return @classroom unless room.nil? || room.respond_to?(:students)

    @classroom.students.delete(self) if @classroom&.respond_to?(:students)
    @classroom = room

    if @classroom && @classroom.students.is_a?(Array)
      @classroom.students << self unless @classroom.students.include?(self)
    end

    @classroom
  end

  def assign_classroom(room)
    self.classroom = room
  end
end

class Teacher < Person
  attr_reader :specialization

  def initialize(age, specialization, name = 'Unknown')
    super(age, name)
    self.specialization = specialization
  end

  def specialization=(value)
    value = value.to_s
    @specialization = value.strip.empty? ? 'Unknown' : value
  end

  def can_use_services?
    true
  end
end

class Book
  attr_accessor :title, :author
  attr_reader :rentals

  def initialize(title, author)
    @title = title.to_s
    @author = author.to_s
    @rentals = []
  end

  def add_rental(person, date)
    Rental.new(date, self, person)
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

class Classroom
  attr_accessor :label
  attr_reader :students

  def initialize(label)
    @label = label
    @students = []
  end

  def students=(students)
    @students = []
    Array(students).compact.each { |student| add_student(student) }
  end

  def add_student(student)
    return nil unless student.respond_to?(:classroom=)

    student.classroom = self
    @students << student unless @students.include?(student)
    student
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
      return @books
    end

    @books.each do |book|
      puts "Title: #{book.title}, Author: #{book.author}"
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
      return @people
    end

    @people.each do |person|
      puts "[#{person.class}] ID: #{person.id}, Name: #{person.name}, Age: #{person.age}"
    end
  end

  def create_person
    print 'Student (1) or Teacher (2)? '
    choice = read_line.to_s.strip.downcase

    case choice
    when '1', '3', 'student', 's'
      create_student
    when '2', 'teacher', 't'
      create_teacher
    else
      puts 'Invalid person type'
      nil
    end
  end

  def create_student
    print 'Name: '
    name = read_line

    print 'Age: '
    age = read_line

    print 'Parent permission? (Y/N): '
    permission = read_parent_permission

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

    puts 'Select a book'
    @books.each_with_index do |book, index|
      puts "#{index}: #{book.title}"
    end
    book_index = parse_integer(read_line)

    puts 'Select a person'
    @people.each_with_index do |person, index|
      puts "#{index}: #{person.name}"
    end
    person_index = parse_integer(read_line)

    unless valid_indices?(person_index, book_index)
      puts 'Invalid selection'
      return nil
    end

    Rental.new(Date.today, @books[book_index], @people[person_index])
  end

  def list_rentals(person_id = nil)
    if person_id.nil?
      print 'ID of person: '
      person_id = read_line
    end

    id = parse_integer(person_id)
    person = id.nil? ? nil : @people.find { |candidate| candidate.id == id }

    unless person
      puts 'Person not found'
      return []
    end

    if person.rentals.empty?
      puts 'No rentals found'
      return person.rentals
    end

    person.rentals.each do |rental|
      puts "#{rental.date} - #{rental.book.title}"
    end
  end

  private

  def read_line
    input = gets
    input&.chomp
  end

  def read_parent_permission
    response = read_line.to_s.strip.downcase

    case response
    when 'y', 'yes'
      true
    when 'n', 'no'
      false
    else
      puts 'Invalid permission response; using no permission'
      false
    end
  end

  def parse_integer(value)
    text = value.to_s.strip
    return nil unless text.match?(/\A[+-]?\d+\z/)

    text.to_i
  end

  def valid_indices?(person_index, book_index)
    person_index.is_a?(Integer) &&
      book_index.is_a?(Integer) &&
      person_index.between?(0, @people.length - 1) &&
      book_index.between?(0, @books.length - 1)
  end
end