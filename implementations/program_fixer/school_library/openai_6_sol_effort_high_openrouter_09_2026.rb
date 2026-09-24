require 'date'

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

class Classroom
  attr_accessor :label
  attr_reader :students

  def initialize(label)
    @label = label
    @students = []
  end

  def add_student(student)
    return nil unless student.is_a?(Student)

    student.classroom = self
    student
  end
end

class Person < Nameable
  attr_reader :id, :name, :age, :rentals, :parent_permission

  @@next_id = 0

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @@next_id += 1
    @id = @@next_id
    self.name = name
    self.age = age
    self.parent_permission = parent_permission
    @rentals = []
  end

  def name=(value)
    normalized = value.to_s.strip
    @name = normalized.empty? ? 'Unknown' : normalized
  end

  def age=(value)
    @age =
      if value.is_a?(Integer) && value >= 0
        value
      elsif value.is_a?(String) && value.strip.match?(/\A\d+\z/)
        value.strip.to_i
      else
        0
      end
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

  def initialize(age, classroom, name, parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom unless classroom.nil?
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    return nil unless room.nil? || room.is_a?(Classroom)

    @classroom.students.delete(self) if @classroom && !@classroom.equal?(room)
    @classroom = room
    room.students << self if room && !room.students.include?(self)
    room
  end

  alias assign_classroom classroom=
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name)
    super(name, age)
    @specialization = specialization
  end

  def can_use_services?
    true
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
      puts "title: #{book.title}, author: #{book.author}"
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
      return
    end

    @people.each do |person|
      puts "[#{person.class}] id: #{person.id}, Name: #{person.name}, Age: #{person.age}"
    end
  end

  def create_person
    print 'Student (1) or Teacher (2)? '
    case gets&.strip
    when '1' then create_student
    when '2' then create_teacher
    else
      puts 'Invalid selection'
      nil
    end
  end

  def create_student
    print 'Name: '
    name = gets
    return nil if name.nil?

    print 'Age: '
    age = parse_nonnegative_integer(gets)
    unless age
      puts 'Invalid age'
      return nil
    end

    print 'Parent permission? (Y/N): '
    permission = gets&.strip&.upcase
    unless %w[Y N].include?(permission)
      puts 'Invalid parent permission'
      return nil
    end

    student = Student.new(age, nil, name, parent_permission: permission == 'Y')
    @people << student
    student
  end

  def create_teacher
    print 'Name: '
    name = gets
    return nil if name.nil?

    print 'Age: '
    age = parse_nonnegative_integer(gets)
    unless age
      puts 'Invalid age'
      return nil
    end

    print 'Specialization: '
    specialization = gets
    return nil if specialization.nil?

    teacher = Teacher.new(age, specialization.strip, name)
    @people << teacher
    teacher
  end

  def create_book
    print 'Title: '
    title = gets
    return nil if title.nil?

    print 'Author: '
    author = gets
    return nil if author.nil?

    book = Book.new(title.strip, author.strip)
    @books << book
    book
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'A book and a person are required to create a rental'
      return nil
    end

    puts 'Select a book'
    @books.each_with_index { |book, index| puts "#{index}: #{book.title}" }
    book_index = parse_nonnegative_integer(gets)

    puts 'Select a person'
    @people.each_with_index { |person, index| puts "#{index}: #{person.name}" }
    person_index = parse_nonnegative_integer(gets)

    unless valid_indices?(person_index, book_index)
      puts 'Invalid selection'
      return nil
    end

    Rental.new(Date.today, @books[book_index], @people[person_index])
  end

  def list_rentals
    print 'ID of person: '
    id = parse_nonnegative_integer(gets)
    person = @people.find { |entry| entry.id == id }

    unless person
      puts 'Person not found'
      return nil
    end

    person.rentals.each do |rental|
      puts "#{rental.date} - #{rental.book.title}"
    end
  end

  private

  def parse_nonnegative_integer(value)
    return nil unless value.is_a?(String) && value.strip.match?(/\A\d+\z/)

    value.strip.to_i
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