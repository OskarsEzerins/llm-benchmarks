require 'date'

class Nameable
  def correct_name
    raise NotImplementedError, "#{self.class} must implement correct_name"
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

  def self.next_id
    @next_id = (@next_id || 0) + 1
  end

  def initialize(age, name = 'Unknown', parent_permission: true)
    @id = Person.next_id
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

  def initialize(age, classroom = nil, name = 'Unknown', parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom unless classroom.nil?
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
    self.book = book
    self.person = person
  end

  def book=(book)
    @book.rentals.delete(self) if @book && @book != book
    @book = book
    @book.rentals << self unless @book.rentals.include?(self)
  end

  def person=(person)
    @person.rentals.delete(self) if @person && @person != person
    @person = person
    @person.rentals << self unless @person.rentals.include?(self)
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
    print 'Student(1) or Teacher(2)? '

    case read_input
    when '1'
      create_student
    when '2'
      create_teacher
    else
      puts 'Invalid selection. Choose 1 for Student or 2 for Teacher.'
      nil
    end
  end

  def create_student
    print 'Name: '
    name = read_input
    unless valid_name?(name)
      puts 'Name cannot be empty.'
      return
    end

    print 'Age: '
    age = parse_nonnegative_integer(read_input)
    if age.nil?
      puts 'Age must be a nonnegative integer.'
      return
    end

    print 'Parent permission? (Y/N): '
    permission = read_input&.upcase
    unless %w[Y N].include?(permission)
      puts 'Invalid parent permission. Enter Y or N.'
      return
    end

    student = Student.new(age, nil, name, parent_permission: permission == 'Y')
    @people << student
    puts 'Student created successfully.'
    student
  end

  def create_teacher
    print 'Name: '
    name = read_input
    unless valid_name?(name)
      puts 'Name cannot be empty.'
      return
    end

    print 'Age: '
    age = parse_nonnegative_integer(read_input)
    if age.nil?
      puts 'Age must be a nonnegative integer.'
      return
    end

    print 'Specialization: '
    specialization = read_input
    if specialization.nil? || specialization.empty?
      puts 'Specialization cannot be empty.'
      return
    end

    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    puts 'Teacher created successfully.'
    teacher
  end

  def create_book
    print 'Title: '
    title = read_input
    if title.nil? || title.empty?
      puts 'Title cannot be empty.'
      return
    end

    print 'Author: '
    author = read_input
    if author.nil? || author.empty?
      puts 'Author cannot be empty.'
      return
    end

    book = Book.new(title, author)
    @books << book
    puts 'Book created successfully.'
    book
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'At least one book and one person are required to create a rental.'
      return
    end

    puts 'Select a book by index:'
    @books.each_with_index do |book, index|
      puts "#{index}: #{book.title} by #{book.author}"
    end

    book_index = parse_nonnegative_integer(read_input)
    unless valid_index?(book_index, @books)
      puts 'Invalid book index.'
      return
    end

    puts 'Select a person by index:'
    @people.each_with_index do |person, index|
      puts "#{index}: [#{person.class}] #{person.name}, ID: #{person.id}"
    end

    person_index = parse_nonnegative_integer(read_input)
    unless valid_indices?(person_index, book_index)
      puts 'Invalid person index.'
      return
    end

    print 'Date (YYYY-MM-DD, blank for today): '
    date = read_input
    date = Date.today.iso8601 if date.nil? || date.empty?

    rental = Rental.new(date, @books[book_index], @people[person_index])
    @rentals << rental
    puts 'Rental created successfully.'
    rental
  end

  def list_rentals
    print 'ID of person: '
    person_id = parse_nonnegative_integer(read_input)
    if person_id.nil?
      puts 'Invalid person ID.'
      return
    end

    person = @people.find { |candidate| candidate.id == person_id }
    unless person
      puts 'Person not found.'
      return
    end

    if person.rentals.empty?
      puts 'No rentals found for this person.'
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
    !name.nil? && !name.empty?
  end

  def parse_nonnegative_integer(value)
    return nil unless value.is_a?(String) && value.match?(/\A\d+\z/)

    value.to_i
  end

  def valid_index?(index, collection)
    index.is_a?(Integer) && index >= 0 && index < collection.length
  end

  def valid_indices?(person_index, book_index)
    valid_index?(person_index, @people) && valid_index?(book_index, @books)
  end
end