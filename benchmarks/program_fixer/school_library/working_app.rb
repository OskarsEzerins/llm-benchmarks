# frozen_string_literal: true

# This is the working implementation that serves as the "correct answer"
# School Library Management System - https://github.com/kessie2862/school-library

class App
  def initialize
    @books = []
    @people = {}
  end

  def list_books
    puts 'No books available' if @books.empty?
    puts
    @books.each do |book|
      puts "Title: #{book.title}, Author: #{book.author}"
      puts
    end
  end

  def list_people
    puts 'No one has registered' if @people.empty?
    puts
    @people.each_value do |person|
      puts "[#{person.class}] ID: #{person.id}, Name: #{person.name}, Age: #{person.age}"
      puts
    end
  end

  def create_person
    puts
    print 'Do you want to create a student (1) or a teacher (2)? (Input the number): '
    puts
    person_type = gets.chomp

    case person_type
    when '1'
      create_student
    when '2'
      create_teacher
    else
      puts
      puts 'Option invalid, please try again'
      puts
    end
  end

  def create_student
    puts
    print 'Name: '
    name = gets.chomp
    print 'Age: '
    age = gets.chomp.to_i
    print 'Has parent permission? [Y/N]: '
    has_parent_permission = gets.chomp.upcase

    parent_permission = case has_parent_permission
                        when 'Y' then true
                        when 'N' then false
                        else
                          puts 'Option invalid, please try again'
                          return
                        end

    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people[student.id] = student
    puts 'Student created successfully.'
    puts
  end

  def create_teacher
    puts
    print 'Name: '
    name = gets.chomp
    print 'Age: '
    age = gets.chomp.to_i
    print 'Specialization: '
    specialization = gets.chomp

    teacher = Teacher.new(age, specialization, name)
    @people[teacher.id] = teacher
    puts 'Teacher created successfully.'
    puts
  end

  def create_book
    puts
    print 'Title: '
    title = gets.chomp
    print 'Author: '
    author = gets.chomp

    @books << Book.new(title, author)
    puts
    puts 'Book created successfully.'
    puts
  end

  def create_rental
    puts 'Select a book from the following list by number'
    @books.each_with_index do |book, index|
      puts "#{index}) Title: #{book.title}, Author: #{book.author}"
    end

    book_index = gets.chomp.to_i

    puts 'Select a person from the following list by number/index (not id)'
    puts
    @people.values.each_with_index do |person, index|
      puts "#{index}) [#{person.class}] ID: #{person.id}, Name: #{person.name}, Age: #{person.age}"
    end

    person_index = gets.chomp.to_i

    print 'Date: '
    rental_date = gets.chomp

    if valid_indices?(person_index, book_index)
      Rental.new(rental_date, @books[book_index], @people.values[person_index])
      puts 'Rental created successfully'
    else
      puts 'Invalid person or book selected.'
    end
  end

  def list_rentals
    puts
    print 'ID of person: '
    person_id = gets.chomp.to_i

    person_obj = @people.values.find { |person| person.id == person_id }

    if person_obj.nil?
      puts 'Person not found'
      return
    end

    puts 'Rentals:'
    person_obj.rentals.each do |rental|
      puts "Date: #{rental.date}, Book: #{rental.book.title} by #{rental.book.author}"
    end
    puts
  end

  private

  def valid_indices?(person_index, book_index)
    person_index >= 0 && person_index < @people.length && book_index >= 0 && book_index < @books.length
  end
end

# Base class for nameable objects
class Nameable
  def correct_name
    raise NotImplementedError, "#{self.class} has not implemented the 'correct_name' method."
  end
end

# Decorator pattern base class
class Decorator < Nameable
  def initialize(nameable)
    super()
    @nameable = nameable
  end

  def correct_name
    @nameable.correct_name
  end
end

# Decorator that trims names to 10 characters
class TrimmerDecorator < Decorator
  def correct_name
    super[0...10]
  end
end

# Decorator that capitalizes names
class CapitalizeDecorator < Decorator
  def correct_name
    nameable_name = @nameable.respond_to?(:correct_name) ? @nameable.correct_name : @nameable
    nameable_name.to_s.capitalize
  end
end

# Represents a book rental transaction
class Rental
  attr_accessor :date, :book, :person

  def initialize(date, book, person)
    @date = date
    @book = book
    @person = person
    book.rentals << self
    person.rentals << self
  end
end

# Represents a book in the library
class Book
  attr_accessor :rentals, :title, :author

  def initialize(title, author)
    @title = title
    @author = author
    @rentals = []
  end

  def add_rental(date, person)
    Rental.new(date, person, self)
  end
end

# Represents a classroom
class Classroom
  attr_accessor :label, :students

  def initialize(label)
    super()
    @label = label
    @students = []
  end

  def add_student(student)
    @students << student
    student.classroom = self
  end
end

# Base person class
class Person < Nameable
  @id_counter = 0

  attr_accessor :id, :name, :age, :rentals

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    super()
    @id = generate_id
    @name = name
    @age = age
    @parent_permission = parent_permission
    @rentals = []
  end

  def can_use_services?
    of_age? || @parent_permission
  end

  def correct_name
    @name
  end

  def add_rental(date, book)
    Rental.new(date, book, self)
  end

  private

  def of_age?
    @age.to_i >= 18
  end

  def generate_id
    self.class.instance_variable_get(:@id_counter) || self.class.instance_variable_set(:@id_counter, 0)
    self.class.instance_variable_set(:@id_counter, self.class.instance_variable_get(:@id_counter) + 1)
  end
end

# Student class inheriting from Person
class Student < Person
  attr_reader :classroom

  def initialize(age, classroom, name, parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @classroom = classroom
  end

  def play_hooky
    '¯\(ツ)/¯'
  end

  def classroom=(classroom)
    @classroom = classroom
    classroom.students.push(self) unless classroom.students.include?(self)
  end
end

# Teacher class inheriting from Person
class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name = 'Unknown')
    super(name, age)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end
