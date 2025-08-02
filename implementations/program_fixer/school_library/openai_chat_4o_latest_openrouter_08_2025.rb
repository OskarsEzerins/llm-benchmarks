require 'date'

class App
  def initialize
    @books = []
    @people = []
    @rentals = []
  end

  def list_books
    if @books.empty?
      puts 'No books available'
    else
      @books.each do |bk|
        puts "Title: #{bk.title}, Author: #{bk.author}"
      end
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

  def create_person
    print 'Do you want to create a student (1) or a teacher (2)? [Input the number]: '
    choice = gets.chomp
    case choice
    when '1'
      create_student
    when '2'
      create_teacher
    else
      puts 'Invalid selection'
    end
  end

  def create_student
    print 'Name: '
    name = gets.chomp
    name = 'Unknown' if name.nil? || name.strip.empty?

    age = nil
    loop do
      print 'Age: '
      input = gets.chomp
      if input =~ /^\d+$/ && input.to_i >= 0
        age = input.to_i
        break
      else
        puts 'Invalid age. Please enter a non-negative integer.'
      end
    end

    permission = nil
    loop do
      print 'Has parent permission? [Y/N]: '
      input = gets.chomp.strip.upcase
      if %w[Y N].include?(input)
        permission = input == 'Y'
        break
      else
        puts 'Please enter Y or N.'
      end
    end

    student = Student.new(age, nil, name, parent_permission: permission)
    @people << student
    puts 'Student created successfully.'
  end

  def create_teacher
    print 'Name: '
    name = gets.chomp
    name = 'Unknown' if name.nil? || name.strip.empty?

    age = nil
    loop do
      print 'Age: '
      input = gets.chomp
      if input =~ /^\d+$/ && input.to_i >= 0
        age = input.to_i
        break
      else
        puts 'Invalid age. Please enter a non-negative integer.'
      end
    end

    print 'Specialization: '
    specialization = gets.chomp
    specialization = 'General' if specialization.nil? || specialization.strip.empty?

    teacher = Teacher.new(name, specialization, age)
    @people << teacher
    puts 'Teacher created successfully.'
  end

  def create_book
    print 'Title: '
    title = gets.chomp
    title = 'Unknown' if title.nil? || title.strip.empty?

    print 'Author: '
    author = gets.chomp
    author = 'Unknown' if author.nil? || author.strip.empty?

    book = Book.new(title, author)
    @books << book
    puts 'Book created successfully.'
  end

  def create_rental
    if @books.empty?
      puts 'No books available.'
      return
    end

    if @people.empty?
      puts 'No people available.'
      return
    end

    puts 'Select a book from the following list by number:'
    @books.each_with_index { |b, i| puts "#{i}) Title: #{b.title}, Author: #{b.author}" }

    book_index = nil
    loop do
      input = gets.chomp
      if input =~ /^\d+$/ && input.to_i.between?(0, @books.length - 1)
        book_index = input.to_i
        break
      else
        puts 'Invalid selection. Try again.'
      end
    end

    puts 'Select a person from the following list by number (not id):'
    @people.each_with_index do |p, i|
      puts "#{i}) [#{p.class}] Name: #{p.name}, ID: #{p.id}, Age: #{p.age}"
    end

    person_index = nil
    loop do
      input = gets.chomp
      if input =~ /^\d+$/ && input.to_i.between?(0, @people.length - 1)
        person_index = input.to_i
        break
      else
        puts 'Invalid selection. Try again.'
      end
    end

    print 'Date (YYYY-MM-DD): '
    date_input = gets.chomp
    date = Date.parse(date_input) rescue Date.today

    rental = Rental.new(date, @books[book_index], @people[person_index])
    @rentals << rental
    puts 'Rental created successfully.'
  end

  def list_rentals
    print 'ID of person: '
    id_input = gets.chomp
    id = id_input.to_i
    person = @people.find { |p| p.id == id }

    if person.nil?
      puts 'Person not found.'
    elsif person.rentals.empty?
      puts 'No rentals found for this person.'
    else
      puts 'Rentals:'
      person.rentals.each do |r|
        puts "#{r.date} - Book: #{r.book.title} by #{r.book.author}"
      end
    end
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, 'Subclasses must implement correct_name'
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
    super.capitalize
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
    @id = rand(1..1000)
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
    super(name, age, parent_permission: parent_permission)
    self.classroom = classroom unless classroom.nil?
  end

  def play_hooky
    '¯(ツ)/¯'
  end

  def classroom=(room)
    @classroom = room
    room.add_student(self) unless room.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(name, specialization, age = 0)
    super(name, age, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end