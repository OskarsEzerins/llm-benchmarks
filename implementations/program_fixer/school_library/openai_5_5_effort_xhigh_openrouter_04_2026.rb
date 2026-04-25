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

class Book
  attr_reader :title, :author, :rentals

  def initialize(title = 'Untitled', author = 'Unknown')
    self.title = title
    self.author = author
    self.rentals = []
  end

  def title=(value)
    @title = normalize_text(value, 'Untitled')
  end

  def author=(value)
    @author = normalize_text(value, 'Unknown')
  end

  def rentals=(value)
    @rentals = value.is_a?(Array) ? value : []
  end

  def add_rental(person, date)
    Rental.new(date, self, person)
  end

  private

  def normalize_text(value, default)
    text = value.to_s.strip
    text.empty? ? default : text
  end
end

class Classroom
  attr_reader :label, :students

  def initialize(label = '')
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
    return nil if student.nil?

    @students << student unless @students.include?(student)
    student.classroom = self if student.respond_to?(:classroom=)
    student
  end
end

class Person < Nameable
  attr_reader :id, :name, :age, :parent_permission, :rentals

  class << self
    def normalize_integer(value)
      return value if value.is_a?(Integer)

      if value.is_a?(String)
        text = value.strip
        return text.to_i if text.match?(/\A-?\d+\z/)
      end

      nil
    end

    def valid_age_input?(value)
      !normalize_integer(value).nil?
    end

    def normalize_age(value)
      integer = normalize_integer(value)
      return 0 if integer.nil? || integer.negative?

      integer
    end

    def normalize_name(value)
      text = value.to_s.strip
      text.empty? ? 'Unknown' : text
    end

    def normalize_permission(value)
      return value if value == true || value == false

      case value
      when String
        case value.strip.downcase
        when 'y', 'yes', 'true', 't', '1'
          true
        when 'n', 'no', 'false', 'f', '0'
          false
        else
          false
        end
      when Numeric
        !value.zero?
      else
        !!value
      end
    end
  end

  def initialize(age = 0, name = 'Unknown', parent_permission: true)
    if !self.class.valid_age_input?(age) && self.class.valid_age_input?(name)
      age, name = name, age
    elsif !self.class.valid_age_input?(age) && self.class.normalize_name(name) == 'Unknown'
      name = age
      age = 0
    end

    self.id = rand(1..1000)
    self.name = name
    self.age = age
    self.parent_permission = parent_permission
    self.rentals = []
  end

  def id=(value)
    @id = self.class.normalize_integer(value) || rand(1..1000)
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
    if !classroom.nil? && !classroom.respond_to?(:students) && Person.normalize_name(name) == 'Unknown'
      name = classroom
      classroom = nil
    end

    super(age, name, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom unless classroom.nil?
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    if @classroom && @classroom != room && @classroom.respond_to?(:students)
      @classroom.students.delete(self) if @classroom.students.is_a?(Array)
    end

    @classroom = room
    return @classroom if room.nil?

    if room.respond_to?(:students)
      room.students = [] if room.respond_to?(:students=) && !room.students.is_a?(Array)
      room.students << self if room.students.is_a?(Array) && !room.students.include?(self)
    end

    @classroom
  end
end

class Teacher < Person
  attr_reader :specialization

  def initialize(age = 0, specialization = 'Unknown', name = 'Unknown')
    age, name = name, age if !Person.valid_age_input?(age) && Person.valid_age_input?(name)

    super(age, name)
    self.specialization = specialization
  end

  def specialization=(value)
    @specialization = Person.normalize_name(value)
  end

  def can_use_services?
    true
  end
end

class Rental
  attr_accessor :date, :book, :person

  def initialize(date, book, person)
    if date.is_a?(Book) && book.is_a?(Person)
      date, book, person = person, date, book
    elsif date.is_a?(Book) && person.is_a?(Person)
      date, book = book, date
    elsif date.is_a?(Person) && person.is_a?(Book)
      date, book, person = book, person, date
    elsif book.is_a?(Person) && person.is_a?(Book)
      book, person = person, book
    end

    @date = date
    @book = book
    @person = person

    add_self_to(@book)
    add_self_to(@person)
  end

  private

  def add_self_to(object)
    return unless object.respond_to?(:rentals)

    object.rentals = [] if object.respond_to?(:rentals=) && !object.rentals.is_a?(Array)
    return unless object.rentals.is_a?(Array)

    object.rentals << self unless object.rentals.include?(self)
  end
end

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
    @books ||= []

    if @books.empty?
      puts 'No books available'
      return
    end

    @books.each do |book|
      next if book.nil?

      puts "Title: \"#{book.title}\", Author: #{book.author}"
    end
  end

  def list_people
    @people ||= []

    if @people.empty?
      puts 'No one has registered'
      return
    end

    @people.each do |person|
      next if person.nil?

      puts "[#{person.class}] Name: #{person.name}, ID: #{person.id}, Age: #{person.age}"
    end
  end

  def create_person
    print 'Student(1) or Teacher(2)? '
    choice = read_input.to_s.strip.downcase

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
    first_value = read_input
    print 'Age: '
    second_value = read_input
    name, age = normalize_name_and_age(first_value, second_value)

    print 'Parent permission? [Y/N]: '
    permission = parse_parent_permission(read_input)

    student = Student.new(age, nil, name, parent_permission: permission)
    @people << student
    student
  end

  def create_teacher
    print 'Name: '
    first_value = read_input
    print 'Age: '
    second_value = read_input
    name, age = normalize_name_and_age(first_value, second_value)

    print 'Specialization: '
    specialization = normalize_text(read_input, 'Unknown')

    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    teacher
  end

  def create_book
    print 'Title: '
    title = normalize_text(read_input, 'Untitled')
    print 'Author: '
    author = normalize_text(read_input, 'Unknown')

    book = Book.new(title, author)
    @books << book
    book
  end

  def create_rental
    @books ||= []
    @people ||= []

    if @books.empty? || @people.empty?
      puts 'No books or people available'
      return nil
    end

    puts 'Select a book'
    @books.each_with_index do |book, index|
      puts "#{index}: Title: \"#{book.title}\", Author: #{book.author}"
    end
    book_index = parse_index(read_input)

    puts 'Select person'
    @people.each_with_index do |person, index|
      puts "#{index}: [#{person.class}] Name: #{person.name}, ID: #{person.id}, Age: #{person.age}"
    end
    person_index = parse_index(read_input)

    unless valid_indices?(person_index, book_index)
      puts 'Invalid selection'
      return nil
    end

    print 'Date: '
    date = normalize_text(read_input, Date.today.to_s)

    Rental.new(date, @books[book_index], @people[person_index])
  end

  def list_rentals
    print 'ID of person: '
    person_id = Person.normalize_integer(read_input)

    if person_id.nil?
      puts 'Invalid ID'
      return
    end

    person = @people.find { |pr| pr.id == person_id }

    unless person
      puts 'No rentals found'
      return
    end

    rentals = person.rentals.is_a?(Array) ? person.rentals : []

    if rentals.empty?
      puts 'No rentals found'
      return
    end

    rentals.each do |rental|
      book = rental.book
      title = book.respond_to?(:title) ? book.title : 'Unknown'
      author = book.respond_to?(:author) ? book.author : 'Unknown'
      puts "Date: #{rental.date}, Book \"#{title}\" by #{author}"
    end
  end

  private

  def read_input
    input = gets
    input.nil? ? nil : input.to_s.chomp
  end

  def normalize_text(value, default)
    text = value.to_s.strip
    text.empty? ? default : text
  end

  def normalize_name_and_age(first_value, second_value)
    if Person.valid_age_input?(first_value) && !Person.valid_age_input?(second_value)
      [normalize_text(second_value, 'Unknown'), Person.normalize_age(first_value)]
    else
      [normalize_text(first_value, 'Unknown'), Person.normalize_age(second_value)]
    end
  end

  def parse_parent_permission(value)
    Person.normalize_permission(value)
  end

  def parse_index(value)
    text = value.to_s.strip
    return nil unless text.match?(/\A\d+\z/)

    text.to_i
  end

  def valid_indices?(person_index, book_index)
    people_count = (@people || []).length
    books_count = (@books || []).length

    return false unless person_index.is_a?(Integer) && book_index.is_a?(Integer)

    person_index >= 0 && person_index < people_count && book_index >= 0 && book_index < books_count
  end
end