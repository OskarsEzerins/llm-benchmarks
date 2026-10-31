require 'date'

class App
  def initialize
    @books = []
    @people = []
  end

  attr_reader :books, :people

  def list_books
    if @books.empty?
      puts 'No books available'
      return
    end

    @books.each_with_index do |book, index|
      puts "#{index}) Title: #{book.title}, Author: #{book.author}"
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
      return
    end

    @people.each_with_index do |person, index|
      puts "#{index}) [#{person.class}] ID: #{person.id}, Name: #{person.name}, Age: #{person.age}"
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
      puts 'Invalid option. Please choose 1 or 2.'
    end
  end

  def create_student
    name = prompt_name
    return unless name

    age = prompt_age
    return unless age

    parent_permission = prompt_parent_permission
    return if parent_permission.nil?

    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
    puts 'Student created successfully'
  end

  def create_teacher
    name = prompt_name
    return unless name

    age = prompt_age
    return unless age

    print 'Specialization: '
    specialization = gets.chomp

    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    puts 'Teacher created successfully'
  end

  def create_book
    print 'Title: '
    title = gets.chomp
    print 'Author: '
    author = gets.chomp

    if title.strip.empty? || author.strip.empty?
      puts 'Title and author cannot be empty.'
      return
    end

    @books << Book.new(title, author)
    puts 'Book created successfully'
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'There must be at least one book and one person to create a rental.'
      return
    end

    puts 'Select a book by number:'
    @books.each_with_index { |book, i| puts "#{i}) #{book.title} by #{book.author}" }
    book_index = gets.chomp.to_i

    puts 'Select a person by number:'
    @people.each_with_index { |person, i| puts "#{i}) [#{person.class}] #{person.name}" }
    person_index = gets.chomp.to_i

    unless valid_indices?(person_index, book_index)
      puts 'Invalid selection.'
      return
    end

    print 'Date (YYYY-MM-DD): '
    date = gets.chomp
    date = Date.today.to_s if date.strip.empty?

    Rental.new(date, @books[book_index], @people[person_index])
    puts 'Rental created successfully'
  end

  def list_rentals
    print 'ID of person: '
    id = gets.chomp.to_i
    person = @people.find { |p| p.id == id }

    if person.nil?
      puts "Person with ID #{id} not found."
      return
    end

    if person.rentals.empty?
      puts 'No rentals found for this person.'
      return
    end

    person.rentals.each do |rental|
      puts "Date: #{rental.date}, Book: #{rental.book.title} by #{rental.book.author}"
    end
  end

  private

  def prompt_name
    print 'Name: '
    name = gets.chomp

    if name.strip.empty?
      puts 'Name cannot be empty.'
      return nil
    end

    name
  end

  def prompt_age
    print 'Age: '
    age_input = gets.chomp

    unless age_input =~ /\A\d+\z/
      puts 'Age must be a positive integer.'
      return nil
    end

    age = age_input.to_i

    if age.negative? || age.zero?
      puts 'Age must be greater than 0.'
      return nil
    end

    age
  end

  def prompt_parent_permission
    print 'Has parent permission? [Y/N]: '
    input = gets.chomp.downcase

    case input
    when 'y', 'yes'
      true
    when 'n', 'no'
      false
    else
      puts 'Invalid input. Please enter Y or N.'
      nil
    end
  end

  def valid_indices?(person_index, book_index)
    person_index.between?(0, @people.length - 1) &&
      book_index.between?(0, @books.length - 1)
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end
end

class Decorator < Nameable
  attr_reader :nameable

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
  attr_accessor :label, :students

  def initialize(label)
    @label = label
    @students = []
  end

  def add_student(student)
    students << student unless students.include?(student)
    student.classroom = self
  end
end

class Person < Nameable
  attr_accessor :name, :age, :rentals
  attr_reader :id

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    super()
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
  attr_reader :classroom

  def initialize(age, classroom = nil, name = 'Unknown', parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @classroom = classroom
    classroom&.add_student(self)
  end

  def play_hooky
    '¯\(ツ)/¯'
  end

  def classroom=(room)
    @classroom = room
    room.students << self unless room.students.include?(self)
  end
end

class Teacher < Person
  attr_reader :specialization

  def initialize(age, specialization, name = 'Unknown', parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end