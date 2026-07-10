require 'date'

class Nameable
  def correct_name
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end
end

class Decorator < Nameable
  attr_accessor :nameable

  def initialize(nameable)
    @nameable = nameable
  end

  def correct_name
    return '' unless @nameable.respond_to?(:correct_name)

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

class Person < Nameable
  attr_reader :id, :name, :age, :rentals, :parent_permission

  @@next_id = 1

  def self.next_id
    id = @@next_id
    @@next_id += 1
    id
  end

  def self.integer_like?(value)
    return true if value.is_a?(Integer)
    return false if value.nil?

    !!(value.to_s.strip =~ /\A-?\d+\z/)
  end

  def self.integer_value(value)
    return value if value.is_a?(Integer)
    return nil unless integer_like?(value)

    value.to_s.strip.to_i
  end

  def self.normalize_age(value)
    int = integer_value(value)
    int && int >= 0 ? int : 0
  end

  def self.normalize_name(value)
    text = value.to_s.strip
    text.empty? ? 'Unknown' : text
  end

  def self.normalize_boolean(value)
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

  def initialize(age = 0, name = 'Unknown', parent_permission: true)
    actual_age = age
    actual_name = name

    if !self.class.integer_like?(age) && self.class.integer_like?(name)
      actual_age = name
      actual_name = age
    elsif name == 'Unknown' && !self.class.integer_like?(age) && !age.nil?
      actual_age = 0
      actual_name = age
    end

    @id = self.class.next_id
    self.name = actual_name
    self.age = actual_age
    self.parent_permission = parent_permission
    self.rentals = []
  end

  def id=(value)
    int = self.class.integer_value(value)
    @id = int && int >= 0 ? int : self.class.next_id
  end

  def name=(value)
    @name = self.class.normalize_name(value)
  end

  def age=(value)
    @age = self.class.normalize_age(value)
  end

  def parent_permission=(value)
    @parent_permission = self.class.normalize_boolean(value)
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

  def add_rental(first, second)
    if defined?(Book) && first.is_a?(Book)
      Rental.new(second, first, self)
    else
      Rental.new(first, second, self)
    end
  end

  private

  def of_age?
    @age >= 18
  end
end

class Student < Person
  attr_reader :classroom

  def initialize(age, classroom = nil, name = 'Unknown', parent_permission: true)
    if name == 'Unknown' && !classroom.nil? && !classroom.respond_to?(:students)
      name = classroom
      classroom = nil
    end

    super(age, name, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom unless classroom.nil?
  end

  def play_hooky
    '¯\_(ツ)_/¯'
  end

  def classroom=(room)
    return @classroom = nil if room.nil? || !room.respond_to?(:students)

    @classroom = room
    room.students = [] if !room.students.is_a?(Array) && room.respond_to?(:students=)
    room.students << self if room.students.is_a?(Array) && !room.students.include?(self)
    @classroom
  end

  def assign_classroom(room)
    self.classroom = room
  end
end

class Teacher < Person
  attr_reader :specialization

  def initialize(age, specialization = 'Unknown', name = 'Unknown')
    actual_age = age
    actual_specialization = specialization
    actual_name = name

    if !self.class.integer_like?(age) && self.class.integer_like?(name)
      actual_age = name
      actual_name = age
    elsif name == 'Unknown' && !self.class.integer_like?(age) && !age.nil?
      actual_age = 0
      actual_name = age
    end

    super(actual_age, actual_name, parent_permission: true)
    self.specialization = actual_specialization
  end

  def specialization=(value)
    @specialization = self.class.normalize_name(value)
  end

  def can_use_services?
    true
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

  def add_rental(first, second)
    if defined?(Person) && first.is_a?(Person)
      Rental.new(second, self, first)
    else
      Rental.new(first, self, second)
    end
  end
end

class Classroom
  attr_reader :label, :students

  def initialize(label)
    self.label = label
    self.students = []
  end

  def label=(value)
    @label = value.to_s.strip
  end

  def students=(value)
    @students = value.is_a?(Array) ? value : []
  end

  def add_student(student)
    return nil unless student.respond_to?(:classroom=)

    @students << student unless @students.include?(student)
    student.classroom = self if !student.respond_to?(:classroom) || student.classroom != self
    student
  end
end

class Rental
  attr_accessor :date
  attr_reader :book, :person

  def initialize(date, book = nil, person = nil)
    actual_date = date
    actual_book = book
    actual_person = person

    if defined?(Book) && defined?(Person)
      if date.is_a?(Book) && book.is_a?(Person)
        actual_date = person
        actual_book = date
        actual_person = book
      elsif date.is_a?(Person) && person.is_a?(Book)
        actual_date = book
        actual_book = person
        actual_person = date
      elsif book.is_a?(Person) && person.is_a?(Book)
        actual_book = person
        actual_person = book
      end
    end

    @date = actual_date
    self.book = actual_book
    self.person = actual_person

    add_to_rentals(@book)
    add_to_rentals(@person)
  end

  def book=(book)
    @book = book
  end

  def person=(person)
    @person = person
  end

  private

  def add_to_rentals(object)
    return unless object.respond_to?(:rentals)

    object.rentals = [] if object.respond_to?(:rentals=) && !object.rentals.is_a?(Array)
    object.rentals << self if object.rentals.respond_to?(:<<) && !object.rentals.include?(self)
  end
end

class App
  attr_reader :books, :people

  def initialize
    @books = []
    @people = []
  end

  def books=(books)
    @books = books.is_a?(Array) ? books : []
  end

  def people=(people)
    @people = people.is_a?(Array) ? people : []
  end

  def list_books
    if @books.empty?
      puts 'No books available'
      return []
    end

    @books.each do |book|
      puts "Title: #{book.title}, Author: #{book.author}"
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
      return []
    end

    @people.each do |person|
      puts "[#{person.class}] ID: #{person.id}, Name: #{person.name}, Age: #{person.age}"
    end
  end

  def create_person
    print 'Do you want to create a student (1) or a teacher (2)? [Input the number]: '
    choice = read_input.downcase

    case choice
    when '1', 'student', 's'
      create_student
    when '2', 'teacher', 't'
      create_teacher
    else
      puts 'Invalid selection'
      nil
    end
  end

  def create_student
    print 'Name: '
    name = read_input

    print 'Age: '
    age = Person.normalize_age(read_input)

    print 'Has parent permission? [Y/N]: '
    parent_permission = Person.normalize_boolean(read_input)

    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
    puts 'Person created successfully'
    student
  end

  def create_teacher
    print 'Name: '
    name = read_input

    print 'Age: '
    age = Person.normalize_age(read_input)

    print 'Specialization: '
    specialization = read_input

    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    puts 'Person created successfully'
    teacher
  end

  def create_book
    print 'Title: '
    title = read_input

    print 'Author: '
    author = read_input

    book = Book.new(title, author)
    @books << book
    puts 'Book created successfully'
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
    @books.each_with_index { |book, index| puts "#{index}: #{book.title} by #{book.author}" }
    book_index = read_index

    puts 'Select a person from the following list by number'
    @people.each_with_index do |person, index|
      puts "#{index}: [#{person.class}] Name: #{person.name}, ID: #{person.id}, Age: #{person.age}"
    end
    person_index = read_index

    unless valid_indices?(person_index, book_index)
      puts 'Invalid selection'
      return nil
    end

    print 'Date (YYYY-MM-DD): '
    date = read_input
    date = Date.today.to_s if date.empty?

    rental = Rental.new(date, @books[book_index], @people[person_index])
    puts 'Rental created successfully'
    rental
  end

  def list_rentals
    print 'ID of person: '
    person_id = Person.integer_value(read_input)

    unless person_id
      puts 'Invalid ID'
      return []
    end

    person = @people.detect { |person_obj| person_obj.id == person_id }

    unless person
      puts 'Person not found'
      return []
    end

    if person.rentals.empty?
      puts 'No rentals found'
      return []
    end

    person.rentals.each do |rental|
      puts "Date: #{rental.date}, Book: #{rental.book.title} by #{rental.book.author}"
    end
  end

  private

  def read_input
    input = gets
    input.nil? ? '' : input.chomp
  end

  def read_index
    value = read_input.strip
    return nil unless value =~ /\A\d+\z/

    value.to_i
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