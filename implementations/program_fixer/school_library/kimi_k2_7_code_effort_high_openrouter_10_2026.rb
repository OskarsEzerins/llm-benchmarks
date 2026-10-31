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
    print 'Do you want to create a student(1) or a teacher(2)? [Input the number]: '
    choice = gets.to_s.chomp
    case choice
    when '1'
      create_student
    when '2'
      create_teacher
    else
      puts 'Invalid option'
    end
  end

  def create_student
    print 'Name: '
    name = gets.to_s.chomp
    print 'Age: '
    age_input = gets.to_s.chomp
    age = Integer(age_input) rescue nil

    if age.nil? || age.negative?
      puts 'Invalid age'
      return
    end

    print 'Parent permission? [Y/N]: '
    permission = gets.to_s.chomp.upcase
    parent_permission = permission == 'Y'

    name = 'Unknown' if name.empty?
    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
    puts 'Student created successfully'
  end

  def create_teacher
    print 'Name: '
    name = gets.to_s.chomp
    print 'Age: '
    age_input = gets.to_s.chomp
    age = Integer(age_input) rescue nil

    if age.nil? || age.negative?
      puts 'Invalid age'
      return
    end

    print 'Specialization: '
    specialization = gets.to_s.chomp

    name = 'Unknown' if name.empty?
    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    puts 'Teacher created successfully'
  end

  def create_book
    print 'Title: '
    title = gets.to_s.chomp
    print 'Author: '
    author = gets.to_s.chomp

    title = 'Unknown' if title.empty?
    author = 'Unknown' if author.empty?

    @books << Book.new(title, author)
    puts 'Book created successfully'
  end

  def create_rental
    if @books.empty?
      puts 'No books available'
      return
    end

    if @people.empty?
      puts 'No people registered'
      return
    end

    puts 'Select a book by number:'
    @books.each_with_index { |book, index| puts "#{index}) Title: #{book.title}, Author: #{book.author}" }
    book_index = gets.to_s.chomp.to_i

    puts 'Select a person by number:'
    @people.each_with_index { |person, index| puts "#{index}) [#{person.class}] Name: #{person.name}, ID: #{person.id}, Age: #{person.age}" }
    person_index = gets.to_s.chomp.to_i

    print 'Date [YYYY-MM-DD] (leave blank for today): '
    date = gets.to_s.chomp
    date = Date.today.to_s if date.empty?

    unless valid_indices?(person_index, book_index)
      puts 'Invalid selection'
      return
    end

    Rental.new(date, @books[book_index], @people[person_index])
    puts 'Rental created successfully'
  end

  def list_rentals
    print 'ID of person: '
    id = gets.to_s.chomp.to_i
    person = @people.find { |p| p.id == id }

    if person.nil?
      puts 'Person not found'
      return
    end

    if person.rentals.empty?
      puts 'No rentals for this person'
      return
    end

    person.rentals.each do |rental|
      puts "Date: #{rental.date}, Book: #{rental.book.title} by #{rental.book.author}"
    end
  end

  private

  def valid_indices?(person_index, book_index)
    person_index.between?(0, @people.length - 1) && book_index.between?(0, @books.length - 1)
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, "#{self.class}##{__method__} has not been implemented"
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
    name = super
    return name if name.length <= 10

    name[0...10]
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
  attr_accessor :label
  attr_reader :students

  def initialize(label)
    @label = label
    @students = []
  end

  def add_student(student)
    student.classroom = self
  end
end

class Person < Nameable
  attr_reader :id, :parent_permission
  attr_accessor :name, :age, :rentals

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    super()
    @id = rand(1..1000)
    @name = name
    @age = age
    @parent_permission = parent_permission
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
  attr_accessor :classroom

  def initialize(age, classroom = nil, name = 'Unknown', parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @classroom = classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    @classroom = room
    return if room.nil?

    room.students.push(self) unless room.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name = 'Unknown', parent_permission: true)
    super(name, age, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end