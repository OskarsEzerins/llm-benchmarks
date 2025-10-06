require 'date'

class App
  def initialize
    @books = []
    @people = []
  end

  def list_books
    puts 'No books available' if @books.empty?
    @books.each do |bk|
      puts "Title: #{bk.title}, Author: #{bk.author}"
    end
  end

  def list_people
    puts 'No one has registered' if @people.empty?
    @people.each do |human|
      puts "[#{human.class}] ID: #{human.id}, Name: #{human.name}, Age: #{human.age}"
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
      puts 'Invalid option. Please select 1 for student or 2 for teacher.'
    end
  end

  def create_student
    print 'Name: '
    name = gets.chomp
    print 'Age: '
    age_input = gets.chomp
    age = age_input.to_i

    unless age_input.match?(/^\d+$/) && age >= 0
      puts 'Invalid age. Please enter a non-negative integer.'
      return
    end

    parent_permission = true
    loop do
      print 'Has parent permission? [Y/N]: '
      perm = gets.chomp.upcase
      if perm == 'Y'
        parent_permission = true
        break
      elsif perm == 'N'
        parent_permission = false
        break
      else
        puts 'Invalid input. Please enter Y or N.'
      end
    end

    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
    puts "Student created successfully with ID: #{student.id}"
  end

  def create_teacher
    print 'Name: '
    name = gets.chomp
    print 'Age: '
    age_input = gets.chomp
    age = age_input.to_i

    unless age_input.match?(/^\d+$/) && age >= 0
      puts 'Invalid age. Please enter a non-negative integer.'
      return
    end

    print 'Specialization: '
    specialization = gets.chomp

    teacher = Teacher.new(name, specialization, age)
    @people << teacher
    puts "Teacher created successfully with ID: #{teacher.id}"
  end

  def create_book
    print 'Title: '
    title = gets.chomp
    print 'Author: '
    author = gets.chomp

    book = Book.new(title, author)
    @books << book
    puts 'Book created successfully'
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

    puts 'Select a book from the following list by number'
    @books.each_with_index { |book, index| puts "#{index}) Title: \"#{book.title}\", Author: #{book.author}" }
    book_index = gets.chomp.to_i

    unless valid_book_index?(book_index)
      puts 'Invalid book index'
      return
    end

    puts 'Select a person from the following list by number (not ID)'
    @people.each_with_index { |person, index| puts "#{index}) [#{person.class}] Name: #{person.name}, ID: #{person.id}, Age: #{person.age}" }
    person_index = gets.chomp.to_i

    unless valid_person_index?(person_index)
      puts 'Invalid person index'
      return
    end

    print 'Date (YYYY-MM-DD): '
    date_input = gets.chomp

    begin
      date = Date.parse(date_input)
    rescue ArgumentError
      puts 'Invalid date format. Please use YYYY-MM-DD.'
      return
    end

    rental = Rental.new(date, @books[book_index], @people[person_index])
    puts 'Rental created successfully'
  end

  def list_rentals
    print 'ID of person: '
    id_input = gets.chomp
    id = id_input.to_i

    unless id_input.match?(/^\d+$/)
      puts 'Invalid ID format. Please enter a number.'
      return
    end

    person = @people.find { |p| p.id == id }

    if person.nil?
      puts 'Person not found'
      return
    end

    if person.rentals.empty?
      puts 'No rentals found for this person'
      return
    end

    person.rentals.each do |rental|
      puts "Date: #{rental.date}, Book: \"#{rental.book.title}\" by #{rental.book.author}"
    end
  end

  private

  def valid_person_index?(index)
    index >= 0 && index < @people.length
  end

  def valid_book_index?(index)
    index >= 0 && index < @books.length
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, 'Subclasses must implement correct_name method'
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
    super[0, 10]
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    super.capitalize
  end
end

class Rental
  attr_accessor :date, :book, :person

  def initialize(date, book, person)
    @date = date
    @book = book
    @person = person

    book.rentals << self unless book.rentals.include?(self)
    person.rentals << self unless person.rentals.include?(self)
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
    return if students.include?(student)
    @students << student
    student.classroom = self
  end
end

class Person < Nameable
  attr_accessor :name, :age, :rentals
  attr_reader :id

  def initialize(age, name = 'Unknown', parent_permission: true)
    super()
    @id = Random.rand(1..1000)
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
    super(age, name, parent_permission: parent_permission)
    @classroom = classroom
  end

  def play_hooky
    '¯\(ツ)/¯'
  end

  def classroom=(classroom)
    @classroom = classroom
    classroom.add_student(self) unless classroom.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(name, specialization, age)
    super(age, name, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end