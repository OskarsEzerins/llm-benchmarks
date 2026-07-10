require 'date'

class App
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
      puts "Title: #{book.title}, Author: #{book.author}"
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
    print 'Do you want to create a student (1) or a teacher (2)? '
    choice = gets&.chomp

    case choice
    when '1', '3'
      create_student
    when '2'
      create_teacher
    else
      puts 'Invalid selection'
    end
  end

  def create_student
    print 'Name: '
    name = gets&.chomp

    print 'Age: '
    age = valid_age(gets&.chomp)
    return puts('Invalid age') if age.nil?

    print 'Parent permission? [Y/N]: '
    permission_input = gets&.chomp&.upcase
    unless %w[Y N].include?(permission_input)
      puts 'Invalid parent permission response'
      return
    end

    student = Student.new(age, nil, name, parent_permission: permission_input == 'Y')
    @people << student
    puts 'Person created successfully'
  end

  def create_teacher
    print 'Name: '
    name = gets&.chomp

    print 'Age: '
    age = valid_age(gets&.chomp)
    return puts('Invalid age') if age.nil?

    print 'Specialization: '
    specialization = gets&.chomp

    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    puts 'Person created successfully'
  end

  def create_book
    print 'Title: '
    title = gets&.chomp

    print 'Author: '
    author = gets&.chomp

    @books << Book.new(title, author)
    puts 'Book created successfully'
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'Books and people must exist before creating a rental'
      return
    end

    puts 'Select a book from the following list by number'
    @books.each_with_index do |book, index|
      puts "#{index}) Title: #{book.title}, Author: #{book.author}"
    end

    book_index = valid_index(gets&.chomp, @books.length)
    return puts('Invalid book selection') if book_index.nil?

    puts 'Select a person from the following list by number'
    @people.each_with_index do |person, index|
      puts "#{index}) [#{person.class}] Name: #{person.name}, ID: #{person.id}, Age: #{person.age}"
    end

    person_index = valid_index(gets&.chomp, @people.length)
    return puts('Invalid person selection') if person_index.nil?

    Rental.new(Date.today, @books[book_index], @people[person_index])
    puts 'Rental created successfully'
  end

  def list_rentals
    print 'ID of person: '
    person_id = Integer(gets&.chomp, exception: false)

    if person_id.nil?
      puts 'Invalid person ID'
      return
    end

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
      puts "Date: #{rental.date}, Book: \"#{rental.book.title}\" by #{rental.book.author}"
    end
  end

  private

  def valid_age(value)
    age = Integer(value, exception: false)
    age if age && age >= 0
  end

  def valid_index(value, length)
    index = Integer(value, exception: false)
    index if index && index.between?(0, length - 1)
  end

  def valid_indices?(person_index, book_index)
    person_index.between?(0, @people.length - 1) &&
      book_index.between?(0, @books.length - 1)
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, 'correct_name must be implemented'
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
  attr_reader :date, :book, :person

  def initialize(date, book, person)
    @date = date
    @book = book
    @person = person

    book.rentals << self unless book.rentals.include?(self)
    person.rentals << self unless person.rentals.include?(self)
  end
end

class Book
  attr_accessor :title, :author
  attr_reader :rentals

  def initialize(title, author)
    @title = normalize_text(title, 'Unknown')
    @author = normalize_text(author, 'Unknown')
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
    return unless student.is_a?(Student)

    student.classroom = self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :parent_permission
  attr_reader :rentals

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id = rand(1..999_999)
    @name = normalize_name(name)
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

  def normalize_name(value)
    name = value.to_s.strip
    name.empty? ? 'Unknown' : name
  end

  def normalize_age(value)
    age = Integer(value, exception: false)
    age && age >= 0 ? age : 0
  end
end

class Student < Person
  attr_reader :classroom

  def initialize(age, classroom = nil, name = 'Unknown', parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom if classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    return unless room.is_a?(Classroom)
    return if @classroom == room

    @classroom.students.delete(self) if @classroom
    @classroom = room
    room.students << self unless room.students.include?(self)
  end

  def assign_classroom(room)
    self.classroom = room
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name = 'Unknown')
    super(name, age, parent_permission: true)
    @specialization = specialization.to_s
  end

  def can_use_services?
    true
  end
end