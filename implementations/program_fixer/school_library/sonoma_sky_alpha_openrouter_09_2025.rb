require 'date'

class Nameable
  def correct_name
    raise NotImplementedError, 'Subclasses must implement correct_name'
  end
end

class Decorator
  def initialize(nameable)
    @nameable = nameable
  end

  def correct_name
    @nameable.correct_name
  end
end

class TrimmerDecorator < Decorator
  def correct_name
    name = super
    name.length > 10 ? name[0, 10] : name
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    @nameable.correct_name.capitalize
  end
end

class Rental
  attr_reader :date, :book, :person

  def initialize(date, book, person)
    @date = date
    @book = book
    @person = person
    @book.rentals << self
    @person.rentals << self
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
  attr_accessor :id, :name, :age, :rentals, :parent_permission
  attr_reader :parent_permission

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
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
    of_age? || @parent_permission
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
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    @classroom = room
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
      puts 'Invalid selection'
    end
  end

  def create_student
    print 'Name: '
    name = gets.chomp
    name = 'Unknown' if name.nil? || name.empty?

    print 'Age: '
    age_input = gets.chomp
    age = age_input.to_i
    age = 0 if age < 0 || age_input != age.to_s

    print 'Has parent permission? [Y/N]: '
    perm_input = gets.chomp.upcase
    parent_permission = perm_input == 'Y'

    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
    puts 'Student created successfully'
  end

  def create_teacher
    print 'Name: '
    name = gets.chomp
    name = 'Unknown' if name.nil? || name.empty?

    print 'Age: '
    age_input = gets.chomp
    age = age_input.to_i
    age = 0 if age < 0 || age_input != age.to_s

    print 'Specialization: '
    specialization = gets.chomp
    specialization = 'Unknown' if specialization.nil? || specialization.empty?

    teacher = Teacher.new(name, specialization, age)
    @people << teacher
    puts 'Teacher created successfully'
  end

  def create_book
    print 'Title: '
    title = gets.chomp
    title = 'Unknown' if title.nil? || title.empty?

    print 'Author: '
    author = gets.chomp
    author = 'Unknown' if author.nil? || author.empty?

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
    @books.each_with_index { |book, i| puts "#{i}) #{book.title} by #{book.author}" }
    print 'Book index: '
    book_index = gets.chomp.to_i
    if book_index < 0 || book_index >= @books.length
      puts 'Invalid book index'
      return
    end

    puts 'Select a person from the following list by number (not id)'
    @people.each_with_index { |person, i| puts "#{i}) #{person.name} (#{person.class})" }
    print 'Person index: '
    person_index = gets.chomp.to_i
    if person_index < 0 || person_index >= @people.length
      puts 'Invalid person index'
      return
    end

    print 'Date (YYYY-MM-DD): '
    rental_date = gets.chomp
    if rental_date !~ /\A\d{4}-\d{2}-\d{2}\z/
      puts 'Invalid date format'
      return
    end

    Rental.new(rental_date, @books[book_index], @people[person_index])
    puts 'Rental created successfully'
  end

  def list_rentals
    print 'ID of person: '
    person_id = gets.chomp.to_i
    person = @people.find { |p| p.id == person_id }
    if person.nil?
      puts 'Person not found'
      return
    end

    if person.rentals.empty?
      puts 'No rentals for this person'
      return
    end

    puts "Rentals for #{person.name}:"
    person.rentals.each do |rental|
      puts "#{rental.date} - #{rental.book.title}"
    end
  end
end