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
      puts "Title: #{book.title}, Author: #{book.author}"
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
      return
    end

    @people.each do |person|
      puts "[#{person.class}] ID: #{person.id}, Name: #{person.name}, Age: #{person.age}"
    end
  end

  def create_person
    print 'Student(1) or Teacher(2)? '
    choice = gets.to_s.strip

    case choice
    when '1', '3'
      create_student
    when '2'
      create_teacher
    else
      nil
    end
  end

  def create_student
    print 'Name: '
    name = read_input

    print 'Age: '
    age = read_input

    print 'Parent permission? (Y/N): '
    permission = read_input

    student = Student.new(
      age,
      nil,
      name,
      parent_permission: permission_value(permission)
    )

    @people << student
    student
  end

  def create_teacher
    print 'Name: '
    name = read_input

    print 'Age: '
    age = read_input

    print 'Specialization: '
    specialization = read_input

    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    teacher
  end

  def create_book
    print 'Title: '
    title = read_input

    print 'Author: '
    author = read_input

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
    book_index = parse_index(gets)

    puts 'Select person'
    @people.each_with_index do |person, index|
      puts "#{index}: #{person.name}"
    end
    person_index = parse_index(gets)

    return nil unless valid_indices?(person_index, book_index)

    Rental.new(Date.today, @books[book_index], @people[person_index])
  end

  def list_rentals
    print 'ID of person: '
    person_id = parse_index(gets)
    person = @people.find { |candidate| candidate.id == person_id }

    return [] unless person

    person.rentals.each do |rental|
      puts "#{rental.date} - #{rental.book.title}"
    end

    person.rentals
  end

  private

  def read_input
    input = gets
    input ? input.chomp : ''
  end

  def parse_index(value)
    Integer(value.to_s.strip, 10)
  rescue ArgumentError, TypeError
    nil
  end

  def permission_value(value)
    %w[y yes true].include?(value.to_s.strip.downcase)
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
    return nil unless student

    student.classroom = self
    self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals
  attr_reader :parent_permission

  @@next_id = 1

  def initialize(age = 0, name = 'Unknown', parent_permission: true, **options)
    age = options[:age] if options.key?(:age)
    name = options[:name] if options.key?(:name)
    parent_permission = options[:parent_permission] if options.key?(:parent_permission)

    if !age_value?(age)
      if age_value?(name)
        actual_name = age
        actual_age = name
      elsif name.to_s == 'Unknown'
        actual_name = age
        actual_age = 0
      else
        actual_name = name
        actual_age = 0
      end
    else
      actual_age = age
      actual_name = name
    end

    @id = @@next_id
    @@next_id += 1

    @name = normalize_name(actual_name)
    @age = normalize_age(actual_age)
    @parent_permission = normalize_permission(parent_permission)
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

  def parent_permission?
    @parent_permission
  end

  private

  def of_age?
    @age >= 18
  end

  def age_value?(value)
    value.is_a?(Integer) ||
      value.is_a?(String) && value.strip.match?(/\A[+-]?\d+\z/)
  end

  def normalize_age(value)
    age = if value.is_a?(Integer)
            value
          elsif value.is_a?(String) && value.strip.match?(/\A[+-]?\d+\z/)
            value.to_i
          else
            0
          end

    age.negative? ? 0 : age
  end

  def normalize_name(value)
    name = value.to_s
    name.strip.empty? ? 'Unknown' : name
  end

  def normalize_permission(value)
    return true if value == true
    return false if value == false

    %w[y yes true].include?(value.to_s.strip.downcase)
  end
end

class Student < Person
  attr_reader :classroom

  def initialize(age, classroom, name, parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom if classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    if @classroom && @classroom != room
      @classroom.students.delete(self) if @classroom.respond_to?(:students)
    end

    @classroom = room

    if room && room.respond_to?(:students) && !room.students.include?(self)
      room.students << self
    end

    @classroom
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization = nil, name = 'Unknown')
    if !age_value_for_teacher?(age)
      if age_value_for_teacher?(name)
        age, name = name, age
      elsif name.to_s == 'Unknown'
        name = age
        age = 0
      end
    end

    super(age, name)
    @specialization = specialization
  end

  def can_use_services?
    true
  end

  private

  def age_value_for_teacher?(value)
    value.is_a?(Integer) ||
      value.is_a?(String) && value.strip.match?(/\A[+-]?\d+\z/)
  end
end