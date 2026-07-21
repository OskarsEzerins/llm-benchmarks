require 'date'

class Nameable
  def correct_name
    raise NotImplementedError, "#{self.class} must implement #correct_name"
  end
end

class Decorator < Nameable
  attr_accessor :nameable

  def initialize(nameable)
    @nameable = nameable
  end

  def correct_name
    @nameable.correct_name.to_s
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

  def students=(value)
    @students = value.nil? ? [] : Array(value)
  end

  def add_student(student)
    return if student.nil? || @students.include?(student)

    @students << student
    student.classroom = self if student.respond_to?(:classroom=) && student.classroom != self
  end
end

class Person < Nameable
  attr_reader :id, :age, :rentals, :parent_permission
  attr_accessor :name

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id = rand(1..1000)
    @name = name.to_s
    self.age = age
    @parent_permission = normalize_permission(parent_permission)
    @rentals = []
  end

  def age=(value)
    @age = normalize_age(value)
  end

  def can_use_services?
    of_age? || @parent_permission
  end

  def correct_name
    @name.to_s
  end

  def add_rental(book, date)
    Rental.new(date, book, self)
  end

  private

  def of_age?
    @age >= 18
  end

  def normalize_age(value)
    age = Integer(value)
    age.negative? ? 0 : age
  rescue ArgumentError, TypeError
    0
  end

  def normalize_permission(value)
    case value
    when true
      true
    when false, nil
      false
    else
      %w[y yes true].include?(value.to_s.strip.downcase)
    end
  end
end

class Student < Person
  attr_reader :classroom

  def initialize(age, classroom, name = 'Unknown', parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom if classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    @classroom.students.delete(self) if @classroom && @classroom != room
    @classroom = room
    room.students << self if room && room.respond_to?(:students) && !room.students.include?(self)
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
    print 'Do you want to create a student (1) or a teacher (2)? [Input the number]: '
    choice = gets&.strip.to_s

    case choice
    when '1', 'student', 's'
      create_student
    when '2', 'teacher', 't'
      create_teacher
    else
      puts 'Invalid option'
    end
  end

  def create_student
    print 'Name: '
    name = gets&.chomp.to_s
    age = prompt_age
    permission = prompt_parent_permission

    student = Student.new(age, nil, name, parent_permission: permission)
    @people << student
    puts 'Student created successfully'
  end

  def create_teacher
    print 'Name: '
    name = gets&.chomp.to_s
    age = prompt_age
    print 'Specialization: '
    specialization = gets&.chomp.to_s

    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    puts 'Teacher created successfully'
  end

  def create_book
    print 'Title: '
    title = gets&.chomp.to_s
    print 'Author: '
    author = gets&.chomp.to_s

    @books << Book.new(title, author)
    puts 'Book created successfully'
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'Books and people are required to create a rental'
      return
    end

    puts 'Select a book'
    @books.each_with_index { |book, index| puts "#{index}: #{book.title}" }
    book_index = read_integer

    puts 'Select person'
    @people.each_with_index { |person, index| puts "#{index}: #{person.name}" }
    person_index = read_integer

    unless valid_indices?(person_index, book_index)
      puts 'Invalid book or person selection'
      return
    end

    rental = Rental.new(Date.today.to_s, @books[book_index], @people[person_index])
    @rentals << rental unless @rentals.include?(rental)
    puts 'Rental created successfully'
  end

  def list_rentals
    print 'ID of person: '
    person_id = read_integer
    person = @people.detect { |candidate| candidate.id == person_id }

    if person.nil?
      puts 'Person not found'
      return
    end

    if person.rentals.empty?
      puts 'No rentals found'
      return
    end

    person.rentals.each do |rental|
      puts "#{rental.date} - #{rental.book.title}"
    end
  end

  private

  def prompt_age
    loop do
      print 'Age: '
      input = gets
      return 0 if input.nil?

      begin
        age = Integer(input.strip)
        return age unless age.negative?
      rescue ArgumentError, TypeError
        nil
      end

      puts 'Invalid age'
    end
  end

  def prompt_parent_permission
    loop do
      print 'Parent permission? [Y/N]: '
      input = gets
      return true if input.nil?

      case input.strip.downcase
      when 'y', 'yes'
        return true
      when 'n', 'no'
        return false
      else
        puts 'Invalid response. Please enter Y or N.'
      end
    end
  end

  def read_integer
    input = gets
    return nil if input.nil?

    Integer(input.strip)
  rescue ArgumentError, TypeError
    nil
  end

  def valid_indices?(person_index, book_index)
    return false if person_index.nil? || book_index.nil?

    person_index.between?(0, @people.length - 1) && book_index.between?(0, @books.length - 1)
  end
end