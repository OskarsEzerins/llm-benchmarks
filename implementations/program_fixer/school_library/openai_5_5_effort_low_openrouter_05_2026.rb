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
      puts 'Invalid selection'
      nil
    end
  end

  def create_student
    print 'Name: '
    name = gets&.chomp
    name = 'Unknown' if name.nil? || name.empty?

    print 'Age: '
    age = parse_age(gets&.chomp)

    print 'Has parent permission? [Y/N]: '
    permission_input = gets&.chomp&.downcase
    parent_permission = permission_input == 'y'

    unless %w[y n].include?(permission_input)
      puts 'Invalid parent permission response. Defaulting to false.'
      parent_permission = false
    end

    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
    student
  end

  def create_teacher
    print 'Name: '
    name = gets&.chomp
    name = 'Unknown' if name.nil? || name.empty?

    print 'Age: '
    age = parse_age(gets&.chomp)

    print 'Specialization: '
    specialization = gets&.chomp
    specialization = 'Unknown' if specialization.nil? || specialization.empty?

    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    teacher
  end

  def create_book
    print 'Title: '
    title = gets&.chomp
    title = 'Untitled' if title.nil? || title.empty?

    print 'Author: '
    author = gets&.chomp
    author = 'Unknown' if author.nil? || author.empty?

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

    puts 'Select a book from the following list by number'
    @books.each_with_index { |book, index| puts "#{index}) Title: #{book.title}, Author: #{book.author}" }
    book_index = gets&.chomp.to_i

    puts 'Select a person from the following list by number'
    @people.each_with_index do |person, index|
      puts "#{index}) [#{person.class}] ID: #{person.id}, Name: #{person.name}, Age: #{person.age}"
    end
    person_index = gets&.chomp.to_i

    unless valid_indices?(person_index, book_index)
      puts 'Invalid selection'
      return nil
    end

    print 'Date [YYYY-MM-DD]: '
    date = gets&.chomp
    date = Date.today.to_s if date.nil? || date.empty?

    Rental.new(date, @books[book_index], @people[person_index])
  end

  def list_rentals
    print 'ID of person: '
    person_id = gets&.chomp.to_i

    person = @people.find { |current_person| current_person.id == person_id }

    if person.nil?
      puts 'Person not found'
      return
    end

    if person.rentals.empty?
      puts 'No rentals found'
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

  def parse_age(value)
    age = Integer(value)
    age.negative? ? 0 : age
  rescue ArgumentError, TypeError
    0
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, "#{self.class} must implement correct_name"
  end
end

class Decorator < Nameable
  attr_accessor :nameable

  def initialize(nameable)
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

    @book.rentals << self unless @book.rentals.include?(self)
    @person.rentals << self unless @person.rentals.include?(self)
  end
end

class Book
  attr_accessor :title, :author, :rentals

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

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals
  attr_reader :parent_permission

  def initialize(age = 0, name = 'Unknown', parent_permission: true)
    @id = Random.rand(1..1000)
    @name = name.nil? || name.to_s.empty? ? 'Unknown' : name.to_s
    @age = sanitize_age(age)
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

  def sanitize_age(value)
    age = Integer(value)
    age.negative? ? 0 : age
  rescue ArgumentError, TypeError
    0
  end

  def of_age?
    @age >= 18
  end
end

class Student < Person
  attr_reader :classroom

  def initialize(age, classroom = nil, name = 'Unknown', parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    self.classroom = classroom unless classroom.nil?
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(classroom)
    @classroom = classroom
    classroom.students << self unless classroom.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name = 'Unknown')
    super(age, name, parent_permission: true)
    @specialization = specialization.nil? || specialization.to_s.empty? ? 'Unknown' : specialization.to_s
  end

  def can_use_services?
    true
  end
end