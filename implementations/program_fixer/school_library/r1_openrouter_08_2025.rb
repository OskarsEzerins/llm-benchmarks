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
    print 'Student (1) or Teacher (2)? '
    choice = gets.chomp
    case choice
    when '1'
      create_student
    when '2'
      create_teacher
    else
      puts 'Invalid option.'
    end
  end

  def create_student
    print 'Name: '
    name = gets.chomp
    print 'Age: '
    age = gets.chomp.to_i
    print 'Parent permission? (Y/N) '
    parent_permission = gets.chomp.upcase == 'Y'

    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
    puts 'Student created successfully.'
  rescue => e
    puts "Error creating student: #{e}"
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
    puts 'Teacher created successfully.'
  rescue => e
    puts "Error creating teacher: #{e}"
  end

  def create_book
    print 'Title: '
    title = gets.chomp
    print 'Author: '
    author = gets.chomp

    @books << Book.new(title, author)
    puts 'Book created successfully.'
  rescue => e
    puts "Error creating book: #{e}"
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'Books or people list is empty.'
      return
    end

    puts 'Select a book:'
    @books.each_with_index { |book, index| puts "#{index}: #{book.title}" }
    book_index = gets.chomp.to_i

    puts 'Select a person:'
    @people.each_with_index { |person, index| puts "#{index}: #{person.name}" }
    person_index = gets.chomp.to_i

    if book_index.between?(0, @books.size - 1) && person_index.between?(0, @people.size - 1)
      date = Date.today
      Rental.new(date, @books[book_index], @people[person_index])
      puts 'Rental created successfully.'
    else
      puts 'Invalid selection.'
    end
  rescue => e
    puts "Error creating rental: #{e}"
  end

  def list_rentals
    print 'Enter person ID: '
    person_id = gets.chomp.to_i
    person = @people.find { |p| p.id == person_id }

    if person.nil?
      puts 'Person not found.'
      return
    end

    if person.rentals.empty?
      puts 'No rentals found.'
      return
    end

    person.rentals.each do |rental|
      puts "Date: #{rental.date}, Book: #{rental.book.title}"
    end
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
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
    name = @nameable.correct_name
    name.length > 10 ? name[0..9] : name
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
end

class Classroom
  attr_accessor :label, :students

  def initialize(label)
    @label = label
    @students = []
  end

  def add_student(student)
    return if @students.include?(student)

    @students << student
    student.classroom = self
  end
end

class Person < Nameable
  attr_reader :id, :name, :age, :rentals, :parent_permission

  def initialize(name, age, parent_permission: true)
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

  def classroom=(classroom)
    @classroom = classroom
    classroom.students << self unless classroom.students.include?(self)
  end

  def play_hooky
    '╰(°▽°)╯'
  end
end

class Teacher < Person
  attr_reader :specialization

  def initialize(age, specialization, name)
    super(name, age, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end