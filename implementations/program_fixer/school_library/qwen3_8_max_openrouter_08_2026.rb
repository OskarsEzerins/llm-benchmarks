require 'date'

class App
  attr_reader :books, :people

  def initialize
    @books = []
    @people = []
  end

  def list_books
    if @books.nil? || @books.empty?
      puts 'No books available'
    else
      @books.each { |bk| puts "title: #{bk.title}, author: #{bk.author}" }
    end
  end

  def list_people
    if @people.nil? || @people.empty?
      puts 'No one has registered'
    else
      @people.each do |human|
        puts "[#{human.class}] id: #{human.id}, Name: #{human.name}, Age: #{human.age}"
      end
    end
  end

  def create_person
    print 'Student(3) or Teacher(1)? '
    choice = safe_gets.strip

    if choice == '1'
      create_teacher
    elsif choice == '3'
      create_student
    else
      puts 'Invalid selection'
      nil
    end
  end

  def create_student
    @people = [] if @people.nil?

    print 'Name: '
    name = safe_gets
    print 'Age: '
    age = safe_gets
    print 'Parent permission? '
    permission = safe_gets

    student = Student.new(age, nil, name, parent_permission: parse_permission(permission))
    @people << student
    student
  end

  def create_teacher
    @people = [] if @people.nil?

    print 'Name: '
    name = safe_gets
    print 'Age: '
    age = safe_gets
    print 'Specialization: '
    specialization = safe_gets

    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    teacher
  end

  def create_book
    @books = [] if @books.nil?

    print 'Title: '
    title = safe_gets
    print 'Author: '
    author = safe_gets

    book = Book.new(title, author)
    @books << book
    book
  end

  def create_rental
    if @books.nil? || @books.empty? || @people.nil? || @people.empty?
      puts 'No books or people available'
      return
    end

    puts 'Select a book'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title}" }
    book_index = parse_non_negative_integer(safe_gets)

    unless valid_book_index?(book_index)
      puts 'Invalid selection'
      return
    end

    puts 'Select person'
    @people.each_with_index { |p, i| puts "#{i}: #{p.name}" }
    person_index = parse_non_negative_integer(safe_gets)

    unless valid_person_index?(person_index)
      puts 'Invalid selection'
      return
    end

    Rental.new(Date.today, @books[book_index], @people[person_index])
  end

  def list_rentals
    @people = [] if @people.nil?

    print 'ID of person: '
    person_id = parse_integer(safe_gets)
    person = @people.detect { |p| p.id == person_id }

    if person.nil?
      puts 'Person not found'
      return
    end

    rentals = person.rentals.is_a?(Array) ? person.rentals : []

    if rentals.empty?
      puts 'No rentals found'
    else
      rentals.each { |r| puts "#{r.date} - #{r.book&.title}" }
    end
  end

  private

  def safe_gets
    input = gets
    input.nil? ? '' : input.to_s.chomp
  end

  def parse_permission(input)
    normalized = input.to_s.strip.downcase
    %w[y yes true t 1].include?(normalized)
  end

  def parse_integer(input)
    text = input.to_s.strip
    return nil unless text =~ /\A-?\d+\z/

    text.to_i
  end

  def parse_non_negative_integer(input)
    value = parse_integer(input)
    return nil if value.nil? || value.negative?

    value
  end

  def valid_book_index?(index)
    !index.nil? && !@books.nil? && index >= 0 && index < @books.length
  end

  def valid_person_index?(index)
    !index.nil? && !@people.nil? && index >= 0 && index < @people.length
  end

  def valid_indices?(person_index, book_index)
    valid_person_index?(person_index) && valid_book_index?(book_index)
  end
end

class Nameable
  def correct_name
    nil
  end
end

class Decorator < Nameable
  def initialize(nameable)
    @nameable = nameable
  end

  def correct_name
    return '' unless @nameable.respond_to?(:correct_name)

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
    name = super.to_s
    return name if name.empty?

    name[0].upcase + name[1..-1].to_s
  end
end

class Rental
  attr_reader :date, :book, :person

  def initialize(date, book, person)
    @date = date
    @book = book
    @person = person

    book.rentals << self if book.respond_to?(:rentals) && book.rentals.is_a?(Array)
    person.rentals << self if person.respond_to?(:rentals) && person.rentals.is_a?(Array)
  end
end

class Book
  attr_accessor :title, :author
  attr_reader :rentals

  def initialize(title, author)
    @title = normalize_text(title)
    @author = normalize_text(author)
    @rentals = []
  end

  def add_rental(person, date)
    Rental.new(date, self, person)
  end

  def rentals=(value)
    @rentals = value.is_a?(Array) ? value : []
  end

  private

  def normalize_text(value)
    text = value.to_s.strip
    text.empty? ? 'Unknown' : text
  end
end

class Classroom
  attr_accessor :label
  attr_reader :students

  def initialize(label)
    @label = normalize_text(label)
    @students = []
  end

  def add_student(student)
    return unless student

    self.students = [] unless students.is_a?(Array)
    students << student unless students.include?(student)
    student.classroom = self if student.respond_to?(:classroom=)
  end

  def students=(value)
    @students = value.is_a?(Array) ? value : []
  end

  private

  def normalize_text(value)
    text = value.to_s.strip
    text.empty? ? 'Unknown' : text
  end
end

class Person < Nameable
  attr_reader :id, :name, :age, :rentals, :parent_permission

  @@id_counter = 0

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id = next_id
    @name = normalize_name(name)
    @age = normalize_age(age)
    @parent_permission = normalize_boolean(parent_permission)
    @rentals = []
  end

  def id=(value)
    @id = value.to_i
  end

  def name=(value)
    @name = normalize_name(value)
  end

  def age=(value)
    @age = normalize_age(value)
  end

  def rentals=(value)
    @rentals = value.is_a?(Array) ? value : []
  end

  def parent_permission=(value)
    @parent_permission = normalize_boolean(value)
  end

  def can_use_services?
    of_age? || parent_permission
  end

  def correct_name
    @name
  end

  def add_rental(book, date)
    Rental.new(date, book, self)
  end

  private

  def next_id
    @@id_counter += 1
  end

  def normalize_name(value)
    text = value.to_s.strip
    text.empty? ? 'Unknown' : text
  end

  def normalize_age(value)
    int_value =
      case value
      when Integer
        value
      when Float
        value.finite? && value == value.to_i ? value.to_i : 0
      when String
        text = value.strip
        text =~ /\A-?\d+\z/ ? text.to_i : 0
      else
        value.respond_to?(:to_i) ? value.to_i : 0
      end

    int_value.negative? ? 0 : int_value
  end

  def normalize_boolean(value)
    return true if value == true
    return false if value == false

    case value
    when nil
      false
    when String
      %w[y yes true t 1].include?(value.strip.downcase)
    when Symbol
      %w[y yes true t 1].include?(value.to_s.downcase)
    when Numeric
      !value.zero?
    else
      value ? true : false
    end
  end

  def of_age?
    @age >= 18
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
    @classroom = room
    return unless room.respond_to?(:students) && room.students.is_a?(Array)

    room.students << self unless room.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name = 'Unknown', parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end