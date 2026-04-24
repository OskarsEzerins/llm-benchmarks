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
      puts "Title: \"#{book.title}\", Author: #{book.author}"
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
      return
    end

    @people.each do |person|
      puts "[#{person.class}] Name: #{person.name}, ID: #{person.id}, Age: #{person.age}"
    end
  end

  def create_person
    print 'Do you want to create a student (1) or a teacher (2)? [Input the number]: '
    choice = read_input.downcase

    case choice
    when '1', '3', 'student', 's'
      create_student
    when '2', 'teacher', 't'
      create_teacher
    else
      puts 'Invalid option'
      nil
    end
  end

  def create_student
    print 'Name: '
    name = normalize_name(read_input)

    print 'Age: '
    age = normalize_age(read_input)

    print 'Has parent permission? [Y/N]: '
    parent_permission = parse_parent_permission(read_input)

    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
    student
  end

  def create_teacher
    print 'Name: '
    name = normalize_name(read_input)

    print 'Age: '
    age = normalize_age(read_input)

    print 'Specialization: '
    specialization = normalize_name(read_input, 'Unknown')

    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    teacher
  end

  def create_book
    print 'Title: '
    title = normalize_name(read_input, 'Unknown')

    print 'Author: '
    author = normalize_name(read_input, 'Unknown')

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
    @books.each_with_index do |book, index|
      puts "#{index}) Title: \"#{book.title}\", Author: #{book.author}"
    end
    book_index = normalize_index(read_input)

    puts 'Select a person from the following list by number (not id)'
    @people.each_with_index do |person, index|
      puts "#{index}) [#{person.class}] Name: #{person.name}, ID: #{person.id}, Age: #{person.age}"
    end
    person_index = normalize_index(read_input)

    unless valid_indices?(person_index, book_index)
      puts 'Invalid selection'
      return nil
    end

    print 'Date: '
    date = read_input

    Rental.new(date, @books[book_index], @people[person_index])
  end

  def list_rentals
    print 'ID of person: '
    person_id = normalize_index(read_input)

    person = @people.find { |item| item.id == person_id }

    unless person
      puts 'Person not found'
      return []
    end

    if person.rentals.empty?
      puts 'No rentals found'
      return []
    end

    person.rentals.each do |rental|
      puts "Date: #{rental.date}, Book \"#{rental.book.title}\" by #{rental.book.author}"
    end

    person.rentals
  end

  private

  def read_input
    gets&.chomp.to_s
  end

  def normalize_name(value, default = 'Unknown')
    text = value.to_s.strip
    text.empty? ? default : text
  end

  def normalize_age(value)
    age = Integer(value)
    age.negative? ? 0 : age
  rescue ArgumentError, TypeError
    0
  end

  def normalize_index(value)
    Integer(value)
  rescue ArgumentError, TypeError
    -1
  end

  def parse_parent_permission(value)
    case value.to_s.strip.downcase
    when 'y', 'yes', 'true', '1'
      true
    when 'n', 'no', 'false', '0'
      false
    else
      false
    end
  end

  def valid_indices?(person_index, book_index)
    person_index.is_a?(Integer) &&
      book_index.is_a?(Integer) &&
      person_index >= 0 &&
      book_index >= 0 &&
      person_index < @people.length &&
      book_index < @books.length
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, 'Implement in subclass'
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
    super.to_s[0, 10]
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
  attr_accessor :title, :author
  attr_reader :rentals

  def initialize(title, author)
    @title = normalize_text(title)
    @author = normalize_text(author)
    @rentals = []
  end

  def add_rental(person, date)
    Rental.new(date, self, person)
  end

  private

  def normalize_text(value)
    text = value.to_s.strip
    text.empty? ? 'Unknown' : text
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

    student.classroom = self
    student
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age
  attr_reader :rentals, :parent_permission

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

  def normalize_age(value)
    age = Integer(value)
    age.negative? ? 0 : age
  rescue ArgumentError, TypeError
    0
  end

  def normalize_name(value)
    text = value.to_s.strip
    text.empty? ? 'Unknown' : text
  end

  def normalize_permission(value)
    case value
    when true, false
      value
    when String
      %w[y yes true 1].include?(value.strip.downcase)
    else
      !!value
    end
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
    return unless room

    room.students << self unless room.students.include?(self)
  end

  alias assign_classroom classroom=
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name = 'Unknown')
    super(age, name, parent_permission: true)
    @specialization = specialization.to_s.strip
    @specialization = 'Unknown' if @specialization.empty?
  end

  def can_use_services?
    true
  end
end