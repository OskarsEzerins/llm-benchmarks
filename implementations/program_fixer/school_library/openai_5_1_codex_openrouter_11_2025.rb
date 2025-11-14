require 'date'

class App
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
      puts "Title: \"#{book.title}\", Author: #{book.author}"
    end
  end

  def list_people
    if @people.empty?
      puts 'No people available'
      return
    end

    @people.each do |person|
      puts "[#{person.class.name}] ID: #{person.id}, Name: #{person.name}, Age: #{person.age}"
    end
  end

  def create_person
    puts 'Do you want to create a student (1) or a teacher (2)? [Input the number]:'
    choice = gets&.chomp
    case choice
    when '1'
      create_student
    when '2'
      create_teacher
    else
      puts 'Invalid selection.'
    end
  end

  def create_student
    name = prompt_name
    age = prompt_age
    parent_permission = prompt_parent_permission
    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
    puts 'Student created successfully'
  end

  def create_teacher
    name = prompt_name
    age = prompt_age
    print 'Specialization: '
    specialization = sanitize_name(gets)
    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    puts 'Teacher created successfully'
  end

  def create_book
    print 'Title: '
    title = sanitize_name(gets)
    print 'Author: '
    author = sanitize_name(gets)
    @books << Book.new(title, author)
    puts 'Book created successfully'
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'Books and people are required to create a rental.'
      return
    end

    puts 'Select a book from the following list by number'
    @books.each_with_index { |book, index| puts "#{index}) Title: \"#{book.title}\", Author: #{book.author}" }
    book_index = safe_index(gets)
    unless valid_index?(@books, book_index)
      puts 'Invalid book selection.'
      return
    end

    puts 'Select a person from the following list by number (not id)'
    @people.each_with_index do |person, index|
      puts "#{index}) [#{person.class.name}] Name: #{person.name}, ID: #{person.id}, Age: #{person.age}"
    end
    person_index = safe_index(gets)
    unless valid_index?(@people, person_index)
      puts 'Invalid person selection.'
      return
    end

    print 'Date (YYYY-MM-DD): '
    date = sanitize_date(gets)

    rental = Rental.new(date, @books[book_index], @people[person_index])
    @rentals << rental
    puts 'Rental created successfully'
  end

  def list_rentals
    print 'ID of person: '
    person_id = safe_integer(gets)
    if person_id.nil?
      puts 'Invalid ID'
      return
    end

    person = @people.find { |pr| pr.id == person_id }
    if person.nil?
      puts 'Person not found'
      return
    end

    if person.rentals.empty?
      puts 'No rentals found for this person'
      return
    end

    person.rentals.each do |rental|
      puts "#{rental.date} - Book: \"#{rental.book.title}\" by #{rental.book.author}"
    end
  end

  private

  def prompt_name
    print 'Name: '
    sanitize_name(gets)
  end

  def prompt_age
    print 'Age: '
    sanitize_age(gets)
  end

  def prompt_parent_permission
    print 'Has parent permission? [Y/N]: '
    interpret_permission(gets)
  end

  def sanitize_name(input)
    value = input.to_s.strip
    value.empty? ? 'Unknown' : value
  end

  def sanitize_age(input)
    age = safe_integer(input)
    age = 0 if age.nil?
    age.negative? ? 0 : age
  end

  def interpret_permission(input)
    value = input.to_s.strip.downcase
    case value
    when 'y', 'yes' then true
    when 'n', 'no' then false
    else
      puts 'Invalid input, assuming "no".'
      false
    end
  end

  def sanitize_date(input)
    value = input.to_s.strip
    return Date.today.to_s if value.empty?

    Date.parse(value).to_s
  rescue ArgumentError
    Date.today.to_s
  end

  def safe_integer(input)
    Integer(input.to_s.strip)
  rescue ArgumentError, TypeError
    nil
  end

  def safe_index(input)
    value = safe_integer(input)
    return nil if value.nil? || value.negative?

    value
  end

  def valid_index?(collection, index)
    !index.nil? && index < collection.length
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, 'Subclasses must implement the correct_name method'
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
    name = super.to_s
    return name if name.length <= 10

    name[0, 10]
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    super.to_s.capitalize
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
  attr_reader :title, :author, :rentals

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
    return if student.nil?

    @students << student unless @students.include?(student)
    student.assign_classroom(self) unless student.classroom == self
  end
end

class Person < Nameable
  attr_reader :id, :parent_permission
  attr_accessor :name, :age, :rentals

  @@id_counter = 1

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id = @@id_counter
    @@id_counter += 1
    @name = name
    @age = age.to_i
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

  def initialize(age, classroom, name, parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    self.classroom = classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    @classroom = room
    return if room.nil?

    room.students << self unless room.students.include?(self)
  end

  def assign_classroom(room)
    self.classroom = room
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name, parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end