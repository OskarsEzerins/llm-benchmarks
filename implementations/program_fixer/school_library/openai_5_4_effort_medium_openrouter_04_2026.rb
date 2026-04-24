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
    print 'Do you want to create a student (1) or a teacher (2)? [Input the number]: '
    choice = gets.to_s.chomp

    case choice
    when '1', 'student', 'Student', '3'
      create_student
    when '2', 'teacher', 'Teacher'
      create_teacher
    else
      puts 'Invalid option'
      nil
    end
  end

  def create_student
    print 'Name: '
    name = sanitize_text(gets)

    print 'Age: '
    age = parse_age(gets)

    print 'Has parent permission? [Y/N]: '
    permission = parse_permission(gets)

    student = Student.new(age, nil, name, parent_permission: permission)
    @people << student
    student
  end

  def create_teacher
    print 'Name: '
    name = sanitize_text(gets)

    print 'Age: '
    age = parse_age(gets)

    print 'Specialization: '
    specialization = sanitize_text(gets)

    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    teacher
  end

  def create_book
    print 'Title: '
    title = sanitize_text(gets)

    print 'Author: '
    author = sanitize_text(gets)

    book = Book.new(title, author)
    @books << book
    book
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'Books and people must exist to create a rental'
      return nil
    end

    puts 'Select a book from the following list by number'
    @books.each_with_index do |book, index|
      puts "#{index}) Title: #{book.title}, Author: #{book.author}"
    end
    book_index = parse_index(gets)

    puts 'Select a person from the following list by number (not id)'
    @people.each_with_index do |person, index|
      puts "#{index}) [#{person.class}] Name: #{person.name}, ID: #{person.id}, Age: #{person.age}"
    end
    person_index = parse_index(gets)

    unless valid_indices?(person_index, book_index)
      puts 'Invalid selection'
      return nil
    end

    print 'Date: '
    date = gets.to_s.chomp
    date = Date.today.to_s if date.strip.empty?

    Rental.new(date, @books[book_index], @people[person_index])
  end

  def list_rentals
    print 'ID of person: '
    person_id = parse_index(gets)

    person = @people.find { |p| p.id == person_id }

    if person.nil?
      puts 'Person not found'
      return
    end

    if person.rentals.empty?
      puts 'No rentals found for this person'
      return
    end

    person.rentals.each do |rental|
      puts "Date: #{rental.date}, Book: #{rental.book.title} by #{rental.book.author}"
    end
  end

  private

  def valid_indices?(person_index, book_index)
    person_index.is_a?(Integer) &&
      book_index.is_a?(Integer) &&
      person_index.between?(0, @people.length - 1) &&
      book_index.between?(0, @books.length - 1)
  end

  def parse_age(value)
    age = Integer(value.to_s.chomp, 10)
    age.negative? ? 0 : age
  rescue ArgumentError, TypeError
    0
  end

  def parse_permission(value)
    case value.to_s.strip.downcase
    when 'y', 'yes', 'true', '1'
      true
    when 'n', 'no', 'false', '0'
      false
    else
      false
    end
  end

  def sanitize_text(value)
    text = value.to_s.chomp.strip
    text.empty? ? 'Unknown' : text
  end

  def parse_index(value)
    Integer(value.to_s.chomp, 10)
  rescue ArgumentError, TypeError
    -1
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, 'Implement correct_name in a subclass'
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

    @book.rentals << self unless @book.rentals.include?(self)
    @person.rentals << self unless @person.rentals.include?(self)
  end
end

class Book
  attr_reader :title, :author, :rentals

  def initialize(title, author)
    @title = title.to_s.strip.empty? ? 'Unknown' : title.to_s
    @author = author.to_s.strip.empty? ? 'Unknown' : author.to_s
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
    student.classroom = self unless student.classroom == self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals

  def initialize(age, name = 'Unknown', parent_permission: true, id: nil)
    @id = id.is_a?(Integer) ? id : Random.rand(1..1000)
    @name = sanitize_name(name)
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

  def sanitize_name(value)
    text = value.to_s.strip
    text.empty? ? 'Unknown' : text
  end

  def normalize_age(value)
    age = Integer(value, 10)
    age.negative? ? 0 : age
  rescue ArgumentError, TypeError
    0
  end

  def normalize_permission(value)
    case value
    when true, false
      value
    when String
      %w[y yes true 1].include?(value.strip.downcase)
    else
      !!value
    end
  end
end

class Student < Person
  attr_reader :classroom

  def initialize(age, classroom = nil, name = 'Unknown', parent_permission: true, id: nil)
    super(age, name, parent_permission: parent_permission, id: id)
    @classroom = nil
    self.classroom = classroom unless classroom.nil?
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(classroom)
    @classroom = classroom
    return if classroom.nil?

    classroom.students << self unless classroom.students.include?(self)
  end

  def assign_classroom(classroom)
    self.classroom = classroom
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name = 'Unknown', id: nil)
    super(age, name, parent_permission: true, id: id)
    @specialization = specialization.to_s.strip.empty? ? 'Unknown' : specialization.to_s
  end

  def can_use_services?
    true
  end
end