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
    else
      @books.each do |book|
        puts "title: #{book.title}, author: #{book.author}"
      end
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
    else
      @people.each do |person|
        puts "[#{person.class}] id: #{person.id}, Name: #{person.name}, Age: #{person.age}"
      end
    end
  end

  def create_person
    loop do
      print 'Student(3) or Teacher(1)? '
      input = gets
      break if input.nil?

      choice = input.chomp
      case choice
      when '1', '2'
        create_teacher
        return
      when '3'
        create_student
        return
      else
        puts 'Invalid selection'
      end
    end
  end

  def create_student
    print 'Name: '
    name_input = gets
    return if name_input.nil?

    name = name_input.chomp
    name = 'Unknown' if name.nil? || name.strip.empty?

    print 'Age: '
    age_input = gets
    return if age_input.nil?

    age = age_input.to_i
    age = 0 if age.negative?

    print 'Parent permission? '
    permission_input = gets
    permission = permission_input&.chomp&.downcase
    parent_permission = %w[y yes true].include?(permission)

    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
  end

  def create_teacher
    print 'Name: '
    name_input = gets
    return if name_input.nil?

    name = name_input.chomp
    name = 'Unknown' if name.nil? || name.strip.empty?

    print 'Age: '
    age_input = gets
    return if age_input.nil?

    age = age_input.to_i
    age = 0 if age.negative?

    teacher = Teacher.new(age, nil, name)
    @people << teacher
  end

  def create_book
    print 'Title: '
    title_input = gets
    return if title_input.nil?

    title = title_input.chomp

    print 'Author: '
    author_input = gets
    return if author_input.nil?

    author = author_input.chomp

    book = Book.new(title, author)
    @books << book
  end

  def create_rental
    if @books.empty?
      puts 'No books available'
      return
    end

    puts 'Select a book'
    @books.each_with_index do |book, index|
      puts "#{index}: #{book.title}"
    end

    book_index_input = gets
    return if book_index_input.nil?

    book_index = book_index_input.to_i

    if @people.empty?
      puts 'No people registered'
      return
    end

    puts 'Select person'
    @people.each_with_index do |person, index|
      puts "#{index}: #{person.name}"
    end

    person_index_input = gets
    return if person_index_input.nil?

    person_index = person_index_input.to_i

    unless valid_indices?(person_index, book_index)
      puts 'Invalid selection'
      return
    end

    Rental.new(Date.today, @books[book_index], @people[person_index])
  end

  def list_rentals
    print 'ID of person: '
    id_input = gets
    return if id_input.nil?

    person_id = id_input.to_i
    person = @people.find { |p| p.id == person_id }

    if person.nil?
      puts 'Person not found'
      return
    end

    person.rentals.each do |rental|
      puts "#{rental.date} - #{rental.book.title}"
    end
  end

  private

  def valid_indices?(person_index, book_index)
    person_index.between?(0, @people.length - 1) &&
      book_index.between?(0, @books.length - 1)
  end
end

class Nameable
  def correct_name
    ''
  end
end

class Decorator < Nameable
  attr_reader :nameable

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
    name.length > 10 ? name[0, 10] : name
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

    book.rentals << self unless book.rentals.include?(self)
    person.rentals << self unless person.rentals.include?(self)
  end
end

class Book
  attr_accessor :title, :author
  attr_reader :rentals

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
  attr_accessor :label
  attr_reader :students

  def initialize(label)
    @label = label.to_s
    @students = []
  end

  def add_student(student)
    return if student.nil?

    @students << student unless @students.include?(student)
    student.classroom = self unless student.classroom == self
  end
end

class Person < Nameable
  attr_accessor :name, :age
  attr_reader :id, :rentals, :parent_permission

  @@id_counter = 0

  def initialize(*args, parent_permission: true)
    if args.length >= 2 && numeric_like?(args[0])
      age_input, name_input = args[0], args[1]
    else
      name_input, age_input = args[0], args[1]
    end

    @@id_counter += 1
    @id = @@id_counter

    @name = name_input.nil? || name_input.to_s.strip.empty? ? 'Unknown' : name_input.to_s
    @age = age_input.to_i
    @age = 0 if @age.negative?

    @parent_permission = normalize_permission(parent_permission)
    @rentals = []
  end

  def can_use_services?
    of_age? || @parent_permission
  end

  def correct_name
    @name
  end

  def full_name
    @name
  end

  def add_rental(book, date)
    Rental.new(date, book, self)
  end

  private

  def numeric_like?(value)
    value.is_a?(Numeric) || value.to_s.match?(/\A-?\d+\z/)
  end

  def normalize_permission(value)
    case value
    when true, 'true', 'Y', 'y', 'yes', 'Yes', 'YES'
      true
    else
      false
    end
  end

  def of_age?
    @age >= 18
  end
end

class Student < Person
  attr_reader :classroom

  def initialize(age, classroom, name, parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom unless classroom.nil?
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

  def initialize(*args)
    if args.length >= 3
      if numeric_like_for_teacher?(args[0])
        age, specialization, name = args[0], args[1], args[2]
      else
        name, specialization, age = args[0], args[1], args[2]
      end
    elsif args.length == 2
      age, specialization = args[0], args[1]
      name = 'Unknown'
    else
      age = args[0]
      specialization = nil
      name = 'Unknown'
    end

    super(name, age, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
  end

  private

  def numeric_like_for_teacher?(value)
    value.is_a?(Numeric) || value.to_s.match?(/\A-?\d+\z/)
  end
end