require 'date'

class App
  def initialize
    @books = []
    @people = []
  end

  def list_books
    if books.empty?
      puts 'No books available'
    else
      books.each do |bk|
        puts "title: #{bk.title}, author: #{bk.author}"
      end
    end
  end

  def list_people
    if people.empty?
      puts 'No one has registered'
    else
      people.each do |human|
        puts "[#{human.class}] id: #{human.id}, Name: #{human.name}, Age: #{human.age}"
      end
    end
  end

  def create_person
    print 'Student(3) or Teacher(1)? '
    choice = read_input.strip

    case choice
    when '1' then create_teacher
    when '3' then create_student
    else
      puts 'Invalid selection'
    end
  end

  def create_student
    print 'Name: '
    name = read_input

    print 'Age: '
    age = parse_age(read_input)

    print 'Parent permission? '
    parent_permission = parse_parent_permission(read_input)

    student = Student.new(age, nil, name, parent_permission: parent_permission)
    people << student
    student
  end

  def create_teacher
    print 'Name: '
    name = read_input

    print 'Age: '
    age = parse_age(read_input)

    print 'Specialization: '
    specialization = read_input

    teacher = Teacher.new(age, specialization, name)
    people << teacher
    teacher
  end

  def create_book
    print 'Title: '
    title = read_input

    print 'Author: '
    author = read_input

    book = Book.new(title, author)
    books << book
    book
  end

  def create_rental
    if books.empty? || people.empty?
      puts 'No books or people available'
      return
    end

    puts 'Select a book'
    books.each_with_index { |b, i| puts "#{i}: #{b.title}" }
    book_index = parse_integer(read_input)

    puts 'Select person'
    people.each_with_index { |p, i| puts "#{i}: #{p.name}" }
    person_index = parse_integer(read_input)

    unless valid_indices?(person_index, book_index)
      puts 'Invalid selection'
      return
    end

    Rental.new(Date.today, books[book_index], people[person_index])
  end

  def list_rentals
    print 'ID of person: '
    pid = parse_integer(read_input)
    person = people.find { |pr| pr.id == pid }

    if person.nil?
      puts 'Person not found'
      return
    end

    Array(person.rentals).each do |rental|
      date = rental.respond_to?(:date) ? rental.date : ''
      book = rental.respond_to?(:book) ? rental.book : nil
      book_title = book.respond_to?(:title) ? book.title : ''

      puts "#{date} - #{book_title}"
    end
  end

  private

  def books
    @books = [] unless @books.is_a?(Array)
    @books
  end

  def people
    @people = [] unless @people.is_a?(Array)
    @people
  end

  def read_input
    input = gets
    input.to_s.chomp
  rescue StandardError
    ''
  end

  def gets
    $stdin.gets
  rescue StandardError
    nil
  end

  def parse_age(input)
    str = input.to_s.strip
    return 0 unless str =~ /\A[+-]?\d+\z/

    age = str.to_i
    age.negative? ? 0 : age
  end

  def parse_parent_permission(input)
    %w[y yes true 1].include?(input.to_s.strip.downcase)
  end

  def parse_integer(input)
    str = input.to_s.strip
    return nil unless str =~ /\A\+?\d+\z/

    str.to_i
  end

  def valid_indices?(person_index, book_index)
    p_i = person_index.is_a?(Integer) ? person_index : parse_integer(person_index.to_s)
    b_i = book_index.is_a?(Integer) ? book_index : parse_integer(book_index.to_s)

    p_i.is_a?(Integer) &&
      b_i.is_a?(Integer) &&
      p_i >= 0 &&
      p_i < people.length &&
      b_i >= 0 &&
      b_i < books.length
  end
end

class Nameable
  def correct_name
    nil
  end
end

class Decorator < Nameable
  attr_reader :nameable

  def initialize(nameable)
    @nameable = nameable
  end

  def correct_name
    return '' if @nameable.nil?

    if @nameable.respond_to?(:correct_name)
      @nameable.correct_name.to_s
    else
      @nameable.to_s
    end
  end
end

class TrimmerDecorator < Decorator
  def correct_name
    super[0, 10].to_s
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

    @book.rentals << self if @book.respond_to?(:rentals) && @book.rentals.is_a?(Array)
    @person.rentals << self if @person.respond_to?(:rentals) && @person.rentals.is_a?(Array)
  end
end

class Book
  attr_reader :title, :author, :rentals

  def initialize(title, author)
    self.title = title
    self.author = author
    @rentals = []
  end

  def title=(value)
    @title = value.to_s
  end

  def author=(value)
    @author = value.to_s
  end

  def rentals=(value)
    @rentals = value.is_a?(Array) ? value : []
  end

  def add_rental(person, date)
    Rental.new(date, self, person)
  end
end

class Classroom
  attr_reader :label, :students

  def initialize(label)
    self.label = label
    @students = []
  end

  def label=(value)
    @label = value.to_s
  end

  def students=(value)
    @students = value.is_a?(Array) ? value : []
  end

  def add_student(student)
    @students = [] unless @students.is_a?(Array)

    return if student.nil?
    return unless student.is_a?(Student) || student.respond_to?(:assign_classroom)

    @students << student unless @students.include?(student)
    student.assign_classroom(self) if student.respond_to?(:assign_classroom)
  end
end

class Person < Nameable
  attr_reader :id, :name, :age, :rentals, :parent_permission

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id = rand(1000)
    self.name = name
    self.age = age
    self.parent_permission = parent_permission
    @rentals = []
  end

  def id=(value)
    @id = value.to_i
  end

  def name=(value)
    @name = value.to_s
  end

  def age=(value)
    int =
      begin
        if value.is_a?(Integer)
          value
        elsif value.is_a?(Numeric)
          value.to_i == value ? value.to_i : nil
        else
          Integer(value.to_s.strip)
        end
      rescue StandardError
        nil
      end

    @age = int.nil? || int.negative? ? 0 : int
  end

  def parent_permission=(value)
    @parent_permission =
      case value
      when true then true
      when false, nil then false
      else
        value.to_s.strip.downcase =~ /\A(?:y|yes|true|1)\z/ ? true : false
      end
  rescue StandardError
    @parent_permission = false
  end

  def rentals=(value)
    @rentals = value.is_a?(Array) ? value : []
  end

  def can_use_services?
    of_age? || parent_permission
  end

  def correct_name
    name.to_s
  end

  def add_rental(book, date)
    Rental.new(date, book, self)
  end

  private

  def of_age?
    age >= 18
  end
end

class Student < Person
  attr_reader :classroom

  def initialize(age, classroom, name, parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @classroom = nil
    assign_classroom(classroom) if classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def assign_classroom(room)
    self.classroom = room
  end

  def classroom=(room)
    @classroom = room

    if room.respond_to?(:students) && room.students.is_a?(Array) && !room.students.include?(self)
      room.students << self
    end
  end
end

class Teacher < Person
  attr_reader :specialization

  def initialize(age, specialization, name, parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    self.specialization = specialization
  end

  def specialization=(value)
    @specialization = value.to_s
  end

  def can_use_services?
    true
  end
end