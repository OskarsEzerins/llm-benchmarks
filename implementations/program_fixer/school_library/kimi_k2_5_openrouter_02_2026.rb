require 'date'

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

class CapitalizeDecorator < Decorator
  def correct_name
    @nameable.correct_name.capitalize
  end
end

class TrimmerDecorator < Decorator
  def correct_name
    @nameable.correct_name[0..9]
  end
end

class Person < Nameable
  attr_reader :id, :parent_permission
  attr_accessor :name, :age, :rentals

  def initialize(age, name = 'Unknown', parent_permission: true)
    super()
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

  def initialize(age, classroom, name = 'Unknown', parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    @classroom = classroom
    classroom.add_student(self) if classroom
  end

  def classroom=(room)
    return if @classroom == room

    @classroom&.students&.delete(self)
    @classroom = room
    room.students << self unless room.students.include?(self)
  end

  def play_hooky
    '¯\(ツ)/¯'
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name = 'Unknown', parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    @specialization = specialization
  end

  def can_use_services?
    true
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
    return if @students.include?(student)

    @students << student
    student.instance_variable_set(:@classroom, self) unless student.classroom == self
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
    @books.each do |bk|
      puts "title: #{bk.title}, author: #{bk.author}"
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
      return
    end
    @people.each do |human|
      puts "[#{human.class}] id: #{human.id}, Name: #{human.name}, Age: #{human.age}"
    end
  end

  def create_person
    puts 'Do you want to create a student (1) or a teacher (2)? [Input the number]: '
    choice = gets.chomp

    case choice
    when '1'
      create_student
    when '2'
      create_teacher
    else
      puts 'Invalid option'
    end
  end

  def create_student
    print 'Age: '
    age_input = gets.chomp
    
    unless age_input.match?(/^\d+$/)
      puts 'Invalid age'
      return
    end
    
    age = age_input.to_i
    
    if age <= 0
      puts 'Invalid age'
      return
    end

    print 'Name: '
    name = gets.chomp
    name = 'Unknown' if name.nil? || name.empty?

    print 'Has parent permission? [Y/N]: '
    perm = gets.chomp.upcase
    
    parent_permission = case perm
                       when 'Y'
                         true
                       when 'N'
                         false
                       else
                         puts 'Invalid input, defaulting to true'
                         true
                       end

    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
    puts 'Student created successfully'
  end

  def create_teacher
    print 'Age: '
    age_input = gets.chomp
    
    unless age_input.match?(/^\d+$/)
      puts 'Invalid age'
      return
    end
    
    age = age_input.to_i
    
    if age <= 0
      puts 'Invalid age'
      return
    end

    print 'Name: '
    name = gets.chomp
    name = 'Unknown' if name.nil? || name.empty?

    print 'Specialization: '
    specialization = gets.chomp
    specialization = 'Unknown' if specialization.nil? || specialization.empty?

    teacher = Teacher.new(age, specialization, name)
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
      puts 'No people available'
      return
    end

    puts 'Select a book from the following list by number'
    @books.each_with_index { |b, i| puts "#{i}) Title: #{b.title}, Author: #{b.author}" }
    
    bi = gets.chomp.to_i
    if bi < 0 || bi >= @books.length
      puts 'Invalid book selection'
      return
    end

    puts 'Select a person from the following list by number (not id)'
    @people.each_with_index { |p, i| puts "#{i}) [#{p.class}] Name: #{p.name}, ID: #{p.id}, Age: #{p.age}" }
    
    pi = gets.chomp.to_i
    if pi < 0 || pi >= @people.length
      puts 'Invalid person selection'
      return
    end

    print 'Date: '
    date = gets.chomp
    date = Date.today.to_s if date.nil? || date.empty?

    Rental.new(date, @books[bi], @people[pi])
    puts 'Rental created successfully'
  end

  def list_rentals
    print 'ID of person: '
    pid = gets.chomp.to_i

    person = @people.find { |p| p.id == pid }
    if person.nil?
      puts 'Person not found'
      return
    end

    if person.rentals.empty?
      puts 'No rentals found for this person'
      return
    end

    puts 'Rentals:'
    person.rentals.each { |r| puts "Date: #{r.date}, Book \"#{r.book.title}\" by #{r.book.author}" }
  end
end