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
    choice = gets&.chomp

    case choice
    when '1'
      create_teacher
    when '2', '3'
      create_student
    else
      puts 'Invalid selection'
      nil
    end
  end

  def create_student
    print 'Name: '
    name = gets&.chomp
    print 'Age: '
    age = gets&.chomp
    print 'Parent permission? '
    permission = gets&.chomp

    unless %w[Y y N n].include?(permission)
      puts 'Invalid parent permission'
      return nil
    end

    student = Student.new(
      age,
      nil,
      name,
      parent_permission: %w[Y y].include?(permission)
    )
    @people << student
    student
  end

  def create_teacher
    print 'Name: '
    name = gets&.chomp
    print 'Age: '
    age = gets&.chomp
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
    return nil if @books.empty? || @people.empty?

    puts 'Select a book'
    @books.each_with_index { |book, index| puts "#{index}: #{book.title}" }
    book_index = Integer(gets.to_s.chomp, exception: false)

    puts 'Select person'
    @people.each_with_index { |person, index| puts "#{index}: #{person.name}" }
    person_index = Integer(gets.to_s.chomp, exception: false)

    unless valid_indices?(person_index, book_index)
      puts 'Invalid selection'
      return nil
    end

    print 'Date: '
    date = gets&.chomp
    Rental.new(date, @books[book_index], @people[person_index])
  end

  def list_rentals
    print 'ID of person: '
    person_id = Integer(gets.to_s.chomp, exception: false)
    person = @people.find { |item| item.id == person_id }

    if person.nil?
      puts 'Person not found'
      return
    end

    person.rentals.each do |rental|
      puts "#{rental.date} - #{rental.book.title}"
    end
  end

  private

  def valid_indices?(person_index, book_index)
    person_index.is_a?(Integer) &&
      book_index.is_a?(Integer) &&
      person_index.between?(0, @people.length - 1) &&
      book_index.between?(0, @books.length - 1)
  end
end

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
    @title = title.to_s
    @author = author.to_s
    @rentals = []
  end

  def add_rental(person, date)
    Rental.new(date, self, person)
  end
end

class Classroom
  attr_accessor :label, :students

  def initialize(label)
    @label = label
    @students = []
  end

  def add_student(student)
    return if @students.include?(student)

    @students << student
    student.assign_classroom(self)
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals
  attr_reader :parent_permission

  @@next_id = 1

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id = @@next_id
    @@next_id += 1
    @name = name.nil? || name.to_s.strip.empty? ? 'Unknown' : name.to_s
    @age = normalize_age(age)
    @parent_permission = !!parent_permission
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

  def normalize_age(value)
    Integer(value, exception: false) || 0
  end

  def of_age?
    @age >= 18
  end
end

class Student < Person
  attr_reader :classroom

  def initialize(age, classroom = nil, name = 'Unknown', parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    self.classroom = classroom if classroom
  end

  def play_hooky
    '¯\\_(ツ)_/¯'
  end

  def classroom=(room)
    return @classroom = nil if room.nil?

    @classroom = room
    room.students << self unless room.students.include?(self)
  end

  def assign_classroom(room)
    self.classroom = room
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(first, second = nil, third = nil)
    if first.is_a?(Numeric) || first.to_s.match?(/\A-?\d+\z/)
      age = first
      specialization = second
      name = third
    else
      name = first
      specialization = second
      age = third || 0
    end

    super(name, age, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end