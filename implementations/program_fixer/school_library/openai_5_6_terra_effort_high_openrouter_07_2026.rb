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
      puts "Title: \"#{book.title}\", Author: #{book.author}"
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
    print 'Do you want to create a student (1) or a teacher (2)? '
    choice = gets&.chomp

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
    name = valid_name(gets&.chomp)

    print 'Age: '
    age = valid_age(gets&.chomp)

    print 'Has parent permission? [Y/N]: '
    permission = valid_permission(gets&.chomp)

    student = Student.new(age, nil, name, parent_permission: permission)
    @people << student
    puts 'Student created successfully'
    student
  end

  def create_teacher
    print 'Name: '
    name = valid_name(gets&.chomp)

    print 'Age: '
    age = valid_age(gets&.chomp)

    print 'Specialization: '
    specialization = gets&.chomp.to_s.strip

    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    puts 'Teacher created successfully'
    teacher
  end

  def create_book
    print 'Title: '
    title = gets&.chomp.to_s.strip

    print 'Author: '
    author = gets&.chomp.to_s.strip

    book = Book.new(title, author)
    @books << book
    puts 'Book created successfully'
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

    book_index = valid_index(gets&.chomp)

    puts 'Select a person'
    @people.each_with_index do |person, index|
      puts "#{index}: #{person.name}"
    end

    person_index = valid_index(gets&.chomp)

    unless valid_indices?(person_index, book_index)
      puts 'Invalid book or person selection'
      return nil
    end

    rental = Rental.new(Date.today, @books[book_index], @people[person_index])
    puts 'Rental created successfully'
    rental
  end

  def list_rentals
    print 'ID of person: '
    person_id = valid_index(gets&.chomp)

    person = @people.find { |registered_person| registered_person.id == person_id }

    unless person
      puts 'Person not found'
      return
    end

    if person.rentals.empty?
      puts 'No rentals found'
      return
    end

    person.rentals.each do |rental|
      puts "Date: #{rental.date}, Book: \"#{rental.book.title}\" by #{rental.book.author}"
    end
  end

  private

  def valid_indices?(person_index, book_index)
    person_index.is_a?(Integer) &&
      book_index.is_a?(Integer) &&
      person_index >= 0 &&
      book_index >= 0 &&
      person_index < @people.length &&
      book_index < @books.length
  end

  def valid_index(value)
    Integer(value)
  rescue ArgumentError, TypeError
    nil
  end

  def valid_age(value)
    age = Integer(value)
    age >= 0 ? age : 0
  rescue ArgumentError, TypeError
    0
  end

  def valid_name(value)
    name = value.to_s.strip
    name.empty? ? 'Unknown' : name
  end

  def valid_permission(value)
    value.to_s.strip.casecmp('y').zero?
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
    super[0, 10]
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    super.capitalize
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
    @title = title.to_s
    @author = author.to_s
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
    @label = label.to_s
    @students = []
  end

  def students=(students)
    @students = Array(students)
  end

  def add_student(student)
    return if student.nil?

    @students << student unless @students.include?(student)
    student.assign_classroom(self) unless student.classroom.equal?(self)
  end
end

class Person < Nameable
  attr_reader :id, :name, :age, :rentals, :parent_permission

  def initialize(age, name = 'Unknown', parent_permission: true)
    @id = rand(1000)
    self.name = name
    self.age = age
    self.parent_permission = parent_permission
    @rentals = []
  end

  def id=(value)
    @id = normalize_integer(value, 0)
  end

  def name=(value)
    normalized_name = value.to_s.strip
    @name = normalized_name.empty? ? 'Unknown' : normalized_name
  end

  def age=(value)
    normalized_age = normalize_integer(value, 0)
    @age = normalized_age.negative? ? 0 : normalized_age
  end

  def parent_permission=(value)
    @parent_permission =
      case value
      when true
        true
      when false
        false
      else
        value.to_s.strip.casecmp('y').zero? || value.to_s.strip.casecmp('true').zero?
      end
  end

  def rentals=(value)
    @rentals = Array(value)
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

  def normalize_integer(value, default)
    Integer(value)
  rescue ArgumentError, TypeError
    default
  end
end

class Student < Person
  attr_reader :classroom

  def initialize(age, classroom = nil, name = 'Unknown', parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    @classroom = nil
    assign_classroom(classroom) unless classroom.nil?
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(classroom)
    assign_classroom(classroom)
  end

  def assign_classroom(classroom)
    return if @classroom.equal?(classroom)

    @classroom.students.delete(self) if @classroom

    @classroom = classroom

    if @classroom && !@classroom.students.include?(self)
      @classroom.students << self
    end
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name = 'Unknown')
    super(age, name, parent_permission: true)
    @specialization = specialization.to_s
  end

  def can_use_services?
    true
  end
end