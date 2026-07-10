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
    print 'Student(2) or Teacher(1)? '
    choice = gets&.strip

    case choice
    when '1'
      create_teacher
    when '2', '3'
      create_student
    else
      puts 'Invalid person type selected'
    end
  end

  def create_student
    print 'Name: '
    name = read_name

    print 'Age: '
    age = read_age

    print 'Parent permission? [Y/N]: '
    permission = read_parent_permission

    student = Student.new(age, nil, name, parent_permission: permission)
    @people << student
    puts 'Student created successfully'
    student
  end

  def create_teacher
    print 'Name: '
    name = read_name

    print 'Age: '
    age = read_age

    print 'Specialization: '
    specialization = gets&.strip
    specialization = 'Unknown' if specialization.nil? || specialization.empty?

    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    puts 'Teacher created successfully'
    teacher
  end

  def create_book
    print 'Title: '
    title = gets&.strip
    title = 'Unknown' if title.nil? || title.empty?

    print 'Author: '
    author = gets&.strip
    author = 'Unknown' if author.nil? || author.empty?

    book = Book.new(title, author)
    @books << book
    puts 'Book created successfully'
    book
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'Books and people must exist before creating a rental'
      return
    end

    puts 'Select a book'
    @books.each_with_index do |book, index|
      puts "#{index}: #{book.title}"
    end

    book_index = read_index

    puts 'Select person'
    @people.each_with_index do |person, index|
      puts "#{index}: #{person.name}"
    end

    person_index = read_index

    unless valid_indices?(person_index, book_index)
      puts 'Invalid selection'
      return
    end

    rental = Rental.new(Date.today, @books[book_index], @people[person_index])
    puts 'Rental created successfully'
    rental
  end

  def list_rentals
    print 'ID of person: '
    input = gets&.strip

    unless input&.match?(/\A\d+\z/)
      puts 'Invalid person ID'
      return
    end

    person = @people.find { |individual| individual.id == input.to_i }

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

  def read_name
    name = gets&.strip
    name.nil? || name.empty? ? 'Unknown' : name
  end

  def read_age
    input = gets&.strip

    return 0 unless input&.match?(/\A\d+\z/)

    age = input.to_i
    age.negative? ? 0 : age
  end

  def read_parent_permission
    input = gets&.strip&.upcase

    case input
    when 'Y', 'YES'
      true
    when 'N', 'NO'
      false
    else
      puts 'Invalid permission response. Defaulting to no permission.'
      false
    end
  end

  def read_index
    input = gets&.strip
    return nil unless input&.match?(/\A\d+\z/)

    input.to_i
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

    book.rentals << self unless book.rentals.include?(self)
    person.rentals << self unless person.rentals.include?(self)
  end
end

class Book
  attr_accessor :title, :author
  attr_reader :rentals

  def initialize(title, author)
    @title = title.nil? || title.to_s.empty? ? 'Unknown' : title.to_s
    @author = author.nil? || author.to_s.empty? ? 'Unknown' : author.to_s
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
    return unless student

    @students << student unless @students.include?(student)
    student.assign_classroom(self) unless student.classroom == self
  end
end

class Person < Nameable
  attr_accessor :name, :age
  attr_reader :id, :rentals, :parent_permission

  def initialize(age, name = 'Unknown', parent_permission: true)
    @id = rand(1..1000)
    @name = normalize_name(name)
    @age = normalize_age(age)
    @parent_permission = normalize_permission(parent_permission)
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

  def normalize_name(name)
    value = name.to_s.strip
    value.empty? ? 'Unknown' : value
  end

  def normalize_age(age)
    parsed_age = Integer(age)
    parsed_age.negative? ? 0 : parsed_age
  rescue ArgumentError, TypeError
    0
  end

  def normalize_permission(permission)
    permission == true || %w[Y YES TRUE].include?(permission.to_s.upcase)
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
    return unless room

    @classroom.students.delete(self) if @classroom && @classroom != room
    @classroom = room
    room.students << self unless room.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name = 'Unknown')
    super(age, name)
    @specialization = specialization.nil? || specialization.to_s.empty? ? 'Unknown' : specialization.to_s
  end

  def can_use_services?
    true
  end
end