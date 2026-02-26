require 'date'

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
    choice = gets&.chomp

    case choice
    when '1'
      create_student
    when '2'
      create_teacher
    else
      puts 'Invalid option'
      nil
    end
  end

  def create_student
    print 'Name: '
    name = sanitize_name(gets&.chomp)

    print 'Age: '
    age = sanitize_age(gets&.chomp)

    permission = nil
    until [true, false].include?(permission)
      print 'Has parent permission? [Y/N]: '
      input = gets&.chomp&.strip&.upcase
      permission = true if input == 'Y'
      permission = false if input == 'N'
      puts 'Invalid input. Please enter Y or N.' if permission.nil?
    end

    student = Student.new(age, nil, name, parent_permission: permission)
    @people << student
    student
  end

  def create_teacher
    print 'Name: '
    name = sanitize_name(gets&.chomp)

    print 'Age: '
    age = sanitize_age(gets&.chomp)

    print 'Specialization: '
    specialization = gets&.chomp.to_s.strip
    specialization = 'Unknown' if specialization.empty?

    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    teacher
  end

  def create_book
    print 'Title: '
    title = gets&.chomp.to_s.strip
    title = 'Unknown' if title.empty?

    print 'Author: '
    author = gets&.chomp.to_s.strip
    author = 'Unknown' if author.empty?

    book = Book.new(title, author)
    @books << book
    book
  end

  def create_rental
    if @books.empty?
      puts 'No books available'
      return nil
    end

    if @people.empty?
      puts 'No people available'
      return nil
    end

    puts 'Select a book from the following list by number:'
    @books.each_with_index do |book, index|
      puts "#{index}) Title: #{book.title}, Author: #{book.author}"
    end
    book_index = gets&.chomp.to_i

    puts 'Select a person from the following list by number (not id):'
    @people.each_with_index do |person, index|
      puts "#{index}) [#{person.class}] Name: #{person.name}, ID: #{person.id}, Age: #{person.age}"
    end
    person_index = gets&.chomp.to_i

    unless valid_indices?(person_index, book_index)
      puts 'Invalid selection'
      return nil
    end

    print 'Date (YYYY-MM-DD): '
    date = gets&.chomp.to_s.strip
    date = Date.today.to_s if date.empty?

    Rental.new(date, @books[book_index], @people[person_index])
  end

  def list_rentals
    print 'ID of person: '
    person_id = gets&.chomp.to_i
    person = @people.find { |p| p.id == person_id }

    if person.nil?
      puts 'Person not found'
      return
    end

    if person.rentals.empty?
      puts 'No rentals for this person'
      return
    end

    person.rentals.each do |rental|
      puts "Date: #{rental.date}, Book: #{rental.book.title} by #{rental.book.author}"
    end
  end

  private

  def valid_indices?(person_index, book_index)
    person_index.is_a?(Integer) &&
      book_index.is_a?(Integer) &&
      person_index >= 0 &&
      book_index >= 0 &&
      person_index < @people.length &&
      book_index < @books.length
  end

  def sanitize_name(name)
    value = name.to_s.strip
    value.empty? ? 'Unknown' : value
  end

  def sanitize_age(age_input)
    age = Integer(age_input, exception: false)
    return 0 if age.nil? || age.negative?

    age
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, 'This method must be implemented by subclasses'
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

class Rental
  attr_reader :date, :book, :person

  def initialize(date, book, person)
    @date = date
    @book = book
    @person = person

    @book.rentals << self unless @book.rentals.include?(self)
    @person.rentals << self unless @person.rentals.include?(self)
  end
end

class Book
  attr_reader :title, :author, :rentals

  def initialize(title, author)
    @title = title.to_s
    @author = author.to_s
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
    return if @students.include?(student)

    @students << student
    student.classroom = self unless student.classroom == self
  end
end

class Person < Nameable
  attr_reader :id, :name, :age, :rentals
  attr_accessor :parent_permission

  def initialize(age, name = 'Unknown', parent_permission: true)
    @id = rand(1..1000)
    @name = name.to_s.strip
    @name = 'Unknown' if @name.empty?
    @age = age.is_a?(Integer) ? age : age.to_i
    @age = 0 if @age.negative?
    @parent_permission = !!parent_permission
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

  def initialize(age, classroom = nil, name = 'Unknown', parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom unless classroom.nil?
  end

  def play_hooky
    '¯\_(ツ)_/¯'
  end

  def classroom=(room)
    @classroom = room
    return if room.nil?
    return if room.students.include?(self)

    room.students << self
  end
end

class Teacher < Person
  attr_reader :specialization

  def initialize(age, specialization, name = 'Unknown')
    super(age, name, parent_permission: true)
    @specialization = specialization.to_s.strip
    @specialization = 'Unknown' if @specialization.empty?
  end

  def can_use_services?
    true
  end
end