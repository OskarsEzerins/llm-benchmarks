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
        puts "title: #{book.title}, author: #{book.author}"
      end
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
    else
      @people.each do |person|
        puts "[#{person.class}] id: #{person.id}, Name: #{person.name}, Age: #{person.age}"
      end
    end
  end

  def create_person
    print 'Student(1) or Teacher(2)? '
    choice = gets.chomp
    case choice
    when '1' then create_student
    when '2' then create_teacher
    else puts 'Invalid option'
    end
  end

  def create_student
    print 'Name: '
    name = gets.chomp
    print 'Age: '
    age = gets.chomp.to_i
    print 'Parent permission? (Y/N): '
    permission = gets.chomp.upcase == 'Y'
    student = Student.new(age, nil, name, parent_permission: permission)
    @people << student
    puts 'Student created successfully'
  rescue ArgumentError => e
    puts "Error: #{e.message}"
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
  rescue ArgumentError => e
    puts "Error: #{e.message}"
  end

  def create_book
    print 'Title: '
    title = gets.chomp
    print 'Author: '
    author = gets.chomp
    @books << Book.new(title, author)
    puts 'Book created successfully'
  rescue ArgumentError => e
    puts "Error: #{e.message}"
  end

  def create_rental
    return puts 'No books available' if @books.empty?
    return puts 'No people available' if @people.empty?

    puts 'Select a book:'
    @books.each_with_index { |book, index| puts "#{index}: #{book.title}" }
    book_index = gets.chomp.to_i

    puts 'Select a person:'
    @people.each_with_index { |person, index| puts "#{index}: #{person.name}" }
    person_index = gets.chomp.to_i

    if valid_indices?(person_index, book_index)
      Rental.new(Date.today.to_s, @books[book_index], @people[person_index])
      puts 'Rental created successfully'
    else
      puts 'Invalid selection'
    end
  rescue ArgumentError => e
    puts "Error: #{e.message}"
  end

  def list_rentals
    print 'ID of person: '
    person_id = gets.chomp.to_i
    person = @people.find { |p| p.id == person_id }
    if person.nil?
      puts 'Person not found'
    elsif person.rentals.empty?
      puts 'No rentals found for this person'
    else
      person.rentals.each { |rental| puts "#{rental.date} - #{rental.book.title}" }
    end
  end

  private

  def valid_indices?(person_index, book_index)
    person_index.between?(0, @people.length - 1) && book_index.between?(0, @books.length - 1)
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, 'Subclasses must implement correct_name'
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
    @nameable.correct_name[0..9]
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
  attr_reader :id, :name, :age, :rentals
  attr_accessor :parent_permission

  def initialize(age, name = 'Unknown', parent_permission: true)
    super()
    @id = rand(1000..9999)
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
    super(age, name, parent_permission: parent_permission)
    @classroom = classroom
    classroom&.add_student(self)
  end

  def play_hooky
    '¯\\(ツ)/¯'
  end

  def classroom=(classroom)
    @classroom = classroom
    classroom.students << self unless classroom.students.include?(self)
  end
end

class Teacher < Person
  attr_reader :specialization

  def initialize(age, specialization, name = 'Unknown')
    super(age, name, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end