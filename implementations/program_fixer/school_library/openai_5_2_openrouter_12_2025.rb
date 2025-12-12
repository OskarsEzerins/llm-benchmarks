# frozen_string_literal: true

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
    choice = (gets || '').chomp

    case choice
    when '1' then create_student
    when '2' then create_teacher
    else
      puts 'Invalid selection'
      nil
    end
  end

  def create_student
    nm = read_name
    ag = read_age

    parent_permission = read_parent_permission

    stu = Student.new(ag, nil, nm, parent_permission: parent_permission)
    @people << stu
    puts 'Person created successfully'
    stu
  end

  def create_teacher
    nm = read_name
    ag = read_age

    print 'Specialization: '
    spec = (gets || '').chomp
    spec = 'General' if spec.strip.empty?

    t = Teacher.new(ag, spec, nm)
    @people << t
    puts 'Person created successfully'
    t
  end

  def create_book
    print 'Title: '
    title = (gets || '').chomp
    title = 'Untitled' if title.strip.empty?

    print 'Author: '
    author = (gets || '').chomp
    author = 'Unknown' if author.strip.empty?

    book = Book.new(title, author)
    @books << book
    puts 'Book created successfully'
    book
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'Books and people must exist to create a rental'
      return nil
    end

    puts 'Select a book from the following list by number'
    @books.each_with_index { |b, i| puts "#{i}) Title: #{b.title}, Author: #{b.author}" }
    b_i = read_index(@books.length)

    puts 'Select a person from the following list by number (not id)'
    @people.each_with_index { |p, i| puts "#{i}) [#{p.class}] Name: #{p.name}, ID: #{p.id}, Age: #{p.age}" }
    p_i = read_index(@people.length)

    return nil unless valid_indices?(p_i, b_i)

    print 'Date (YYYY-MM-DD): '
    date_str = (gets || '').chomp
    date = parse_date(date_str) || Date.today.to_s

    rental = Rental.new(date, @books[b_i], @people[p_i])
    puts 'Rental created successfully'
    rental
  end

  def list_rentals
    print 'ID of person: '
    pid = (gets || '').chomp.to_i

    p_obj = @people.find { |pr| pr.id == pid }
    if p_obj.nil?
      puts 'Person not found'
      return
    end

    if p_obj.rentals.empty?
      puts 'No rentals found for this person'
      return
    end

    p_obj.rentals.each { |r| puts "Date: #{r.date}, Book: \"#{r.book.title}\" by #{r.book.author}" }
  end

  private

  def valid_indices?(p_i, b_i)
    p_i.is_a?(Integer) && b_i.is_a?(Integer) &&
      p_i >= 0 && p_i < @people.length &&
      b_i >= 0 && b_i < @books.length
  end

  def read_index(max_len)
    input = (gets || '').chomp
    idx = Integer(input, exception: false)
    return -1 if idx.nil? || idx.negative? || idx >= max_len

    idx
  end

  def read_name
    print 'Name: '
    nm = (gets || '').chomp
    nm = 'Unknown' if nm.strip.empty?
    nm
  end

  def read_age
    age = nil
    until age.is_a?(Integer) && age >= 0
      print 'Age: '
      input = (gets || '').chomp
      age = Integer(input, exception: false)
      age = nil if age.nil? || age.negative?
    end
    age
  end

  def read_parent_permission
    loop do
      print 'Has parent permission? [Y/N]: '
      perm = (gets || '').chomp.strip.upcase
      return true if perm == 'Y'
      return false if perm == 'N'

      puts 'Invalid input. Please enter Y or N.'
    end
  end

  def parse_date(str)
    return nil if str.nil? || str.strip.empty?

    Date.parse(str).to_s
  rescue ArgumentError
    nil
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, 'Implement correct_name in subclasses'
  end
end

class Decorator < Nameable
  def initialize(nameable)
    @nameable = nameable
    super()
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

    @book.rentals << self unless @book.rentals.include?(self)
    @person.rentals << self unless @person.rentals.include?(self)
  end
end

class Book
  attr_reader :title, :author, :rentals

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
    @label = label
    @students = []
  end

  def add_student(student)
    return if student.nil?

    @students << student unless @students.include?(student)
    student.classroom = self unless student.classroom == self
  end
end

class Person < Nameable
  attr_reader :id
  attr_accessor :name, :age, :rentals

  def initialize(age, name = 'Unknown', parent_permission: true)
    @id = rand(1..1_000_000)
    @name = (name.nil? || name.to_s.strip.empty?) ? 'Unknown' : name.to_s
    @age = age.to_i
    @age = 0 if @age.negative?
    @parent_permission = !!parent_permission
    @rentals = []
  end

  def correct_name
    @name
  end

  def can_use_services?
    of_age? || @parent_permission
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
    super(age, name, parent_permission: parent_permission)
    self.classroom = classroom unless classroom.nil?
  end

  def play_hooky
    '¯\\(ツ)/¯'
  end

  def classroom=(room)
    @classroom = room
    return if room.nil?

    room.add_student(self) unless room.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name = 'Unknown')
    super(age, name, parent_permission: true)
    @specialization = specialization.to_s
  end

  def can_use_services?
    true
  end
end