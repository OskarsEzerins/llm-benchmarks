require 'date'

# Nameable base class
class Nameable
  def correct_name
    raise NotImplementedError, "#{self.class} has not implemented method 'correct_name'"
  end
end

# Decorator base class
class Decorator < Nameable
  def initialize(nameable)
    super()
    @nameable = nameable
  end

  def correct_name
    @nameable.correct_name
  end
end

# TrimmerDecorator limits names to 10 characters
class TrimmerDecorator < Decorator
  def correct_name
    name = super
    name.length > 10 ? name[0, 10] : name
  end
end

# CapitalizeDecorator capitalizes names
class CapitalizeDecorator < Decorator
  def correct_name
    super.capitalize
  end
end

# Rental class links book and person with a date
class Rental
  attr_reader :date, :book, :person

  def initialize(date, book, person)
    @date = date
    @book = book
    @person = person
    book.rentals << self
    person.rentals << self
  end
end

# Book class
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

# Classroom class
class Classroom
  attr_accessor :label
  attr_reader :students

  def initialize(label)
    @label = label
    @students = []
  end

  def add_student(student)
    @students << student unless @students.include?(student)
    student.assign_classroom(self)
  end
end

# Person base class
class Person < Nameable
  attr_reader :id, :rentals
  attr_accessor :name, :age

  def initialize(age, name = 'Unknown', parent_permission: true)
    super()
    @id = rand(1000)
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

  def add_rental(book, date)
    Rental.new(date, book, self)
  end

  private

  def of_age?
    @age >= 18
  end
end

# Student class
class Student < Person
  attr_reader :classroom

  def initialize(age, classroom, name = 'Unknown', parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom if classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    @classroom = room
    room.students << self unless room.students.include?(self)
  end

  # Internal method used by Classroom#add_student
  def assign_classroom(room)
    @classroom = room
  end
end

# Teacher class
class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name = 'Unknown')
    super(age, name)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end

# Main application
class App
  def initialize
    @books = []
    @people = []
  end

  def list_books
    if @books.empty?
      puts 'No books available'
    else
      @books.each do |book|
        puts "Title: #{book.title}, Author: #{book.author}"
      end
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
    else
      @people.each do |person|
        puts "[#{person.class}] ID: #{person.id}, Name: #{person.name}, Age: #{person.age}"
      end
    end
  end

  def create_person
    print 'Student(3) or Teacher(1)? '
    choice = gets.chomp
    case choice
    when '1'
      create_teacher
    when '3'
      create_student
    else
      puts 'Invalid option. Please enter 1 for Teacher or 3 for Student.'
    end
  end

  def create_student
    print 'Name: '
    name = gets.chomp
    print 'Age: '
    age = gets.to_i
    print 'Parent permission? (Y/N): '
    perm_input = gets.chomp.upcase
    parent_permission = perm_input == 'Y'
    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
    puts 'Student created successfully.'
  end

  def create_teacher
    print 'Name: '
    name = gets.chomp
    print 'Age: '
    age = gets.to_i
    print 'Specialization: '
    specialization = gets.chomp
    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    puts 'Teacher created successfully.'
  end

  def create_book
    print 'Title: '
    title = gets.chomp
    print 'Author: '
    author = gets.chomp
    @books << Book.new(title, author)
    puts 'Book created successfully.'
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'Not enough books or people to create a rental.'
      return
    end

    puts 'Select a book by number:'
    @books.each_with_index { |b, i| puts "#{i}) #{b.title} by #{b.author}" }
    print 'Book number: '
    book_index = gets.to_i
    unless valid_book_index?(book_index)
      puts 'Invalid book selection.'
      return
    end

    puts 'Select a person by number:'
    @people.each_with_index { |p, i| puts "#{i}) [#{p.class}] #{p.name} (ID: #{p.id})" }
    print 'Person number: '
    person_index = gets.to_i
    unless valid_person_index?(person_index)
      puts 'Invalid person selection.'
      return
    end

    book = @books[book_index]
    person = @people[person_index]
    Rental.new(Date.today, book, person)
    puts 'Rental created successfully.'
  end

  def list_rentals
    print 'ID of person: '
    id = gets.to_i
    person = @people.find { |p| p.id == id }
    if person.nil?
      puts 'Person not found.'
      return
    end
    puts "Rentals for #{person.name}:"
    person.rentals.each do |rental|
      puts "#{rental.date} - #{rental.book.title} by #{rental.book.author}"
    end
  end

  private

  def valid_book_index?(index)
    index >= 0 && index < @books.length
  end

  def valid_person_index?(index)
    index >= 0 && index < @people.length
  end
end