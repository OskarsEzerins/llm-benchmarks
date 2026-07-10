require 'date'

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
      puts "[#{person.class}] id: #{person.id}, Name: #{person.name}, Age: #{person.age}"
    end
  end

  def create_person
    print 'Student (1) or Teacher (2)? '
    choice = gets&.chomp

    case choice
    when '1'
      create_student
    when '2'
      create_teacher
    else
      puts 'Invalid person selection'
    end
  end

  def create_student
    print 'Name: '
    name = gets&.chomp

    print 'Age: '
    age = valid_age(gets&.chomp)

    print 'Parent permission? [Y/N]: '
    permission_input = gets&.chomp&.upcase

    parent_permission =
      case permission_input
      when 'Y'
        true
      when 'N'
        false
      else
        puts 'Invalid parent permission response. Defaulting to no permission.'
        false
      end

    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
    puts 'Student created successfully'
  end

  def create_teacher
    print 'Name: '
    name = gets&.chomp

    print 'Age: '
    age = valid_age(gets&.chomp)

    print 'Specialization: '
    specialization = gets&.chomp

    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    puts 'Teacher created successfully'
  end

  def create_book
    print 'Title: '
    title = gets&.chomp

    print 'Author: '
    author = gets&.chomp

    @books << Book.new(title, author)
    puts 'Book created successfully'
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'A book and a person are required to create a rental'
      return
    end

    puts 'Select a book'
    @books.each_with_index do |book, index|
      puts "#{index}: #{book.title}"
    end

    book_index = integer_input(gets&.chomp)

    puts 'Select person'
    @people.each_with_index do |person, index|
      puts "#{index}: #{person.name}"
    end

    person_index = integer_input(gets&.chomp)

    unless valid_indices?(person_index, book_index)
      puts 'Invalid book or person selection'
      return
    end

    Rental.new(Date.today, @books[book_index], @people[person_index])
    puts 'Rental created successfully'
  end

  def list_rentals
    print 'ID of person: '
    person_id = integer_input(gets&.chomp)

    person = @people.find { |candidate| candidate.id == person_id }

    unless person
      puts 'Person not found'
      return
    end

    if person.rentals.empty?
      puts 'No rentals found'
      return
    end

    person.rentals.each do |rental|
      puts "#{rental.date} - #{rental.book.title} by #{rental.book.author}"
    end
  end

  private

  def valid_indices?(person_index, book_index)
    person_index.is_a?(Integer) &&
      book_index.is_a?(Integer) &&
      person_index.between?(0, @people.length - 1) &&
      book_index.between?(0, @books.length - 1)
  end

  def integer_input(value)
    Integer(value)
  rescue ArgumentError, TypeError
    nil
  end

  def valid_age(value)
    age = integer_input(value)
    return 0 if age.nil? || age.negative?

    age
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
  attr_accessor :title, :author
  attr_reader :rentals

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
    @label = label.to_s
    @students = []
  end

  def add_student(student)
    return unless student

    @students << student unless @students.include?(student)
    student.assign_classroom(self) unless student.classroom == self
  end
end

class Person < Nameable
  attr_reader :id, :name, :age, :rentals, :parent_permission

  def initialize(age = 0, name = 'Unknown', parent_permission: true)
    @id = rand(1..1000)
    @name = valid_name(name)
    @age = valid_age(age)
    @parent_permission = parent_permission == true || parent_permission.to_s.upcase == 'Y'
    @rentals = []
  end

  def name=(value)
    @name = valid_name(value)
  end

  def age=(value)
    @age = valid_age(value)
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

  def valid_age(value)
    age = Integer(value)
    age.negative? ? 0 : age
  rescue ArgumentError, TypeError
    0
  end

  def valid_name(value)
    name = value.to_s.strip
    name.empty? ? 'Unknown' : name
  end
end

class Student < Person
  attr_reader :classroom

  def initialize(age, classroom = nil, name = 'Unknown', parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    @classroom = nil
    assign_classroom(classroom) if classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    assign_classroom(room)
  end

  def assign_classroom(room)
    return if room.nil? || @classroom == room

    @classroom.students.delete(self) if @classroom && @classroom.students.include?(self)
    @classroom = room
    room.students << self unless room.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name = 'Unknown')
    super(age, name, parent_permission: true)
    @specialization = specialization.to_s
  end

  def can_use_services?
    true
  end
end