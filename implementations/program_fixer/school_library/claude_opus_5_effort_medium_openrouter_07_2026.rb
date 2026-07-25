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

class TrimmerDecorator < Decorator
  def correct_name
    name = super.to_s
    name.length > 10 ? name[0, 10] : name
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    super.to_s.capitalize
  end
end

class Rental
  attr_accessor :date, :book, :person

  def initialize(date, book, person)
    @date = date
    @book = book
    @person = person
    book.rentals << self if book
    person.rentals << self if person
  end
end

class Book
  attr_accessor :title, :author
  attr_reader :rentals

  def initialize(title, author)
    @title = title
    @author = author
    @rentals = []
  end

  def add_rental(person, date)
    Rental.new(date, self, person)
  end
end

class Person < Nameable
  attr_accessor :name, :age
  attr_reader :id, :rentals, :parent_permission

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    super()
    @id = rand(1..1000)
    @name = name.nil? || name.to_s.empty? ? 'Unknown' : name.to_s
    @age = age.to_i
    @parent_permission = parent_permission ? true : false
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

class Student < Person
  attr_reader :classroom

  def initialize(age, classroom = nil, name = 'Unknown', parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom if classroom
  end

  def play_hooky
    '¯\(ツ)/¯'
  end

  def classroom=(room)
    @classroom = room
    return if room.nil?

    room.students << self unless room.students.include?(self)
  end

  alias assign_classroom classroom=
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization = nil, name = 'Unknown', parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end

class App
  attr_reader :books, :people

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
      puts "Title: #{bk.title}, Author: #{bk.author}"
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
      return
    end
    @people.each do |human|
      puts "[#{human.class}] ID: #{human.id}, Name: #{human.name}, Age: #{human.age}"
    end
  end

  def create_person
    print 'Do you want to create a student (1) or a teacher (2)? [Input the number]: '
    choice = gets&.chomp.to_s.strip.downcase
    case choice
    when '1', 'student'
      create_student
    when '2', 'teacher'
      create_teacher
    else
      puts 'Invalid selection, please try again'
      nil
    end
  end

  def create_student
    print 'Name: '
    name = read_name
    print 'Age: '
    age = read_age
    print 'Has parent permission? [Y/N]: '
    permission = read_permission
    student = Student.new(age, nil, name, parent_permission: permission)
    @people << student
    puts 'Person created successfully'
    student
  end

  def create_teacher
    print 'Name: '
    name = read_name
    print 'Age: '
    age = read_age
    print 'Specialization: '
    specialization = gets&.chomp.to_s
    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    puts 'Person created successfully'
    teacher
  end

  def create_book
    print 'Title: '
    title = gets&.chomp.to_s
    print 'Author: '
    author = gets&.chomp.to_s
    book = Book.new(title, author)
    @books << book
    puts 'Book created successfully'
    book
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'You need at least one book and one person to create a rental'
      return nil
    end

    puts 'Select a book from the following list by number'
    @books.each_with_index { |b, i| puts "#{i}) Title: #{b.title}, Author: #{b.author}" }
    book_index = gets.to_i

    puts 'Select a person from the following list by number (not id)'
    @people.each_with_index { |p, i| puts "#{i}) [#{p.class}] Name: #{p.name}, ID: #{p.id}, Age: #{p.age}" }
    person_index = gets.to_i

    unless valid_indices?(person_index, book_index)
      puts 'Invalid selection'
      return nil
    end

    print 'Date: '
    date = gets&.chomp.to_s
    date = Date.today.to_s if date.empty?

    rental = Rental.new(date, @books[book_index], @people[person_index])
    puts 'Rental created successfully'
    rental
  end

  def list_rentals
    print 'ID of person: '
    person_id = gets.to_i
    person = @people.find { |pr| pr.id == person_id }
    if person.nil?
      puts 'Person not found'
      return
    end
    puts 'Rentals:'
    person.rentals.each { |r| puts "Date: #{r.date}, Book \"#{r.book.title}\" by #{r.book.author}" }
  end

  private

  def read_name
    name = gets&.chomp.to_s.strip
    name.empty? ? 'Unknown' : name
  end

  def read_age
    input = gets&.chomp.to_s.strip
    age = input.to_i
    age.negative? ? 0 : age
  end

  def read_permission
    answer = gets&.chomp.to_s.strip.downcase
    case answer
    when 'y', 'yes' then true
    when 'n', 'no' then false
    else
      puts 'Invalid answer, assuming no parent permission'
      false
    end
  end

  def valid_indices?(person_index, book_index)
    return false if person_index.negative? || book_index.negative?

    person_index < @people.length && book_index < @books.length
  end
end