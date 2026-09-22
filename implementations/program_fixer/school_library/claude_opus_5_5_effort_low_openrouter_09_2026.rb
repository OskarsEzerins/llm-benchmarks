require 'date'

class Nameable
  def correct_name
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end
end

class Decorator < Nameable
  attr_accessor :nameable

  def initialize(nameable)
    super()
    @nameable = nameable
  end

  def correct_name
    @nameable.correct_name
  end
end

class TrimmerDecorator < Decorator
  def correct_name
    name = super.to_s
    name.length > 10 ? name[0...10] : name
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    name = super.to_s
    return name if name.empty?

    name[0].upcase + name[1..]
  end
end

class Person < Nameable
  attr_accessor :name, :age, :rentals
  attr_reader :id, :parent_permission

  def initialize(age = 0, name = 'Unknown', parent_permission: true)
    super()
    @id = Random.rand(1..10_000)
    @name = name.nil? || name.to_s.strip.empty? ? 'Unknown' : name.to_s
    @age = Person.sanitize_age(age)
    @parent_permission = parent_permission ? true : false
    @rentals = []
  end

  def self.sanitize_age(age)
    value = Integer(age.to_s.strip, exception: false)
    value.nil? || value.negative? ? 0 : value
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

  def initialize(age, classroom, name = 'Unknown', parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom if classroom
  end

  def play_hooky
    '¯\(ツ)/¯'
  end

  def classroom=(room)
    @classroom = room
    return if room.nil?

    room.students << self unless room.students.include?(self)
  end

  alias assign_classroom classroom=
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name = 'Unknown')
    super(age, name, parent_permission: true)
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
    @students << student unless @students.include?(student)
    student.classroom = self
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

class Rental
  attr_accessor :date, :book, :person

  def initialize(date, book, person)
    @date = date
    @book = book
    @person = person
    book.rentals << self
    person.rentals << self
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
    @books.each { |bk| puts "Title: #{bk.title}, Author: #{bk.author}" }
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
      return
    end
    @people.each do |human|
      puts "[#{human.class}] ID: #{human.id}, Name: #{human.name}, Age: #{human.age}"
    end
  end

  def create_person
    print 'Do you want to create a student (1) or a teacher (2)? [Input the number]: '
    choice = read_input
    case choice
    when '1' then create_student
    when '2' then create_teacher
    else
      puts 'Invalid option'
      nil
    end
  end

  def create_student
    print 'Age: '
    age = Person.sanitize_age(read_input)
    print 'Name: '
    name = read_name
    permission = nil
    3.times do
      print 'Has parent permission? [Y/N]: '
      answer = read_input.upcase
      if %w[Y N].include?(answer)
        permission = answer == 'Y'
        break
      end
      puts 'Invalid answer, please enter Y or N'
    end
    permission = false if permission.nil?
    student = Student.new(age, nil, name, parent_permission: permission)
    @people << student
    puts 'Person created successfully'
    student
  end

  def create_teacher
    print 'Age: '
    age = Person.sanitize_age(read_input)
    print 'Name: '
    name = read_name
    print 'Specialization: '
    spec = read_input
    teacher = Teacher.new(age, spec, name)
    @people << teacher
    puts 'Person created successfully'
    teacher
  end

  def create_book
    print 'Title: '
    title = read_input
    print 'Author: '
    author = read_input
    book = Book.new(title, author)
    @books << book
    puts 'Book created successfully'
    book
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'You need at least one book and one person to create a rental'
      return nil
    end

    puts 'Select a book from the following list by number'
    @books.each_with_index { |b, i| puts "#{i}) Title: \"#{b.title}\", Author: #{b.author}" }
    book_index = parse_index(read_input)

    puts 'Select a person from the following list by number (not id)'
    @people.each_with_index do |p, i|
      puts "#{i}) [#{p.class}] Name: #{p.name}, ID: #{p.id}, Age: #{p.age}"
    end
    person_index = parse_index(read_input)

    unless valid_indices?(person_index, book_index)
      puts 'Invalid selection'
      return nil
    end

    print 'Date: '
    date = read_input
    date = Date.today.to_s if date.empty?
    rental = Rental.new(date, @books[book_index], @people[person_index])
    @rentals << rental
    puts 'Rental created successfully'
    rental
  end

  def list_rentals
    print 'ID of person: '
    pid = Integer(read_input, exception: false)
    person = @people.find { |pr| pr.id == pid }
    if person.nil?
      puts 'Person not found'
      return
    end
    if person.rentals.empty?
      puts 'No rentals found'
      return
    end
    puts 'Rentals:'
    person.rentals.each { |r| puts "Date: #{r.date}, Book \"#{r.book.title}\" by #{r.book.author}" }
  end

  private

  def read_input
    input = $stdin.gets
    input.nil? ? '' : input.chomp.strip
  end

  def read_name
    name = read_input
    name.empty? ? 'Unknown' : name
  end

  def parse_index(value)
    Integer(value.to_s.strip, exception: false)
  end

  def valid_indices?(person_index, book_index)
    !person_index.nil? && !book_index.nil? &&
      person_index >= 0 && person_index < @people.length &&
      book_index >= 0 && book_index < @books.length
  end
end