require 'date'

class App
  attr_reader :books, :people

  def initialize
    self.books = []
    self.people = []
  end

  def books=(value)
    @books = value.is_a?(Array) ? value : []
  end

  def people=(value)
    @people = value.is_a?(Array) ? value : []
  end

  def list_books
    ensure_collections

    if @books.empty?
      puts 'No books available'
      return @books
    end

    @books.each do |book|
      puts "Title: \"#{book.title}\", Author: #{book.author}"
    end

    @books
  end

  def list_people
    ensure_collections

    if @people.empty?
      puts 'No one has registered'
      return @people
    end

    @people.each do |person|
      puts "[#{person.class}] ID: #{person.id}, Name: #{person.name}, Age: #{person.age}"
    end

    @people
  end

  def create_person
    print 'Do you want to create a student (1) or a teacher (2)? [Input the number]: '
    choice = read_input.to_s.strip.downcase

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
    ensure_collections

    print 'Name: '
    name = read_input

    print 'Age: '
    age = read_input

    print 'Has parent permission? [Y/N]: '
    permission = read_input

    student = Student.new(
      parse_age(age),
      nil,
      parse_name(name),
      parent_permission: parse_permission(permission)
    )

    @people << student
    student
  end

  def create_teacher
    ensure_collections

    print 'Name: '
    name = read_input

    print 'Age: '
    age = read_input

    print 'Specialization: '
    specialization = read_input

    teacher = Teacher.new(
      parse_age(age),
      parse_name(specialization, 'Unknown'),
      parse_name(name)
    )

    @people << teacher
    teacher
  end

  def create_book
    ensure_collections

    print 'Title: '
    title = read_input

    print 'Author: '
    author = read_input

    book = Book.new(title, author)
    @books << book
    book
  end

  def create_rental
    ensure_collections

    if @books.empty? || @people.empty?
      puts 'No books or people available to create a rental'
      return nil
    end

    puts 'Select a book by number'
    @books.each_with_index do |book, index|
      puts "#{index}) Title: \"#{book.title}\", Author: #{book.author}"
    end
    book_index = parse_index(read_input)

    puts 'Select a person by number'
    @people.each_with_index do |person, index|
      puts "#{index}) [#{person.class}] ID: #{person.id}, Name: #{person.name}, Age: #{person.age}"
    end
    person_index = parse_index(read_input)

    unless valid_indices?(person_index, book_index)
      puts 'Invalid selection'
      return nil
    end

    print 'Date (YYYY-MM-DD): '
    date = read_input
    date = Date.today.to_s if date.nil? || date.strip.empty?

    Rental.new(date, @books[book_index], @people[person_index])
  end

  def list_rentals
    ensure_collections

    print 'ID of person: '
    person_id = parse_index(read_input)

    person = @people.find { |person_item| person_item.id == person_id }

    unless person
      puts 'Person not found'
      return nil
    end

    person.rentals.each do |rental|
      puts "Date: #{rental.date}, Book: \"#{rental.book.title}\" by #{rental.book.author}"
    end

    person.rentals
  end

  private

  def ensure_collections
    @books = [] unless @books.is_a?(Array)
    @people = [] unless @people.is_a?(Array)
  end

  def read_input
    input = gets
    input&.chomp
  end

  def parse_age(value)
    Person.normalize_age(value)
  end

  def parse_name(value, default = 'Unknown')
    Person.normalize_name(value, default)
  end

  def parse_permission(value)
    Person.normalize_permission(value)
  end

  def parse_index(value)
    number = Person.integer_value(value)
    return nil if number.nil? || number.negative?

    number
  end

  def valid_indices?(person_index, book_index)
    ensure_collections

    person_index = parse_index(person_index)
    book_index = parse_index(book_index)

    !person_index.nil? &&
      !book_index.nil? &&
      person_index < @people.length &&
      book_index < @books.length
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

    attach_to(@book)
    attach_to(@person)
  end

  private

  def attach_to(object)
    return unless object&.respond_to?(:rentals)

    rentals = object.rentals

    unless rentals.is_a?(Array)
      return unless object.respond_to?(:rentals=)

      object.rentals = []
      rentals = object.rentals
    end

    rentals << self unless rentals.include?(self)
  end
end

class Book
  attr_reader :title, :author, :rentals

  def initialize(title, author)
    self.title = title
    self.author = author
    self.rentals = []
  end

  def title=(value)
    text = value.to_s.strip
    @title = text.empty? ? 'Untitled' : text
  end

  def author=(value)
    text = value.to_s.strip
    @author = text.empty? ? 'Unknown' : text
  end

  def rentals=(value)
    @rentals = value.is_a?(Array) ? value : []
  end

  def add_rental(person, date)
    Rental.new(date, self, person)
  end
end

class Classroom
  attr_reader :label, :students

  def initialize(label)
    self.label = label
    self.students = []
  end

  def label=(value)
    @label = value.to_s
  end

  def students=(value)
    @students = value.is_a?(Array) ? value : []
  end

  def add_student(student)
    return nil unless student

    self.students = [] unless @students.is_a?(Array)
    @students << student unless @students.include?(student)

    if student.respond_to?(:classroom=) && (!student.respond_to?(:classroom) || student.classroom != self)
      student.classroom = self
    end

    student
  end
end

class Person < Nameable
  @@next_id = 1

  attr_reader :id, :name, :age, :rentals, :parent_permission

  def self.next_id
    current_id = @@next_id
    @@next_id += 1
    current_id
  end

  def self.integer_value(value)
    return value if value.is_a?(Integer)

    if value.is_a?(Float)
      return value.to_i if value.finite? && value == value.to_i
      return nil
    end

    text = value.to_s.strip
    return nil unless text.match?(/\A[+-]?\d+\z/)

    text.to_i
  end

  def self.integer_like?(value)
    !integer_value(value).nil?
  end

  def self.normalize_age(value)
    number = integer_value(value)
    return 0 if number.nil? || number.negative?

    number
  end

  def self.normalize_id(value)
    number = integer_value(value)
    return next_id if number.nil? || number <= 0

    number
  end

  def self.normalize_name(value, default = 'Unknown')
    text = value.to_s.strip
    text.empty? ? default : text
  end

  def self.normalize_permission(value)
    return true if value == true
    return false if value == false

    case value.to_s.strip.downcase
    when 'y', 'yes', 'true', '1'
      true
    when 'n', 'no', 'false', '0'
      false
    else
      false
    end
  end

  def initialize(age = 0, name = 'Unknown', parent_permission: true, id: nil)
    if !self.class.integer_like?(age) && self.class.integer_like?(name)
      age, name = name, age
    elsif !self.class.integer_like?(age) && (name.nil? || name == 'Unknown')
      name, age = age, 0
    end

    self.id = id
    self.name = name
    self.age = age
    self.parent_permission = parent_permission
    self.rentals = []
  end

  def id=(value)
    @id = self.class.normalize_id(value)
  end

  def name=(value)
    @name = self.class.normalize_name(value)
  end

  def age=(value)
    @age = self.class.normalize_age(value)
  end

  def parent_permission=(value)
    @parent_permission = self.class.normalize_permission(value)
  end

  def rentals=(value)
    @rentals = value.is_a?(Array) ? value : []
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

  def initialize(age = 0, classroom = nil, name = 'Unknown', parent_permission: true)
    if name == 'Unknown' && classroom && !classroom.respond_to?(:students)
      name = classroom
      classroom = nil
    end

    super(age, name, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom if classroom
  end

  def play_hooky
    '¯\(ツ)/¯'
  end

  def classroom=(room)
    unless room.nil? || room.respond_to?(:students)
      remove_from_current_classroom
      @classroom = nil
      return nil
    end

    remove_from_current_classroom if @classroom && @classroom != room
    @classroom = room
    add_to_classroom_students(room)
    room
  end

  def assign_classroom(room)
    self.classroom = room
  end

  private

  def remove_from_current_classroom
    return unless @classroom&.respond_to?(:students)
    return unless @classroom.students.is_a?(Array)

    @classroom.students.delete(self)
  end

  def add_to_classroom_students(room)
    return unless room&.respond_to?(:students)

    unless room.students.is_a?(Array)
      return unless room.respond_to?(:students=)

      room.students = []
    end

    room.students << self unless room.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age = 0, specialization = 'Unknown', name = 'Unknown', parent_permission: true)
    if !Person.integer_like?(age) && Person.integer_like?(name)
      age, name = name, age
    elsif !Person.integer_like?(age) && (name.nil? || name == 'Unknown')
      name, age = age, 0
    end

    super(age, name, parent_permission: parent_permission)
    @specialization = Person.normalize_name(specialization, 'Unknown')
  end

  def can_use_services?
    true
  end
end