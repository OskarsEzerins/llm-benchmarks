require 'date'

class App
  def initialize
    @books = []
    @people = []
  end

  def list_books
    puts 'No books available' if @books.empty?
    @books.each do |book|
      puts "Title: #{book.title}, Author: #{book.author}"
    end
  end

  def list_people
    puts 'No people registered' if @people.empty?
    @people.each do |person|
      puts "[#{person.class.name}] ID: #{person.id}, Name: #{person.name}, Age: #{person.age}"
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
      puts 'Invalid choice'
    end
  end

  def create_student
    print 'Name: '
    name = gets.chomp
    print 'Age: '
    age = gets.chomp.to_i
    if age.negative? || !age.is_a?(Integer)
      puts 'Invalid age'
      return
    end
    print 'Parent permission? (Y/N): '
    permission_input = gets.chomp.upcase
    permission = permission_input == 'Y'
    student = Student.new(age, nil, name, parent_permission: permission)
    @people << student
  end

  def create_teacher
    print 'Name: '
    name = gets.chomp
    print 'Age: '
    age = gets.chomp.to_i
    if age.negative? || !age.is_a?(Integer)
      puts 'Invalid age'
      return
    end
    print 'Specialization: '
    specialization = gets.chomp
    teacher = Teacher.new(name, specialization, age)
    @people << teacher
  end

  def create_book
    print 'Title: '
    title = gets.chomp
    print 'Author: '
    author = gets.chomp
    book = Book.new(title, author)
    @books << book
  end

  def create_rental
    puts 'Select a book'
    @books.each_with_index do |book, index|
      puts "#{index}: #{book.title}"
    end
    book_index = gets.chomp.to_i
    puts 'Select a person'
    @people.each_with_index do |person, index|
      puts "#{index}: #{person.name}"
    end
    person_index = gets.chomp.to_i
    if valid_indices?(person_index, book_index)
      Rental.new(Date.today, @people[person_index], @books[book_index])
    else
      puts 'Invalid selection'
    end
  end

  def list_rentals
    print 'ID of person: '
    person_id = gets.chomp.to_i
    person = @people.detect { |p| p.id == person_id }
    if person
      person.rentals.each do |rental|
        puts "#{rental.date} - #{rental.book.title}"
      end
    else
      puts 'Person not found'
    end
  end

  private

  def valid_indices?(person_index, book_index)
    person_index >= 0 && person_index < @people.length && book_index >= 0 && book_index < @books.length
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, 'Subclass must implement correct_name'
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
    super()[0..9]
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    @nameable.correct_name.capitalize
  end
end

class Rental
  attr_reader :date, :book, :person

  def initialize(date, person, book)
    @date = date
    @person = person
    @book = book
    book.rentals << self
    person.rentals << self
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
    Rental.new(date, person, self)
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
    student.assign_classroom(self)
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id = rand(1000)
    @name = name
    @age = age.to_i
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
    Rental.new(date, self, book)
  end

  private

  def of_age?
    @age >= 18
  end
end

class Student < Person
  attr_reader :classroom

  def initialize(age, classroom, name, parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @classroom = classroom
  end

  def assign_classroom(room)
    return if @classroom == room

    if @classroom && @classroom.students.include?(self)
      @classroom.students.delete(self)
    end
    @classroom = room
  end

  def play_hooky
    '╰(°▽°)╯'
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(name, specialization, age = 0)
    super(name, age)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end