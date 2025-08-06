require 'date'

# -------------------------- Decorators ---------------------------------

class Nameable
  def correct_name
    raise NotImplementedError, 'Subclasses must implement #correct_name'
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
    super[0, 10]
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    super.capitalize
  end
end

# --------------------------- Core Models --------------------------------

class Rental
  attr_reader :date, :book, :person

  def initialize(date, book, person)
    @date   = date
    @book   = book
    @person = person

    book.rentals << self
    person.rentals << self
  end
end

class Book
  attr_reader :title, :author, :rentals

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
    return if @students.include?(student)

    @students << student
    student.classroom = self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals, :parent_permission

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id                = rand(1..1000)
    @name              = name
    @age               = age
    @parent_permission = parent_permission
    @rentals           = []
  end

  def can_use_services?
    of_age? || parent_permission
  end

  def correct_name
    @name
  end

  private

  def of_age?
    @age >= 18
  end
end

class Student < Person
  attr_accessor :classroom

  def initialize(age, classroom = nil, name = 'Unknown', parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom unless classroom.nil?
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    @classroom = room
    room.add_student(self) unless room.nil? || room.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, name, specialization = 'Unknown')
    super(name, age, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end

# ------------------------------ App -------------------------------------

class App
  def initialize
    @books  = []
    @people = []
  end

  # ---- Listing ---------------------------------------------------------

  def list_books
    if @books.empty?
      puts 'No books available'
    else
      @books.each { |bk| puts "Title: #{bk.title}, Author: #{bk.author}" }
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
    else
      @people.each do |human|
        puts "[#{human.class}] ID: #{human.id}, Name: #{human.name}, Age: #{human.age}"
      end
    end
  end

  def list_rentals
    print 'ID of person: '
    pid = gets.chomp.to_i
    person = @people.find { |p| p.id == pid }

    if person.nil? || person.rentals.empty?
      puts 'No rentals found for this person'
    else
      person.rentals.each do |r|
        puts "#{r.date} - #{r.book.title}"
      end
    end
  end

  # ---- Creation ---------------------------------------------------------

  def create_person
    loop do
      print 'Create a Teacher (1) or Student (2)? '
      choice = gets.chomp
      case choice
      when '1'
        create_teacher
        break
      when '2'
        create_student
        break
      else
        puts 'Invalid option, please enter 1 or 2.'
      end
    end
  end

  def create_student
    print 'Name: '
    name = gets.chomp
    age = read_positive_integer('Age')
    parent_permission = read_yes_no('Parent permission? [Y/N]')

    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
    puts 'Student created successfully.'
  end

  def create_teacher
    print 'Name: '
    name = gets.chomp
    age = read_positive_integer('Age')
    print 'Specialization: '
    specialization = gets.chomp

    teacher = Teacher.new(age, name, specialization)
    @people << teacher
    puts 'Teacher created successfully.'
  end

  def create_book
    print 'Title: '
    title = gets.chomp
    print 'Author: '
    author = gets.chomp

    book = Book.new(title, author)
    @books << book
    puts 'Book created successfully.'
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'You need at least one book and one person to create a rental.'
      return
    end

    puts 'Select a book from the following list by number'
    @books.each_with_index { |b, i| puts "#{i}) Title: \"#{b.title}\", Author: #{b.author}" }
    book_index = read_index('Book index', @books.size)

    puts 'Select a person from the following list by number (not ID)'
    @people.each_with_index { |p, i| puts "#{i}) [#{p.class}] Name: #{p.name}, ID: #{p.id}" }
    person_index = read_index('Person index', @people.size)

    print 'Date (YYYY-MM-DD): '
    date_input = gets.chomp
    date = date_input.empty? ? Date.today.to_s : date_input

    Rental.new(date, @books[book_index], @people[person_index])
    puts 'Rental created successfully.'
  end

  # ---- Helpers ----------------------------------------------------------

  private

  def read_positive_integer(prompt)
    loop do
      print "#{prompt}: "
      input = gets.chomp
      if input =~ /^\d+$/ && input.to_i > 0
        return input.to_i
      else
        puts 'Please enter a valid positive integer.'
      end
    end
  end

  def read_yes_no(prompt)
    loop do
      print "#{prompt} "
      answer = gets.chomp.upcase
      return true if answer == 'Y'
      return false if answer == 'N'

      puts 'Please answer with Y or N.'
    end
  end

  def read_index(prompt, size)
    loop do
      print "#{prompt}: "
      idx = gets.chomp.to_i
      return idx if idx >= 0 && idx < size

      puts "Please enter a number between 0 and #{size - 1}."
    end
  end
end