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
    print 'Student(2) or Teacher(1)? '
    choice = gets&.to_s&.strip

    case choice
    when '1'
      create_teacher
    when '2', '3'
      create_student
    else
      nil
    end
  end

  def create_student
    print 'Name: '
    name = gets&.to_s&.strip

    print 'Age: '
    age = gets&.to_s&.strip

    print 'Parent permission? '
    permission = gets&.to_s&.strip

    student = Student.new(
      age,
      nil,
      name,
      parent_permission: permission.to_s.upcase == 'Y'
    )
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
    return nil unless @books.any? && @people.any?

    puts 'Select a book'
    @books.each_with_index do |book, index|
      puts "#{index}: #{book.title}"
    end
    book_index = gets&.to_s&.strip.to_i

    puts 'Select person'
    @people.each_with_index do |person, index|
      puts "#{index}: #{person.name}"
    end
    person_index = gets&.to_s&.strip.to_i

    return nil unless valid_indices?(person_index, book_index)

    Rental.new(Date.today, @books[book_index], @people[person_index])
  end

  def list_rentals
    print 'ID of person: '
    person_id = gets&.to_s&.strip.to_i
    person = @people.find { |item| item.id == person_id }

    return nil unless person

    person.rentals.each do |rental|
      puts "#{rental.date} - #{rental.book.title}"
    end
  end

  private

  def valid_indices?(person_index, book_index)
    person_index.is_a?(Integer) &&
      book_index.is_a?(Integer) &&
      person_index >= 0 &&
      person_index < @people.length &&
      book_index >= 0 &&
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
    @title = title.to_s
    @author = author.to_s
    @rentals = []
  end

  def add_rental(person, date)
    Rental.new(date, self, person)
  end
end

class Classroom
  attr_accessor :label, :students

  def initialize(label)
    @label = label
    @students = []
  end

  def add_student(student)
    return unless student

    @students << student unless @students.include?(student)
    student.assign_classroom(self) unless student.classroom.equal?(self)
    student
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals
  attr_reader :parent_permission

  def initialize(age = 0, name = 'Unknown', parent_permission: true)
    @id = rand(1..1_000_000)
    @age = normalize_age(age)
    @name = normalize_name(name)
    @parent_permission = !!parent_permission
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

  def normalize_age(value)
    integer = Integer(value, exception: false)
    integer && integer >= 0 ? integer : 0
  end

  def normalize_name(value)
    text = value.to_s.strip
    text.empty? ? 'Unknown' : text
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
    assign_classroom(classroom) if classroom
  end

  def play_hooky
    '¯(ツ)/¯'
  end

  def assign_classroom(classroom)
    return unless classroom

    @classroom = classroom
    classroom.students << self unless classroom.students.include?(self)
    self
  end

  def classroom=(classroom)
    assign_classroom(classroom)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization = nil, name = 'Unknown')
    if age.is_a?(String) && !age.match?(/\A\d+\z/)
      actual_name = age
      actual_specialization = specialization
      actual_age = name
    else
      actual_age = age
      actual_specialization = specialization
      actual_name = name
    end

    super(actual_age, actual_name, parent_permission: true)
    @specialization = actual_specialization.to_s
  end

  def can_use_services?
    true
  end
end.alias_method :can_use_services?, :can_use_services?