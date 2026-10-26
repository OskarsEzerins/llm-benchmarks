require 'date'

class Nameable
  def correct_name
    raise NotImplementedError
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
    name = super
    return name if name.nil?

    name.length > 10 ? name[0, 10] : name
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    super.capitalize
  end
end

class Book
  attr_reader :title, :author, :rentals

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
  attr_reader :date, :book, :person

  def initialize(date, book, person)
    @date = date
    @book = book
    @person = person
    @book.rentals << self
    @person.rentals << self
  end
end

class Classroom
  attr_accessor :label, :students

  def initialize(label)
    @label = label
    @students = []
  end

  def add_student(student)
    student.classroom = self
  end
end

class Person < Nameable
  @@next_id = 0

  attr_accessor :name, :age, :rentals
  attr_reader :id, :parent_permission

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @@next_id += 1
    @id = @@next_id
    @name = name.nil? || name.to_s.empty? ? 'Unknown' : name.to_s
    @age = age.to_i
    @parent_permission = parent_permission == true ||
                         parent_permission.to_s.downcase == 'true' ||
                         parent_permission.to_s.downcase == 'y' ||
                         parent_permission.to_s.downcase == 'yes'
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
end

class Student < Person
  attr_reader :classroom

  def initialize(age, classroom, name = 'Unknown', parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom if classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    @classroom = room
    return unless room

    room.students ||= []
    room.students << self unless room.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(*args, parent_permission: true)
    if args.length >= 3
      if integer_like?(args[0])
        age, specialization, name = args
      else
        name, specialization, age = args
      end
    elsif args.length == 2
      if integer_like?(args[0])
        age, specialization = args
        name = 'Unknown'
      else
        name, specialization = args
        age = 0
      end
    else
      age = args[0] || 0
      specialization = args[1]
      name = 'Unknown'
    end

    super(name || 'Unknown', age || 0, parent_permission: parent_permission)
    @specialization = specialization
  end

  def can_use_services?
    true
  end

  private

  def integer_like?(value)
    value.is_a?(Integer) || value.to_s.match?(/\A-?\d+\z/)
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
    choice = gets
    return if choice.nil?

    case choice.chomp
    when '1'
      create_teacher
    when '3'
      create_student
    else
      puts 'Invalid option'
    end
  end

  def create_student
    print 'Name: '
    name = read_string('Unknown')
    print 'Age: '
    age = read_integer(0)
    print 'Parent permission? '
    permission = read_parent_permission

    student = Student.new(age, nil, name, parent_permission: permission)
    @people << student
  end

  def create_teacher
    print 'Name: '
    name = read_string('Unknown')
    print 'Age: '
    age = read_integer(0)
    print 'Specialization: '
    specialization = read_string('General')

    teacher = Teacher.new(age, specialization, name)
    @people << teacher
  end

  def create_book
    print 'Title: '
    title = read_string('Unknown')
    print 'Author: '
    author = read_string('Unknown')

    @books << Book.new(title, author)
  end

  def create_rental
    if @books.empty?
      puts 'No books available'
      return
    end

    if @people.empty?
      puts 'No people registered'
      return
    end

    puts 'Select a book'
    @books.each_with_index { |book, index| puts "#{index}: #{book.title}" }
    book_index = read_integer(-1)

    puts 'Select person'
    @people.each_with_index { |person, index| puts "#{index}: #{person.name}" }
    person_index = read_integer(-1)

    if valid_indices?(person_index, book_index)
      Rental.new(Date.today, @books[book_index], @people[person_index])
    else
      puts 'Invalid selection'
    end
  end

  def list_rentals
    print 'ID of person: '
    person_id = read_integer(-1)
    person = @people.find { |p| p.id == person_id }

    if person.nil?
      puts 'Person not found'
      return
    end

    if person.rentals.empty?
      puts 'No rentals found'
      return
    end

    person.rentals.each do |rental|
      puts "#{rental.date} - #{rental.book.title}"
    end
  end

  private

  def valid_indices?(person_index, book_index)
    person_index.is_a?(Integer) && book_index.is_a?(Integer) &&
      person_index >= 0 && person_index < @people.length &&
      book_index >= 0 && book_index < @books.length
  end

  def read_string(default)
    input = gets
    return default if input.nil?

    value = input.chomp.strip
    value.empty? ? default : value
  end

  def read_integer(default)
    input = gets
    return default if input.nil?

    value = Integer(input.strip)
    return default if value < 0

    value
  rescue ArgumentError
    default
  end

  def read_parent_permission
    input = gets
    return false if input.nil?

    case input.chomp.upcase
    when 'Y'
      true
    when 'N'
      false
    else
      puts 'Invalid response, defaulting to N'
      false
    end
  end
end