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
    choice = gets&.chomp

    case choice
    when '1'
      create_teacher
    when '2', '3'
      create_student
    else
      puts 'Invalid selection'
      nil
    end
  end

  def create_student
    print 'Name: '
    name = gets&.chomp.to_s

    print 'Age: '
    age = parse_age(gets&.chomp)

    print 'Parent permission? [Y/N]: '
    permission = parse_permission(gets&.chomp)

    student = Student.new(age, nil, name, parent_permission: permission)
    @people << student
    student
  end

  def create_teacher
    print 'Name: '
    name = gets&.chomp.to_s

    print 'Age: '
    age = parse_age(gets&.chomp)

    print 'Specialization: '
    specialization = gets&.chomp.to_s

    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    teacher
  end

  def create_book
    print 'Title: '
    title = gets&.chomp.to_s

    print 'Author: '
    author = gets&.chomp.to_s

    book = Book.new(title, author)
    @books << book
    book
  end

  def create_rental
    return nil unless valid_indices?

    puts 'Select a book'
    @books.each_with_index { |book, index| puts "#{index}: #{book.title}" }
    book_index = gets&.chomp.to_i

    puts 'Select person'
    @people.each_with_index { |person, index| puts "#{index}: #{person.name}" }
    person_index = gets&.chomp.to_i

    return nil unless valid_indices?(person_index, book_index)

    print 'Date: '
    date = gets&.chomp
    Rental.new(date, @books[book_index], @people[person_index])
  end

  def list_rentals
    print 'ID of person: '
    person_id = gets&.chomp.to_i
    person = @people.find { |item| item.id == person_id }

    return puts('No rentals found') unless person

    person.rentals.each do |rental|
      puts "#{rental.date} - #{rental.book.title}"
    end
  end

  private

  def parse_age(value)
    age = Integer(value, exception: false)
    age && age >= 0 ? age : 0
  end

  def parse_permission(value)
    value.to_s.strip.upcase == 'Y'
  end

  def valid_indices?(person_index = nil, book_index = nil)
    return false if @people.empty? || @books.empty?
    return true if person_index.nil? || book_index.nil?

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
    @title = title
    @author = author
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
    @students << student unless @students.include?(student)
    student.assign_classroom(self) unless student.classroom.equal?(self)
    self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals
  attr_reader :parent_permission

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id = rand(1..1_000_000)
    @name = name.to_s
    @age = Integer(age, exception: false) || 0
    @age = 0 if @age.negative?
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

  def of_age?
    @age >= 18
  end
end

class Student < Person
  attr_reader :classroom

  def initialize(age, classroom = nil, name = 'Unknown', parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @classroom = nil
    assign_classroom(classroom) if classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def assign_classroom(room)
    return unless room

    @classroom = room
    room.students << self unless room.students.include?(self)
    self
  end

  def classroom=(room)
    assign_classroom(room)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name = 'Unknown')
    super(name, age, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end