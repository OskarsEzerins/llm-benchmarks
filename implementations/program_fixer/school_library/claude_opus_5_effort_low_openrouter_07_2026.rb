require 'date'

class Nameable
  def correct_name
    raise NotImplementedError, 'Subclasses must implement correct_name'
  end
end

class Decorator < Nameable
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

    name.length > 10 ? name[0..9] : name
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    name = super
    return name if name.nil?

    name.capitalize
  end
end

class Rental
  attr_accessor :date, :book, :person

  def initialize(date, book, person)
    @date   = date
    @book   = book
    @person = person
    book.rentals << self if book
    person.rentals << self if person
  end
end

class Book
  attr_accessor :title, :author, :rentals

  def initialize(title, author)
    @title   = title
    @author  = author
    @rentals = []
  end

  def add_rental(person, date)
    Rental.new(date, self, person)
  end
end

class Classroom
  attr_accessor :label, :students

  def initialize(label)
    @label    = label
    @students = []
  end

  def add_student(student)
    @students << student unless @students.include?(student)
    student.assign_classroom(self)
    student
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals
  attr_reader :parent_permission

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    super()
    @id = rand(1..1000)
    @name = name.nil? || name.to_s.strip.empty? ? 'Unknown' : name.to_s
    @age = age.to_i
    @parent_permission = parent_permission ? true : false
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
    '¯\\(ツ)/¯'
  end

  def classroom=(room)
    @classroom = room
    return if room.nil?

    room.students << self unless room.students.include?(self)
  end

  def assign_classroom(room)
    @classroom = room
    return if room.nil?

    room.students << self unless room.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name = 'Unknown', parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end

class App
  attr_accessor :books, :people

  def initialize
    @books  = []
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
    print 'Student(1) or Teacher(2)? '
    choice = gets&.chomp
    case choice
    when '1' then create_student
    when '2' then create_teacher
    else
      puts 'Invalid selection'
      nil
    end
  end

  def create_student
    print 'Name: '
    name = gets&.chomp
    print 'Age: '
    age = gets&.chomp.to_i
    print 'Parent permission? [Y/N]: '
    answer = gets&.chomp.to_s.upcase
    permission = answer == 'Y'
    puts 'Invalid input, defaulting to no permission' unless %w[Y N].include?(answer)
    student = Student.new(age, nil, name, parent_permission: permission)
    @people << student
    puts 'Person created successfully'
    student
  end

  def create_teacher
    print 'Name: '
    name = gets&.chomp
    print 'Age: '
    age = gets&.chomp.to_i
    print 'Specialization: '
    specialization = gets&.chomp
    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    puts 'Person created successfully'
    teacher
  end

  def create_book
    print 'Title: '
    title = gets&.chomp
    print 'Author: '
    author = gets&.chomp
    book = Book.new(title, author)
    @books << book
    puts 'Book created successfully'
    book
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'Need at least one book and one person'
      return nil
    end

    puts 'Select a book from the following list by number'
    @books.each_with_index { |b, i| puts "#{i}: Title: #{b.title}, Author: #{b.author}" }
    book_index = gets&.chomp.to_i

    puts 'Select a person from the following list by number (not id)'
    @people.each_with_index { |p, i| puts "#{i}: [#{p.class}] Name: #{p.name}, ID: #{p.id}, Age: #{p.age}" }
    person_index = gets&.chomp.to_i

    unless valid_indices?(person_index, book_index)
      puts 'Invalid selection'
      return nil
    end

    print 'Date: '
    date = gets&.chomp
    date = Date.today.to_s if date.nil? || date.empty?
    rental = Rental.new(date, @books[book_index], @people[person_index])
    puts 'Rental created successfully'
    rental
  end

  def list_rentals
    print 'ID of person: '
    id = gets&.chomp.to_i
    person = @people.find { |p| p.id == id }
    if person.nil?
      puts 'Person not found'
      return
    end
    puts 'Rentals:'
    person.rentals.each { |r| puts "Date: #{r.date}, Book: #{r.book.title} by #{r.book.author}" }
  end

  private

  def valid_indices?(person_index, book_index)
    person_index.between?(0, @people.length - 1) && book_index.between?(0, @books.length - 1)
  end
end