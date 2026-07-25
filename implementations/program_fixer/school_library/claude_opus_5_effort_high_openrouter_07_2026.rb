require 'date'

class Nameable
  def correct_name
    raise NotImplementedError, 'Subclasses must implement the correct_name method'
  end
end

class Decorator < Nameable
  attr_reader :nameable

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
    name = super
    return name if name.nil?

    name.to_s[0, 10]
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    name = super
    return name if name.nil?

    name.to_s.capitalize
  end
end

class Rental
  attr_accessor :date, :book, :person

  def initialize(date, book, person)
    @date = date
    @book = book
    @person = person

    book.rentals << self if book.respond_to?(:rentals) && !book.rentals.include?(self)
    person.rentals << self if person.respond_to?(:rentals) && !person.rentals.include?(self)
  end
end

class Book
  attr_accessor :title, :author
  attr_reader :rentals

  def initialize(title = '', author = '')
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

  def initialize(label = '')
    @label = label
    @students = []
  end

  def add_student(student)
    return if student.nil?

    @students << student unless @students.include?(student)
    student.assign_classroom(self) if student.respond_to?(:assign_classroom)
    student
  end
end

class Person < Nameable
  attr_accessor :name, :age, :parent_permission
  attr_reader :rentals
  attr_accessor :id

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    super()
    name, age = age, name if name.is_a?(Numeric) && !age.is_a?(Numeric)
    @id = rand(1..1_000_000)
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

  def normalize_name(name)
    return 'Unknown' if name.nil?

    str = name.to_s
    str.strip.empty? ? 'Unknown' : str
  end

  def normalize_age(age)
    case age
    when Numeric then age.to_i
    when nil then 0
    else
      str = age.to_s.strip
      str.empty? ? 0 : str.to_i
    end
  end

  def normalize_permission(permission)
    case permission
    when true, false then permission
    when nil then false
    when String
      %w[y yes true 1].include?(permission.strip.downcase)
    when Numeric then !permission.zero?
    else true
    end
  end

  def of_age?
    @age >= 18
  end
end

class Student < Person
  attr_reader :classroom

  def initialize(age = 0, classroom = nil, name = 'Unknown', parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom unless classroom.nil?
  end

  def play_hooky
    '¯\\(ツ)/¯'
  end

  def classroom=(room)
    @classroom = room
    return if room.nil?

    room.students << self if room.respond_to?(:students) && !room.students.include?(self)
    room
  end

  def assign_classroom(room)
    @classroom = room
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age = 0, specialization = nil, name = 'Unknown', parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @specialization = specialization
  end

  def can_use_services?
    true
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
    print 'Do you want to create a student (1) or a teacher (2)? '
    choice = read_input
    case choice.downcase
    when '1', 'student' then create_student
    when '2', 'teacher' then create_teacher
    else
      puts 'Invalid selection, please try again'
      nil
    end
  end

  def create_student
    print 'Name: '
    name = read_input
    print 'Age: '
    age = read_input
    print 'Has parent permission? [Y/N]: '
    permission = read_input
    student = Student.new(age, nil, name, parent_permission: truthy_answer?(permission))
    @people << student
    puts 'Person created successfully'
    student
  end

  def create_teacher
    print 'Name: '
    name = read_input
    print 'Age: '
    age = read_input
    print 'Specialization: '
    specialization = read_input
    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    puts 'Person created successfully'
    teacher
  end

  def create_book
    print 'Title: '
    title = read_input
    print 'Author: '
    author = read_input
    book = Book.new(title, author)
    @books << book
    puts 'Book created successfully'
    book
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'You need at least one book and one person to create a rental'
      return nil
    end

    puts 'Select a book from the following list by number'
    @books.each_with_index { |book, index| puts "#{index}: #{book.title}" }
    book_index = read_input.to_i

    puts 'Select a person from the following list by number (not id)'
    @people.each_with_index { |person, index| puts "#{index}: [#{person.class}] Name: #{person.name}" }
    person_index = read_input.to_i

    unless valid_indices?(person_index, book_index)
      puts 'Invalid selection'
      return nil
    end

    print 'Date: '
    date = read_input
    date = Date.today.to_s if date.empty?

    rental = Rental.new(date, @books[book_index], @people[person_index])
    @rentals << rental
    puts 'Rental created successfully'
    rental
  end

  def list_rentals
    print 'ID of person: '
    person_id = read_input.to_i
    person = @people.find { |p| p.id == person_id }

    if person.nil?
      puts 'Person not found'
      return
    end

    if person.rentals.empty?
      puts 'No rentals found'
      return
    end

    person.rentals.each { |rental| puts "Date: #{rental.date}, Book: #{rental.book.title}" }
  end

  private

  def read_input
    input = gets
    input.nil? ? '' : input.chomp.strip
  end

  def truthy_answer?(answer)
    %w[y yes true 1].include?(answer.to_s.strip.downcase)
  end

  def valid_indices?(person_index, book_index)
    return false if person_index.negative? || book_index.negative?

    person_index < @people.length && book_index < @books.length
  end
end