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
    print 'Student(1) or Teacher(2)? '
    choice = gets&.to_s&.strip

    case choice
    when '1', '3'
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
    name = gets&.to_s&.strip

    print 'Age: '
    age = gets&.to_s&.strip

    print 'Parent permission? '
    permission = gets&.to_s&.strip.upcase
    parent_permission = permission == 'Y'

    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
    student
  end

  def create_teacher
    print 'Name: '
    name = gets&.to_s&.strip

    print 'Age: '
    age = gets&.to_s&.strip

    print 'Specialization: '
    specialization = gets&.to_s&.strip

    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    teacher
  end

  def create_book
    print 'Title: '
    title = gets&.to_s&.strip

    print 'Author: '
    author = gets&.to_s&.strip

    book = Book.new(title, author)
    @books << book
    book
  end

  def create_rental
    return nil if @books.empty? || @people.empty?

    puts 'Select a book'
    @books.each_with_index do |book, index|
      puts "#{index}: #{book.title}"
    end
    book_index = integer_input(gets)

    puts 'Select person'
    @people.each_with_index do |person, index|
      puts "#{index}: #{person.name}"
    end
    person_index = integer_input(gets)

    return nil unless valid_indices?(person_index, book_index)

    print 'Date: '
    date = gets&.to_s&.strip
    date = Date.today.to_s if date.nil? || date.empty?

    Rental.new(date, @books[book_index], @people[person_index])
  end

  def list_rentals
    print 'ID of person: '
    person_id = integer_input(gets)
    person = @people.find { |individual| individual.id == person_id }

    return puts('No rentals found') if person.nil? || person.rentals.empty?

    person.rentals.each do |rental|
      puts "#{rental.date} - #{rental.book.title}"
    end
  end

  private

  def integer_input(value)
    Integer(value.to_s.strip, 10)
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
    @date = date
    @book = book
    @person = person

    @book.rentals << self unless @book.rentals.include?(self)
    @person.rentals << self unless @person.rentals.include?(self)
  end
end

class Book
  attr_accessor :title, :author, :rentals

  def initialize(title, author)
    @title = title.nil? ? '' : title.to_s
    @author = author.nil? ? '' : author.to_s
    @rentals = []
  end

  def add_rental(person, date)
    Rental.new(date, self, person)
  end
end

class Classroom
  attr_accessor :label, :students

  def initialize(label)
    @label = label.nil? ? '' : label.to_s
    @students = []
  end

  def add_student(student)
    return if student.nil?

    @students << student unless @students.include?(student)
    student.assign_classroom(self) unless student.classroom.equal?(self)
    student
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals
  attr_reader :parent_permission

  @@next_id = 1

  def initialize(age = 0, name = 'Unknown', parent_permission: true)
    if !numeric_value?(age) && numeric_value?(name)
      age, name = name, age
    end

    @id = @@next_id
    @@next_id += 1
    @name = name.nil? || name.to_s.strip.empty? ? 'Unknown' : name.to_s
    @age = normalize_age(age)
    @parent_permission = parent_permission == true
    @rentals = []
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

  def normalize_age(value)
    Integer(value.to_s.strip, 10)
  rescue ArgumentError, TypeError
    0
  end

  def numeric_value?(value)
    Integer(value.to_s.strip, 10)
    true
  rescue ArgumentError, TypeError
    false
  end
end

class Student < Person
  attr_reader :classroom

  def initialize(age, classroom, name, parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom unless classroom.nil?
  end

  def play_hooky
    '¯(ツ)/¯'
  end

  def classroom=(room)
    return @classroom = nil if room.nil?

    @classroom = room
    room.students << self unless room.students.include?(self)
    room
  end

  def assign_classroom(room)
    self.classroom = room
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age = 0, specialization = '', name = 'Unknown')
    if !numeric_value_for_teacher?(age) && numeric_value_for_teacher?(name)
      age, name = name, age
    end

    super(age, name)
    @specialization = specialization.nil? ? '' : specialization.to_s
  end

  def can_use_services?
    true
  end

  private

  def numeric_value_for_teacher?(value)
    Integer(value.to_s.strip, 10)
    true
  rescue ArgumentError, TypeError
    false
  end
end