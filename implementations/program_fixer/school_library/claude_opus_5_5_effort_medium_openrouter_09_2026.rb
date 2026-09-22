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
    super.to_s.capitalize
  end
end

class Rental
  attr_accessor :date
  attr_reader :book, :person

  def initialize(date, book, person)
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
    @students << student unless @students.include?(student)
    student.classroom = self unless student.classroom.equal?(self)
  end
end

class Person < Nameable
  attr_reader :id, :age, :rentals, :parent_permission
  attr_accessor :name

  def initialize(age = 0, name = 'Unknown', parent_permission: true)
    super()
    # Support both (age, name) and (name, age) argument orders
    age, name = name, age if age.is_a?(String) && !name.is_a?(String)
    age, name = name, age if age.is_a?(String) && name.is_a?(String) && age !~ /\A-?\d+\z/ && name =~ /\A-?\d+\z/
    @id = rand(1..10_000)
    @name = Person.sanitize_name(name)
    @age = Person.sanitize_age(age)
    @parent_permission = Person.to_bool(parent_permission)
    @rentals = []
  end

  def age=(value)
    @age = Person.sanitize_age(value)
  end

  def parent_permission=(value)
    @parent_permission = Person.to_bool(value)
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

  def self.sanitize_name(name)
    str = name.nil? ? '' : name.to_s.strip
    str.empty? ? 'Unknown' : str
  end

  def self.sanitize_age(age)
    value = case age
            when Integer then age
            when Float then age.to_i
            when String then age.strip =~ /\A\d+\z/ ? age.strip.to_i : 0
            else 0
            end
    value.negative? ? 0 : value
  end

  def self.to_bool(value)
    case value
    when true then true
    when String then %w[y yes true].include?(value.strip.downcase)
    else false
    end
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
    '╰(°▽°)╯'
  end

  def classroom=(room)
    @classroom = room
    return if room.nil?

    room.students << self unless room.students.include?(self)
  end
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
    @books.each do |bk|
      puts "Title: #{bk.title}, Author: #{bk.author}"
    end
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
    print 'Name: '
    name = Person.sanitize_name(read_input)
    print 'Age: '
    age = parse_age(read_input)
    if age.nil?
      puts 'Invalid age'
      return nil
    end
    print 'Has parent permission? [Y/N]: '
    perm = read_input.upcase
    unless %w[Y N].include?(perm)
      puts 'Invalid parent permission response'
      return nil
    end
    student = Student.new(age, nil, name, parent_permission: perm == 'Y')
    @people << student
    puts 'Person created successfully'
    student
  end

  def create_teacher
    print 'Name: '
    name = Person.sanitize_name(read_input)
    print 'Age: '
    age = parse_age(read_input)
    if age.nil?
      puts 'Invalid age'
      return nil
    end
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
      puts 'Books and people are required to create a rental'
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
    date_input = read_input
    date = date_input.empty? ? Date.today.to_s : date_input
    rental = Rental.new(date, @books[book_index], @people[person_index])
    puts 'Rental created successfully'
    rental
  end

  def list_rentals
    print 'ID of person: '
    pid = parse_index(read_input)
    person = pid.nil? ? nil : @people.detect { |pr| pr.id == pid }
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
    input = gets
    input.nil? ? '' : input.to_s.chomp.strip
  end

  def parse_age(str)
    return nil unless str.is_a?(String) && str.strip =~ /\A\d+\z/

    str.strip.to_i
  end

  def parse_index(str)
    return nil unless str.is_a?(String) && str.strip =~ /\A\d+\z/

    str.strip.to_i
  end

  def valid_indices?(p_i, b_i)
    return false if p_i.nil? || b_i.nil?

    p_i >= 0 && p_i < @people.length && b_i >= 0 && b_i < @books.length
  end
end