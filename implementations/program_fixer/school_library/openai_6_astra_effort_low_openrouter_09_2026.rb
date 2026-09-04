require 'date'

class Nameable
  def correct_name
    raise NotImplementedError, 'Subclasses must implement correct_name'
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
    @book.rentals << self
    @person.rentals << self
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
    @label = label
    @students = []
  end

  def add_student(student)
    student.classroom = self
    student
  end
end

class Person < Nameable
  attr_reader :id, :name, :age, :parent_permission, :rentals

  @next_id = 0

  def self.next_id
    @next_id += 1
  end

  def initialize(age = 0, name = 'Unknown', parent_permission: true)
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
    parsed =
      if value.is_a?(Integer)
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
    self.classroom = classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    @classroom.students.delete(self) if @classroom && @classroom != room
    @classroom = room
    room.students << self if room && !room.students.include?(self)
    room
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

class App
  attr_reader :books, :people, :rentals

  def initialize
    @books = []
    @people = []
    @rentals = []
  end

  def list_books
    puts 'No books available' if @books.empty?
    @books.each do |book|
      puts "title: #{book.title}, author: #{book.author}"
    end
  end

  def list_people
    puts 'No one has registered' if @people.empty?
    @people.each do |person|
      puts "[#{person.class}] id: #{person.id}, Name: #{person.name}, Age: #{person.age}"
    end
  end

  def create_person
    print 'Student(1) or Teacher(2)? '
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

    unless age
      puts 'Invalid age: enter a nonnegative integer'
      return nil
    end

    print 'Parent permission? [Y/N]: '
    permission = read_input&.upcase

    unless %w[Y N].include?(permission)
      puts 'Invalid parent permission: enter Y or N'
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

    unless age
      puts 'Invalid age: enter a nonnegative integer'
      return nil
    end

    print 'Specialization: '
    specialization = read_input
    teacher = Teacher.new(age, specialization.to_s, name)
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
      puts 'Add at least one book and one person before creating a rental'
      return nil
    end

    puts 'Select a book'
    @books.each_with_index do |book, index|
      puts "#{index}: #{book.title} by #{book.author}"
    end
    book_index = parse_nonnegative_integer(read_input)

    puts 'Select person'
    @people.each_with_index do |person, index|
      puts "#{index}: [#{person.class}] #{person.name}, ID: #{person.id}"
    end
    person_index = parse_nonnegative_integer(read_input)

    unless valid_indices?(person_index, book_index)
      puts 'Invalid book or person index'
      return nil
    end

    print 'Date (YYYY-MM-DD, blank for today): '
    date = read_input
    date = Date.today.iso8601 if date.nil? || date.empty?

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
      return nil
    end

    puts 'No rentals found' if person.rentals.empty?
    person.rentals.each do |rental|
      puts "#{rental.date} - #{rental.book.title} by #{rental.book.author}"
    end
  end

  private

  def read_input
    gets&.strip
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