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
        puts "Title: \"#{book.title}\", Author: #{book.author}"
      end
    end
  end

  def list_people
    if @people.empty?
      puts 'No people registered'
    else
      @people.each do |person|
        puts "[#{person.class}] ID: #{person.id}, Name: #{person.name}, Age: #{person.age}"
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
      puts 'Invalid choice. Please try again.'
    end
  end

  def create_student
    print 'Name: '
    name = gets.chomp
    print 'Age: '
    age = gets.chomp.to_i
    print 'Has parent permission? [Y/N]: '
    permission = gets.chomp.downcase == 'y'
    student = Student.new(age, nil, name, parent_permission: permission)
    @people << student
    puts 'Student created successfully'
  rescue StandardError => e
    puts "Error creating student: #{e.message}"
  end

  def create_teacher
    print 'Name: '
    name = gets.chomp
    print 'Age: '
    age = gets.chomp.to_i
    print 'Specialization: '
    specialization = gets.chomp
    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    puts 'Teacher created successfully'
  rescue StandardError => e
    puts "Error creating teacher: #{e.message}"
  end

  def create_book
    print 'Title: '
    title = gets.chomp
    print 'Author: '
    author = gets.chomp
    book = Book.new(title, author)
    @books << book
    puts 'Book created successfully'
  rescue StandardError => e
    puts "Error creating book: #{e.message}"
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'No books or people available to create a rental'
      return
    end

    puts 'Select a book from the following list by number:'
    @books.each_with_index { |book, index| puts "#{index}) Title: \"#{book.title}\", Author: #{book.author}" }
    book_index = gets.chomp.to_i

    puts 'Select a person from the following list by number (not ID):'
    @people.each_with_index { |person, index| puts "#{index}) [#{person.class}] Name: #{person.name}, ID: #{person.id}, Age: #{person.age}" }
    person_index = gets.chomp.to_i

    if valid_indices?(person_index, book_index)
      date = Date.today
      Rental.new(date, @books[book_index], @people[person_index])
      puts 'Rental created successfully'
    else
      puts 'Invalid selection. Please try again.'
    end
  rescue StandardError => e
    puts "Error creating rental: #{e.message}"
  end

  def list_rentals
    if @people.empty?
      puts 'No people available to list rentals'
      return
    end

    print 'Enter person ID: '
    person_id = gets.chomp.to_i
    person = @people.find { |p| p.id == person_id }

    if person
      if person.rentals.empty?
        puts 'No rentals found for this person'
      else
        puts "Rentals for #{person.name}:"
        person.rentals.each do |rental|
          puts "Date: #{rental.date}, Book: \"#{rental.book.title}\" by #{rental.book.author}"
        end
      end
    else
      puts 'Person not found'
    end
  rescue StandardError => e
    puts "Error listing rentals: #{e.message}"
  end

  private

  def valid_indices?(person_index, book_index)
    person_index.between?(0, @people.size - 1) && book_index.between?(0, @books.size - 1)
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end
end

class Decorator < Nameable
  def initialize(nameable)
    @nameable = nameable
    super()
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
  attr_reader :date, :book, :person

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
  attr_accessor :label
  attr_reader :students

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
  attr_reader :parent_permission

  def initialize(age, name = 'Unknown', parent_permission: true)
    @id = rand(1..1000)
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
  attr_accessor :classroom

  def initialize(age, classroom, name, parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    @classroom = classroom
  end

  def play_hooky
    '¯\(°_o)/¯'
  end

  def classroom=(classroom)
    @classroom = classroom
    classroom.students << self unless classroom.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name)
    super(age, name, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end