require 'date'

class App
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
      puts "title: #{book.title}, author: #{book.author}"
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
      return
    end

    @people.each do |person|
      puts "[#{person.class}] id: #{person.id}, Name: #{person.name}, Age: #{person.age}"
    end
  end

  def create_person
    print 'Student(3) or Teacher(1)? '
    choice = gets.to_s.strip

    case choice
    when '1'
      create_teacher
    when '2', '3'
      create_student
    else
      puts 'Invalid selection'
    end
  end

  def create_student
    print 'Name: '
    name = sanitize_name(gets)

    print 'Age: '
    age = sanitize_age(gets)

    print 'Parent permission? '
    parent_permission = gets.to_s.strip.upcase == 'Y'

    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
    student
  end

  def create_teacher
    print 'Name: '
    name = sanitize_name(gets)

    print 'Age: '
    age = sanitize_age(gets)

    print 'Specialization: '
    specialization = gets.to_s.strip
    specialization = 'Unknown' if specialization.empty?

    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    teacher
  end

  def create_book
    print 'Title: '
    title = sanitize_name(gets)

    print 'Author: '
    author = sanitize_name(gets)

    book = Book.new(title, author)
    @books << book
    book
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'No books or people available'
      return
    end

    puts 'Select a book'
    @books.each_with_index { |book, index| puts "#{index}: #{book.title}" }
    book_index = gets.to_s.to_i

    puts 'Select person'
    @people.each_with_index { |person, index| puts "#{index}: #{person.name}" }
    person_index = gets.to_s.to_i

    if valid_indices?(person_index, book_index)
      Rental.new(Date.today, @books[book_index], @people[person_index])
      puts 'Rental created'
    else
      puts 'Invalid selection'
    end
  end

  def list_rentals
    print 'ID of person: '
    person_id = gets.to_s.strip.to_i
    person = @people.find { |p| p.id == person_id }

    unless person
      puts 'Person not found'
      return
    end

    if person.rentals.empty?
      puts 'No rentals'
    else
      person.rentals.each { |rental| puts "#{rental.date} - #{rental.book.title}" }
    end
  end

  private

  def valid_indices?(person_index, book_index)
    person_index.is_a?(Integer) && book_index.is_a?(Integer) &&
      person_index >= 0 && person_index < @people.length &&
      book_index >= 0 && book_index < @books.length
  end

  def sanitize_name(value)
    name = value.to_s.strip
    name.empty? ? 'Unknown' : name
  end

  def sanitize_age(value)
    age = value.is_a?(Integer) ? value : value.to_s.to_i
    age = 0 if age < 0
    age
  end
end

class Nameable
  def correct_name
    nil
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

    @book.rentals << self if @book.respond_to?(:rentals) && @book.rentals
    @person.rentals << self if @person.respond_to?(:rentals) && @person.rentals
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

class Classroom
  attr_accessor :label
  attr_reader :students

  def initialize(label)
    @label = label
    @students = []
  end

  def add_student(student)
    return unless student

    @students << student unless @students.include?(student)
    student.classroom = self if student.respond_to?(:classroom=)
  end
end

class Person < Nameable
  attr_accessor :name, :age, :rentals
  attr_reader :id, :parent_permission

  @@next_id = 0

  def initialize(*args, parent_permission: true)
    first = args[0]
    second = args[1]

    if numeric_value?(first)
      age = first
      name = args.length > 1 ? second : 'Unknown'
    else
      name = first
      age = args.length > 1 ? second : 0
    end

    @@next_id += 1
    @id = @@next_id
    @name = name.to_s.strip
    @name = 'Unknown' if @name.empty?
    @age = age.is_a?(Integer) ? age : age.to_s.to_i
    @age = 0 if @age < 0

    @parent_permission = case parent_permission
                         when true, 1, 'true', 'TRUE', 'Y', 'y'
                           true
                         else
                           false
                         end

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

  def numeric_value?(value)
    value.is_a?(Numeric) || value.to_s.strip.match?(/\A-?\d+\z/)
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
    @classroom = room
    return unless room && room.respond_to?(:students)

    room.students << self unless room.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(*args, parent_permission: true)
    first = args[0]

    if first.is_a?(Numeric) || first.to_s.strip.match?(/\A-?\d+\z/)
      age = args[0]
      specialization = args[1]
      name = args[2] || 'Unknown'
    else
      name = args[0] || 'Unknown'
      specialization = args[1]
      age = args[2] || 0
    end

    super(age, name, parent_permission: parent_permission)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end