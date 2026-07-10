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
    name = prompt_name
    age = prompt_age
    permission = prompt_parent_permission

    student = Student.new(age, nil, name, parent_permission: permission)
    @people << student
    student
  end

  def create_teacher
    name = prompt_name
    age = prompt_age

    print 'Specialization: '
    specialization = read_input
    specialization = 'Unknown' if specialization.nil? || specialization.empty?

    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    teacher
  end

  def create_book
    print 'Title: '
    title = read_input
    title = 'Untitled' if title.nil? || title.empty?

    print 'Author: '
    author = read_input
    author = 'Unknown' if author.nil? || author.empty?

    book = Book.new(title, author)
    @books << book
    book
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'Books and people must be available to create a rental'
      return nil
    end

    puts 'Select a book'
    @books.each_with_index do |book, index|
      puts "#{index}: #{book.title} by #{book.author}"
    end
    book_index = integer_input

    puts 'Select a person'
    @people.each_with_index do |person, index|
      puts "#{index}: #{person.name}"
    end
    person_index = integer_input

    unless valid_indices?(person_index, book_index)
      puts 'Invalid book or person selection'
      return nil
    end

    print 'Date (YYYY-MM-DD, leave blank for today): '
    date = read_input
    date = Date.today.to_s if date.nil? || date.empty?

    Rental.new(date, @books[book_index], @people[person_index])
  end

  def list_rentals
    print 'ID of person: '
    id_input = read_input

    unless id_input&.match?(/\A\d+\z/)
      puts 'Invalid person ID'
      return []
    end

    person = @people.find { |entry| entry.id == id_input.to_i }

    unless person
      puts 'Person not found'
      return []
    end

    person.rentals.each do |rental|
      puts "#{rental.date} - #{rental.book.title} by #{rental.book.author}"
    end
  end

  private

  def read_input
    input = gets
    input&.chomp&.strip
  end

  def integer_input
    input = read_input
    return nil unless input&.match?(/\A\d+\z/)

    input.to_i
  end

  def prompt_name
    print 'Name: '
    name = read_input
    name.nil? || name.empty? ? 'Unknown' : name
  end

  def prompt_age
    loop do
      print 'Age: '
      input = read_input
      return input.to_i if input&.match?(/\A\d+\z/)

      puts 'Age must be a non-negative integer'
      return 0 if input.nil?
    end
  end

  def prompt_parent_permission
    loop do
      print 'Parent permission? [Y/N]: '
      input = read_input&.upcase

      return true if input == 'Y'
      return false if input == 'N'

      puts 'Please enter Y or N'
      return false if input.nil?
    end
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
  attr_accessor :date, :book, :person

  def initialize(date, book, person)
    raise ArgumentError, 'A valid book is required' unless book.respond_to?(:rentals)
    raise ArgumentError, 'A valid person is required' unless person.respond_to?(:rentals)

    @date = date
    @book = book
    @person = person

    book.rentals << self unless book.rentals.include?(self)
    person.rentals << self unless person.rentals.include?(self)
  end
end

class Book
  attr_accessor :title, :author, :rentals

  def initialize(title, author)
    @title = title.nil? || title.to_s.empty? ? 'Untitled' : title.to_s
    @author = author.nil? || author.to_s.empty? ? 'Unknown' : author.to_s
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
    return student if @students.include?(student)

    @students << student
    student.classroom = self unless student.classroom.equal?(self)
    student
  end
end

class Person < Nameable
  attr_accessor :name, :rentals
  attr_reader :id, :age, :parent_permission

  def initialize(age = 0, name = 'Unknown', parent_permission: true)
    @id = rand(1..1_000_000)
    self.age = age
    self.name = name
    self.parent_permission = parent_permission
    @rentals = []
  end

  def age=(value)
    integer_age =
      if value.is_a?(Integer)
        value
      elsif value.to_s.match?(/\A\d+\z/)
        value.to_i
      else
        0
      end

    @age = [integer_age, 0].max
  end

  def name=(value)
    text = value&.to_s&.strip
    @name = text.nil? || text.empty? ? 'Unknown' : text
  end

  def parent_permission=(value)
    @parent_permission =
      case value
      when true, false
        value
      when String
        value.strip.casecmp('y').zero? || value.strip.casecmp('yes').zero?
      else
        !!value
      end
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
    self.classroom = classroom if classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    return @classroom = nil if room.nil?
    raise ArgumentError, 'A valid classroom is required' unless room.respond_to?(:students)

    if @classroom && !@classroom.equal?(room)
      @classroom.students.delete(self)
    end

    @classroom = room
    room.students << self unless room.students.include?(self)
    room
  end

  alias assign_classroom classroom=
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name = 'Unknown')
    super(age, name, parent_permission: true)
    @specialization =
      if specialization.nil? || specialization.to_s.strip.empty?
        'Unknown'
      else
        specialization.to_s
      end
  end

  def can_use_services?
    true
  end
end