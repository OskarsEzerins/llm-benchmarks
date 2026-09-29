require 'date'

class Nameable
  def correct_name
    raise NotImplementedError, 'Subclasses must implement correct_name'
  end
end

class Decorator < Nameable
  attr_reader :nameable

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

class Person < Nameable
  attr_reader :id, :name, :age, :parent_permission, :rentals

  @next_id = 0

  def self.next_id
    Person.instance_variable_set(
      :@next_id,
      Person.instance_variable_get(:@next_id) + 1
    )
  end

  def initialize(age, name = 'Unknown', parent_permission: true)
    @id = Person.next_id
    self.name = name
    self.age = age
    self.parent_permission = parent_permission
    @rentals = []
  end

  def name=(value)
    text = value.to_s.strip
    @name = text.empty? ? 'Unknown' : text
  end

  def age=(value)
    parsed = if value.is_a?(Integer)
               value
             elsif value.is_a?(String) && value.strip.match?(/\A\+?\d+\z/)
               value.strip.to_i
             end

    @age = parsed && parsed >= 0 ? parsed : 0
  end

  def parent_permission=(value)
    @parent_permission =
      value == true ||
      (value.is_a?(String) && %w[y yes true].include?(value.strip.downcase))
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
    super(age, name, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom unless classroom.nil?
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    return @classroom if @classroom.equal?(room)

    @classroom.students.delete(self) if @classroom
    @classroom = room

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
    super(age, name)
    @specialization = specialization
  end

  def can_use_services?
    true
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

  def add_rental(person, date)
    Rental.new(date, self, person)
  end
end

class Rental
  attr_reader :date, :book, :person

  def initialize(date, book, person)
    @date = date
    @book = book
    @person = person

    @book.rentals << self
    @person.rentals << self
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
    student.classroom = self
    @students << student unless @students.include?(student)
    student
  end
end

class App
  attr_reader :books, :people, :rentals

  def initialize
    @books = []
    @people = []
    @rentals = []
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
    print 'Create a student (1) or a teacher (2)? '

    case read_input
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
    age = parse_nonnegative_integer(read_input)

    print 'Parent permission? [Y/N]: '
    permission = read_input&.upcase

    unless valid_name?(name) && !age.nil? && %w[Y N].include?(permission)
      puts 'Invalid student details'
      return nil
    end

    student = Student.new(age, nil, name, parent_permission: permission == 'Y')
    @people << student
    student
  end

  def create_teacher
    print 'Name: '
    name = read_input

    print 'Age: '
    age = parse_nonnegative_integer(read_input)

    print 'Specialization: '
    specialization = read_input

    unless valid_name?(name) && !age.nil?
      puts 'Invalid teacher details'
      return nil
    end

    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    teacher
  end

  def create_book
    print 'Title: '
    title = read_input

    print 'Author: '
    author = read_input

    unless valid_name?(title) && valid_name?(author)
      puts 'Invalid book details'
      return nil
    end

    book = Book.new(title, author)
    @books << book
    book
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'A book and a person are required to create a rental'
      return nil
    end

    puts 'Select a book by index'
    @books.each_with_index do |book, index|
      puts "#{index}: #{book.title}, #{book.author}"
    end
    book_index = parse_nonnegative_integer(read_input)

    puts 'Select a person by index'
    @people.each_with_index do |person, index|
      puts "#{index}: [#{person.class}] #{person.name}, ID: #{person.id}"
    end
    person_index = parse_nonnegative_integer(read_input)

    unless valid_indices?(person_index, book_index)
      puts 'Invalid book or person index'
      return nil
    end

    print 'Date (YYYY-MM-DD): '
    date = read_input

    if date.nil? || date.empty?
      puts 'Invalid rental date'
      return nil
    end

    rental = Rental.new(date, @books[book_index], @people[person_index])
    @rentals << rental
    rental
  end

  def list_rentals
    print 'ID of person: '
    person_id = parse_nonnegative_integer(read_input)
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

  def read_input
    gets&.strip
  end

  def valid_name?(name)
    name.is_a?(String) && !name.strip.empty?
  end

  def parse_nonnegative_integer(value)
    return nil unless value.is_a?(String) && value.match?(/\A\+?\d+\z/)

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