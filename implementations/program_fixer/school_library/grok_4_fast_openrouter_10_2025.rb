require 'date'

class Nameable
  def correct_name
    raise NotImplementedError, 'Subclasses must implement correct_name'
  end
end

class BaseDecorator < Nameable
  attr_reader :nameable

  def initialize(nameable)
    @nameable = nameable
  end

  def correct_name
    nameable.correct_name
  end
end

class CapitalizeDecorator < BaseDecorator
  def correct_name
    super.capitalize
  end
end

class TrimmerDecorator < BaseDecorator
  def correct_name
    name = super
    name.length > 10 ? name[0, 10] : name
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
  attr_reader :title, :author, :rentals

  def initialize(title, author)
    @title = title
    @author = author
    @rentals = []
  end
end

class Classroom
  attr_accessor :label, :students

  def initialize(label)
    @label = label
    @students = []
  end

  def add_student(student)
    @students << student unless @students.include?(student)
    student.classroom = self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals, :parent_permission

  def initialize(age, name = 'Unknown', parent_permission: false)
    @id = rand(1..1000)
    @name = name
    @age = age
    @parent_permission = parent_permission
    @rentals = []
  end

  def correct_name
    @name
  end

  def can_use_services?
    @age >= 18 || @parent_permission
  end

  def add_rental(book, date)
    Rental.new(date, book, self)
  end
end

class Student < Person
  attr_reader :classroom

  def initialize(age, classroom = nil, name, parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    @classroom = classroom
  end

  def classroom=(room)
    @classroom = room
    room.students << self unless room.students.include?(self)
  end

  def play_hooky
    '╰(°▽°)╯'
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name, parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end

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
    print 'Do you want to create a student (1) or a teacher (2)? [Input the number]: '
    choice = gets.chomp
    case choice
    when '1'
      create_student
    when '2'
      create_teacher
    else
      puts 'Invalid choice. Please enter 1 or 2.'
    end
  end

  def create_student
    print 'Enter the age: '
    age_input = gets.chomp.to_i
    age = age_input < 0 ? 0 : age_input
    print 'Enter the name: '
    name = gets.chomp
    name = 'Unknown' if name.empty?
    print 'Has parent permission? [Y/N]: '
    perm = gets.chomp.downcase
    parent_permission = perm == 'y'
    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
    puts "Student '#{name}' created successfully."
  end

  def create_teacher
    print 'Enter the age: '
    age_input = gets.chomp.to_i
    age = age_input < 0 ? 0 : age_input
    print 'Enter the specialization: '
    specialization = gets.chomp
    print 'Enter the name: '
    name = gets.chomp
    name = 'Unknown' if name.empty?
    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    puts "Teacher '#{name}' created successfully."
  end

  def create_book
    print 'Enter the title: '
    title = gets.chomp
    title = 'Unknown' if title.empty?
    print 'Enter the author: '
    author = gets.chomp
    author = 'Unknown' if author.empty?
    book = Book.new(title, author)
    @books << book
    puts "Book '#{title}' created successfully."
  end

  def create_rental
    if @books.empty?
      puts 'No books available. Please add a book first.'
      return
    end
    if @people.empty?
      puts 'No people available. Please add a person first.'
      return
    end

    puts 'Select a book from the following list:'
    @books.each_with_index do |book, index|
      puts "#{index}) \"#{book.title}\" by #{book.author}"
    end
    print 'Enter book index: '
    book_index = gets.chomp.to_i
    if book_index < 0 || book_index >= @books.length
      puts 'Invalid book selection.'
      return
    end

    puts 'Select a person from the following list:'
    @people.each_with_index do |person, index|
      puts "#{index}) [#{person.class}] Name: #{person.name}, ID: #{person.id}, Age: #{person.age}"
    end
    print 'Enter person index: '
    person_index = gets.chomp.to_i
    if person_index < 0 || person_index >= @people.length
      puts 'Invalid person selection.'
      return
    end

    print 'Enter rental date (YYYY-MM-DD): '
    rental_date = gets.chomp
    rental_date = Date.today.to_s if rental_date.empty?
    rental = Rental.new(rental_date, @books[book_index], @people[person_index])
    puts "Rental created successfully for #{@people[person_index].name} on #{rental_date}."
  end

  def list_rentals
    print 'Enter person ID: '
    pid = gets.chomp.to_i
    person = @people.find { |p| p.id == pid }
    if person.nil?
      puts "Person with ID #{pid} not found."
      return
    end
    if person.rentals.empty?
      puts 'No rentals found for this person.'
      return
    end
    puts 'Rentals:'
    person.rentals.each do |rental|
      puts "#{rental.date} - #{rental.book.title}"
    end
  end
end