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

class Person < Nameable
  attr_reader :id, :name, :age, :parent_permission, :rentals

  @@next_id = 0

  def initialize(age = 0, name = 'Unknown', parent_permission: true)
    @id = (@@next_id += 1)
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
    normalized = value.is_a?(String) ? value.strip : value

    @age =
      if normalized.is_a?(Integer) && normalized >= 0
        normalized
      elsif normalized.is_a?(String) && normalized.match?(/\A[0-9]+\z/)
        normalized.to_i
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

  def initialize(age, classroom = nil, name = 'Unknown', parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    if @classroom && @classroom != room
      @classroom.students.delete(self)
    end

    @classroom = room

    if room && !room.students.include?(self)
      room.students << self
    end

    @classroom
  end

  alias_method :assign_classroom, :classroom=
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
  attr_accessor :date
  attr_reader :book, :person

  def initialize(date, book, person)
    @date = date
    @book = book
    @person = person

    @book.rentals << self
    @person.rentals << self
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
    choice = read_text('Student(1) or Teacher(2)? ')

    case choice
    when '1'
      create_student
    when '2'
      create_teacher
    else
      puts 'Invalid selection. Please choose 1 or 2.'
      nil
    end
  end

  def create_student
    name = read_text('Name: ')
    unless valid_name?(name)
      puts 'Name cannot be empty.'
      return
    end

    age = parse_non_negative_integer(read_text('Age: '))
    if age.nil?
      puts 'Age must be a non-negative integer.'
      return
    end

    permission = read_text('Parent permission? [Y/N]: ')&.upcase
    unless %w[Y N].include?(permission)
      puts 'Invalid parent permission. Please enter Y or N.'
      return
    end

    student = Student.new(age, nil, name, parent_permission: permission == 'Y')
    @people << student
    puts 'Student created successfully.'
    student
  end

  def create_teacher
    name = read_text('Name: ')
    unless valid_name?(name)
      puts 'Name cannot be empty.'
      return
    end

    age = parse_non_negative_integer(read_text('Age: '))
    if age.nil?
      puts 'Age must be a non-negative integer.'
      return
    end

    specialization = read_text('Specialization: ')
    if specialization.nil?
      puts 'No specialization provided.'
      return
    end

    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    puts 'Teacher created successfully.'
    teacher
  end

  def create_book
    title = read_text('Title: ')
    author = read_text('Author: ')

    unless valid_name?(title) && valid_name?(author)
      puts 'Title and author cannot be empty.'
      return
    end

    book = Book.new(title, author)
    @books << book
    puts 'Book created successfully.'
    book
  end

  def create_rental(date = Date.today)
    if @books.empty?
      puts 'No books available'
      return
    end

    if @people.empty?
      puts 'No one has registered'
      return
    end

    puts 'Select a book'
    @books.each_with_index do |book, index|
      puts "#{index}: #{book.title} by #{book.author}"
    end

    book_index = parse_non_negative_integer(read_text('Book index: '))
    if book_index.nil? || book_index >= @books.length
      puts 'Invalid book index.'
      return
    end

    puts 'Select person'
    @people.each_with_index do |person, index|
      puts "#{index}: [#{person.class}] #{person.name}, ID: #{person.id}"
    end

    person_index = parse_non_negative_integer(read_text('Person index: '))
    unless valid_indices?(person_index, book_index)
      puts 'Invalid person index.'
      return
    end

    rental = Rental.new(date, @books[book_index], @people[person_index])
    @rentals << rental
    puts 'Rental created successfully.'
    rental
  end

  def list_rentals
    person_id = parse_non_negative_integer(read_text('ID of person: '))
    if person_id.nil?
      puts 'Invalid person ID.'
      return
    end

    person = @people.find { |registered_person| registered_person.id == person_id }
    unless person
      puts 'Person not found.'
      return
    end

    if person.rentals.empty?
      puts 'No rentals found for this person.'
      return
    end

    person.rentals.each do |rental|
      puts "#{rental.date} - #{rental.book.title}"
    end
  end

  private

  def read_text(prompt)
    print prompt
    gets&.strip
  end

  def valid_name?(value)
    value.is_a?(String) && !value.strip.empty?
  end

  def parse_non_negative_integer(value)
    return nil unless value.is_a?(String)

    value = value.strip
    return nil unless value.match?(/\A[0-9]+\z/)

    value.to_i
  end

  def valid_indices?(person_index, book_index)
    person_index.is_a?(Integer) &&
      book_index.is_a?(Integer) &&
      person_index >= 0 &&
      person_index < @people.length &&
      book_index >= 0 &&
      book_index < @books.length
  end
end