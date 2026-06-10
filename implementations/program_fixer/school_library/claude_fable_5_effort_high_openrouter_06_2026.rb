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
    super[0..9]
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    super.capitalize
  end
end

class Person < Nameable
  attr_accessor :name, :age, :rentals
  attr_reader :id

  def initialize(age = 0, name = 'Unknown', parent_permission: true)
    super()
    @id = rand(1..1000)
    @name = name.nil? || name.to_s.strip.empty? ? 'Unknown' : name.to_s
    @age = age.to_i.negative? ? 0 : age.to_i
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

class Student < Person
  attr_reader :classroom

  def initialize(age, classroom, name = 'Unknown', parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom if classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    @classroom = room
    room.students << self unless room.nil? || room.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name = 'Unknown')
    super(age, name, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
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
    student.classroom = self unless student.classroom == self
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
    choice = gets.to_s.chomp
    case choice
    when '1'
      create_student
    when '2'
      create_teacher
    else
      puts 'Invalid option. Please enter 1 or 2.'
    end
  end

  def create_student
    name = prompt_name
    age = prompt_age
    permission = prompt_permission
    return if permission.nil?

    student = Student.new(age, nil, name, parent_permission: permission)
    @people << student
    puts 'Student created successfully'
  end

  def create_teacher
    name = prompt_name
    age = prompt_age
    print 'Specialization: '
    specialization = gets.to_s.chomp
    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    puts 'Teacher created successfully'
  end

  def create_book
    print 'Title: '
    title = gets.to_s.chomp
    print 'Author: '
    author = gets.to_s.chomp
    @books << Book.new(title, author)
    puts 'Book created successfully'
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'No books or people available to create a rental'
      return
    end

    puts 'Select a book from the following list by number'
    @books.each_with_index { |book, index| puts "#{index}) Title: #{book.title}, Author: #{book.author}" }
    book_index = gets.to_s.chomp.to_i

    puts 'Select a person from the following list by number (not id)'
    @people.each_with_index do |person, index|
      puts "#{index}) [#{person.class}] Name: #{person.name}, ID: #{person.id}, Age: #{person.age}"
    end
    person_index = gets.to_s.chomp.to_i

    unless valid_indices?(person_index, book_index)
      puts 'Invalid selection'
      return
    end

    print 'Date (YYYY-MM-DD): '
    date = gets.to_s.chomp
    date = Date.today.to_s if date.empty?

    Rental.new(date, @books[book_index], @people[person_index])
    puts 'Rental created successfully'
  end

  def list_rentals
    print 'ID of person: '
    person_id = gets.to_s.chomp.to_i
    person = @people.detect { |p| p.id == person_id }

    if person.nil?
      puts 'Person not found'
      return
    end

    if person.rentals.empty?
      puts 'No rentals found for this person'
      return
    end

    person.rentals.each do |rental|
      puts "Date: #{rental.date}, Book: #{rental.book.title} by #{rental.book.author}"
    end
  end

  private

  def prompt_name
    print 'Name: '
    name = gets.to_s.chomp
    name.strip.empty? ? 'Unknown' : name
  end

  def prompt_age
    print 'Age: '
    age = gets.to_s.chomp.to_i
    age.negative? ? 0 : age
  end

  def prompt_permission
    print 'Has parent permission? [Y/N]: '
    answer = gets.to_s.chomp.upcase
    case answer
    when 'Y'
      true
    when 'N'
      false
    else
      puts 'Invalid response. Please enter Y or N.'
      nil
    end
  end

  def valid_indices?(person_index, book_index)
    person_index >= 0 && person_index < @people.length &&
      book_index >= 0 && book_index < @books.length
  end
end