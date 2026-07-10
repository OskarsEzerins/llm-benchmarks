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
    print 'Student (1) or Teacher (2)? '
    choice = read_line

    case choice
    when '1'
      create_student
    when '2'
      create_teacher
    else
      puts 'Invalid selection.'
      nil
    end
  end

  def create_student
    print 'Name: '
    name = read_line
    unless valid_name?(name)
      puts 'Invalid name.'
      return
    end

    print 'Age: '
    age = parse_age(read_line)
    unless age
      puts 'Invalid age.'
      return
    end

    print 'Parent permission? [Y/N]: '
    permission = parse_parent_permission(read_line)
    if permission.nil?
      puts 'Invalid parent permission response.'
      return
    end

    student = Student.new(age, nil, name, parent_permission: permission)
    @people << student
    puts 'Person created successfully.'
    student
  end

  def create_teacher
    print 'Name: '
    name = read_line
    unless valid_name?(name)
      puts 'Invalid name.'
      return
    end

    print 'Age: '
    age = parse_age(read_line)
    unless age
      puts 'Invalid age.'
      return
    end

    print 'Specialization: '
    specialization = read_line

    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    puts 'Person created successfully.'
    teacher
  end

  def create_book
    print 'Title: '
    title = read_line
    print 'Author: '
    author = read_line

    book = Book.new(title, author)
    @books << book
    puts 'Book created successfully.'
    book
  end

  def create_rental
    if @books.empty?
      puts 'No books available'
      return
    end

    puts 'Select a book'
    @books.each_with_index do |book, index|
      puts "#{index}: #{book.title}"
    end

    book_index = parse_index(read_line)
    unless valid_book_index?(book_index)
      puts 'Invalid book selection.'
      return
    end

    if @people.empty?
      puts 'No people available'
      return
    end

    puts 'Select a person'
    @people.each_with_index do |person, index|
      puts "#{index}: #{person.name}"
    end

    person_index = parse_index(read_line)
    unless valid_indices?(person_index, book_index)
      puts 'Invalid person selection.'
      return
    end

    rental = Rental.new(Date.today, @books[book_index], @people[person_index])
    puts 'Rental created successfully.'
    rental
  end

  def list_rentals
    print 'ID of person: '
    person_id = parse_index(read_line)

    person = @people.find { |candidate| candidate.id == person_id }

    unless person
      puts 'Person not found.'
      return
    end

    if person.rentals.empty?
      puts 'No rentals found.'
      return
    end

    person.rentals.each do |rental|
      puts "Date: #{rental.date}, Book \"#{rental.book.title}\" by #{rental.book.author}"
    end
  end

  private

  def read_line
    value = gets
    return nil if value.nil?

    value.chomp
  end

  def valid_name?(name)
    name.is_a?(String) && !name.strip.empty?
  end

  def parse_age(value)
    return value if value.is_a?(Integer) && value >= 0
    return nil unless value.is_a?(String)

    stripped = value.strip
    return nil unless /\A\d+\z/.match?(stripped)

    stripped.to_i
  end

  def parse_index(value)
    return value if value.is_a?(Integer) && value >= 0
    return nil unless value.is_a?(String)

    stripped = value.strip
    return nil unless /\A\d+\z/.match?(stripped)

    stripped.to_i
  end

  def parse_parent_permission(value)
    return true if value.is_a?(String) && value.strip.casecmp('y').zero?
    return false if value.is_a?(String) && value.strip.casecmp('n').zero?

    nil
  end

  def valid_book_index?(book_index)
    book_index.is_a?(Integer) && book_index >= 0 && book_index < @books.length
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

    add_to_rentals(@book)
    add_to_rentals(@person)
  end

  private

  def add_to_rentals(owner)
    return unless owner&.respond_to?(:rentals)

    rentals = owner.rentals

    unless rentals.is_a?(Array)
      owner.rentals = [] if owner.respond_to?(:rentals=)
      rentals = owner.rentals
    end

    rentals << self if rentals.is_a?(Array) && !rentals.include?(self)
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

  def rentals=(value)
    @rentals = value.is_a?(Array) ? value : []
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

  def students=(value)
    @students = value.is_a?(Array) ? value : []
  end

  def add_student(student)
    return unless student.respond_to?(:classroom=)

    @students << student unless @students.include?(student)
    student.classroom = self unless student.classroom.equal?(self)
    student
  end
end

class Person < Nameable
  attr_reader :id, :name, :age, :rentals, :parent_permission

  def initialize(age = 0, name = 'Unknown', parent_permission: true)
    @id = generate_id
    self.name = name
    self.age = age
    self.parent_permission = parent_permission
    @rentals = []
  end

  def id=(value)
    @id = normalize_id(value)
  end

  def name=(value)
    text = value.to_s
    @name = text.strip.empty? ? 'Unknown' : text
  end

  def age=(value)
    @age = normalize_age(value)
  end

  def parent_permission=(value)
    @parent_permission =
      case value
      when true
        true
      when false
        false
      when String
        %w[y yes true].include?(value.strip.downcase)
      else
        false
      end
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

  def generate_id
    rand(1..1000)
  end

  def normalize_id(value)
    return value if value.is_a?(Integer)

    if value.is_a?(String) && /\A\d+\z/.match?(value.strip)
      return value.to_i
    end

    generate_id
  end

  def normalize_age(value)
    return value if value.is_a?(Integer) && value >= 0

    if value.is_a?(String) && /\A\d+\z/.match?(value.strip)
      return value.to_i
    end

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
    @classroom = nil
    self.classroom = classroom unless classroom.nil?
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    if @classroom && @classroom.respond_to?(:students)
      @classroom.students.delete(self)
    end

    @classroom = room

    if room && room.respond_to?(:students) && !room.students.include?(self)
      if room.respond_to?(:add_student)
        room.add_student(self)
      else
        room.students << self
      end
    end

    room
  end

  def assign_classroom(room)
    self.classroom = room
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name = 'Unknown')
    super(age, name, parent_permission: true)
    @specialization = specialization.nil? ? '' : specialization.to_s
  end

  def can_use_services?
    true
  end
end