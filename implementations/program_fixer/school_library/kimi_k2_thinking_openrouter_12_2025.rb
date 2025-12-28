require 'date'

class Nameable
  def correct_name
    raise NotImplementedError, 'Subclasses must implement correct_name method'
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
    super[0..9]
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    @nameable.correct_name.capitalize
  end
end

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

class Book
  attr_accessor :title, :author, :rentals

  def initialize(title, author)
    @title = title
    @author = author
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
    @students << student unless @students.include?(student)
    student.classroom = self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
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

class Student < Person
  attr_reader :classroom

  def initialize(age, classroom, name, parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @classroom = classroom
    @classroom.add_student(self) if @classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    @classroom = room
    room.students << self unless room.students.include?(self)
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
      puts "Title: #{book.title}, Author: #{book.author}"
    end
  end

  def list_people
    if @people.empty?
      puts 'No people registered'
      return
    end
    @people.each do |person|
      puts "[#{person.class}] ID: #{person.id}, Name: #{person.name}, Age: #{person.age}"
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
      puts 'Invalid option'
    end
  end

  def create_student
    print 'Name: '
    name = gets.chomp
    if name.strip.empty?
      puts 'Name cannot be empty'
      return
    end

    print 'Age: '
    age = gets.to_i
    if age <= 0
      puts 'Age must be a positive integer'
      return
    end

    print 'Has parent permission? [Y/N]: '
    permission = gets.chomp.downcase
    parent_permission = permission == 'y'

    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
    puts 'Student created successfully'
  end

  def create_teacher
    print 'Name: '
    name = gets.chomp
    if name.strip.empty?
      puts 'Name cannot be empty'
      return
    end

    print 'Age: '
    age = gets.to_i
    if age <= 0
      puts 'Age must be a positive integer'
      return
    end

    print 'Specialization: '
    specialization = gets.chomp
    if specialization.strip.empty?
      puts 'Specialization cannot be empty'
      return
    end

    teacher = Teacher.new(name, specialization, age)
    @people << teacher
    puts 'Teacher created successfully'
  end

  def create_book
    print 'Title: '
    title = gets.chomp
    if title.strip.empty?
      puts 'Title cannot be empty'
      return
    end

    print 'Author: '
    author = gets.chomp
    if author.strip.empty?
      puts 'Author cannot be empty'
      return
    end

    book = Book.new(title, author)
    @books << book
    puts 'Book created successfully'
  end

  def create_rental
    if @books.empty?
      puts 'No books available to rent'
      return
    end

    if @people.empty?
      puts 'No people registered to rent to'
      return
    end

    puts 'Select a book from the following list by number'
    @books.each_with_index do |book, index|
      puts "#{index}) Title: #{book.title}, Author: #{book.author}"
    end

    book_index = gets.to_i
    if book_index < 0 || book_index >= @books.length
      puts 'Invalid book index'
      return
    end

    puts 'Select a person from the following list by number (not ID)'
    @people.each_with_index do |person, index|
      puts "#{index}) [#{person.class}] Name: #{person.name}, ID: #{person.id}, Age: #{person.age}"
    end

    person_index = gets.to_i
    if person_index < 0 || person_index >= @people.length
      puts 'Invalid person index'
      return
    end

    print 'Date (YYYY-MM-DD): '
    date = gets.chomp

    book = @books[book_index]
    person = @people[person_index]

    Rental.new(date, book, person)
    puts 'Rental created successfully'
  end

  def list_rentals
    print 'ID of person: '
    person_id = gets.to_i

    person = @people.find { |p| p.id == person_id }
    unless person
      puts "Person with ID #{person_id} not found"
      return
    end

    rentals = person.rentals
    if rentals.empty?
      puts 'No rentals found for this person'
      return
    end

    rentals.each do |rental|
      puts "Date: #{rental.date}, Book: \"#{rental.book.title}\" by #{rental.book.author}"
    end
  end

  private

  def valid_indices?(person_index, book_index)
    person_index < @people.length && book_index < @books.length
  end
end