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
    print 'Student (1) or Teacher (2)? '
    choice = read_input

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
    name = read_input

    print 'Age: '
    age = read_input

    permission = read_parent_permission
    student = Student.new(age, nil, name, parent_permission: permission)
    @people << student
    student
  end

  def create_teacher
    print 'Name: '
    name = read_input

    print 'Age: '
    age = read_input

    print 'Specialization: '
    specialization = read_input

    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    teacher
  end

  def create_book
    print 'Title: '
    title = read_input

    print 'Author: '
    author = read_input

    book = Book.new(title, author)
    @books << book
    book
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'A book and a person are required to create a rental'
      return nil
    end

    puts 'Select a book'
    @books.each_with_index do |book, index|
      puts "#{index}: #{book.title} by #{book.author}"
    end
    book_index = parse_integer(read_input)

    puts 'Select a person'
    @people.each_with_index do |person, index|
      puts "#{index}: #{person.name}"
    end
    person_index = parse_integer(read_input)

    unless valid_indices?(person_index, book_index)
      puts 'Invalid book or person selection'
      return nil
    end

    Rental.new(Date.today, @books[book_index], @people[person_index])
  end

  def list_rentals
    print 'ID of person: '
    person_id = parse_integer(read_input)

    if person_id.nil?
      puts 'Invalid person ID'
      return []
    end

    person = @people.find { |candidate| candidate.id == person_id }

    unless person
      puts 'Person not found'
      return []
    end

    if person.rentals.empty?
      puts 'No rentals found'
      return []
    end

    person.rentals.each do |rental|
      puts "#{rental.date} - #{rental.book.title}"
    end
  end

  private

  def read_input
    input = gets
    input.nil? ? nil : input.chomp
  end

  def read_parent_permission
    loop do
      print 'Parent permission? [Y/N]: '
      response = read_input
      return false if response.nil?

      case response.strip.downcase
      when 'y', 'yes'
        return true
      when 'n', 'no'
        return false
      else
        puts 'Please enter Y or N'
      end
    end
  end

  def parse_integer(value)
    return nil if value.nil? || value.strip.empty?

    Integer(value, 10)
  rescue ArgumentError, TypeError
    nil
  end

  def valid_indices?(person_index, book_index)
    person_index.is_a?(Integer) &&
      book_index.is_a?(Integer) &&
      person_index.between?(0, @people.length - 1) &&
      book_index.between?(0, @books.length - 1)
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, "#{self.class} must implement #correct_name"
  end
end

class Decorator < Nameable
  def initialize(nameable)
    raise ArgumentError, 'A nameable object is required' unless nameable.respond_to?(:correct_name)

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
  attr_reader :date, :book, :person

  def initialize(date, book, person)
    raise ArgumentError, 'A valid book is required' unless book.respond_to?(:rentals)
    raise ArgumentError, 'A valid person is required' unless person.respond_to?(:rentals)

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
    @title = normalize_text(title, 'Unknown title')
    @author = normalize_text(author, 'Unknown author')
    @rentals = []
  end

  def add_rental(person, date)
    Rental.new(date, self, person)
  end

  private

  def normalize_text(value, fallback)
    text = value.to_s.strip
    text.empty? ? fallback : text
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
    return nil unless student.respond_to?(:classroom=)

    @students << student unless @students.include?(student)
    student.classroom = self unless student.classroom.equal?(self)
    student
  end

  def remove_student(student)
    @students.delete(student)
  end
end

class Person < Nameable
  attr_accessor :name
  attr_reader :id, :age, :rentals, :parent_permission

  @next_id = 1

  class << self
    def generate_id
      Person.instance_variable_set(:@next_id, 1) unless Person.instance_variable_get(:@next_id)
      id = Person.instance_variable_get(:@next_id)
      Person.instance_variable_set(:@next_id, id + 1)
      id
    end
  end

  def initialize(age = 0, name = 'Unknown', parent_permission: true)
    @id = Person.generate_id
    @name = normalize_name(name)
    @age = normalize_age(age)
    @parent_permission = normalize_permission(parent_permission)
    @rentals = []
  end

  def age=(value)
    @age = normalize_age(value)
  end

  def parent_permission=(value)
    @parent_permission = normalize_permission(value)
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

  def normalize_name(value)
    text = value.to_s.strip
    text.empty? ? 'Unknown' : text
  end

  def normalize_age(value)
    age = Integer(value, 10)
    age.negative? ? 0 : age
  rescue ArgumentError, TypeError
    0
  end

  def normalize_permission(value)
    return value if value == true || value == false

    %w[y yes true 1].include?(value.to_s.strip.downcase)
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
    return @classroom if room.equal?(@classroom)
    return nil unless room.nil? || room.respond_to?(:students)

    old_classroom = @classroom
    @classroom = room
    old_classroom.remove_student(self) if old_classroom&.respond_to?(:remove_student)
    room.students << self if room && !room.students.include?(self)
    @classroom
  end

  def assign_classroom(room)
    self.classroom = room
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