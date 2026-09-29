require 'date'

class Nameable
  def correct_name
    raise NotImplementedError, "#{self.class} must implement correct_name"
  end
end

class Decorator < Nameable
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
    @nameable.correct_name.to_s[0, 10]
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    @nameable.correct_name.to_s.capitalize
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
  attr_accessor :label, :students

  def initialize(label)
    @label = label
    @students = []
  end

  def add_student(student)
    @students << student unless @students.include?(student)
    student.classroom = self unless student.classroom == self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals
  attr_reader :parent_permission

  def initialize(age, name = 'Unknown', parent_permission: true)
    super()
    @id = rand(1..10_000)
    @age = begin
      a = Integer(age)
      a.negative? ? 0 : a
    rescue ArgumentError, TypeError
      0
    end
    @name = name.nil? || name.to_s.strip.empty? ? 'Unknown' : name.to_s
    @parent_permission = parent_permission == true
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

  def initialize(age, classroom = nil, name = 'Unknown', parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom if classroom
  end

  def play_hooky
    '¯(ツ)/¯'
  end

  def classroom=(room)
    @classroom = room
    return if room.nil?

    room.students << self unless room.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization = nil, name = 'Unknown', parent_permission: true)
    super(age, name, parent_permission: parent_permission)
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
    puts 'No books available' if @books.empty?
    @books.each do |bk|
      puts "title: #{bk.title}, author: #{bk.author}"
    end
  end

  def list_people
    puts 'No one has registered' if @people.empty?
    @people.each do |human|
      puts "[#{human.class}] id: #{human.id}, Name: #{human.name}, Age: #{human.age}"
    end
  end

  def create_person
    print 'Student(1) or Teacher(2)? '
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
    nm = read_input
    nm = 'Unknown' if nm.empty?
    print 'Age: '
    ag = parse_int(read_input)
    if ag.nil? || ag.negative?
      puts 'Invalid age'
      return nil
    end
    print 'Parent permission? [Y/N] '
    perm = read_input.upcase
    unless %w[Y N].include?(perm)
      puts 'Invalid parent permission response'
      return nil
    end
    stu = Student.new(ag, nil, nm, parent_permission: perm == 'Y')
    @people << stu
    puts 'Person created successfully'
    stu
  end

  def create_teacher
    print 'Name: '
    nm = read_input
    nm = 'Unknown' if nm.empty?
    print 'Age: '
    ag = parse_int(read_input)
    if ag.nil? || ag.negative?
      puts 'Invalid age'
      return nil
    end
    print 'Specialization: '
    spec = read_input
    t = Teacher.new(ag, spec, nm)
    @people << t
    puts 'Person created successfully'
    t
  end

  def create_book
    print 'Title: '
    t = read_input
    print 'Author: '
    a = read_input
    if t.empty? || a.empty?
      puts 'Title and author cannot be empty'
      return nil
    end
    book = Book.new(t, a)
    @books << book
    puts 'Book created successfully'
    book
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'Need at least one book and one person'
      return nil
    end
    puts 'Select a book'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title}" }
    bi = parse_int(read_input)
    puts 'Select person'
    @people.each_with_index { |p, i| puts "#{i}: #{p.name}" }
    pi = parse_int(read_input)
    unless valid_indices?(pi, bi)
      puts 'Invalid selection'
      return nil
    end
    rental = Rental.new(Date.today.to_s, @books[bi], @people[pi])
    puts 'Rental created successfully'
    rental
  end

  def list_rentals
    print 'ID of person: '
    pid = parse_int(read_input)
    p_obj = pid.nil? ? nil : @people.detect { |pr| pr.id == pid }
    if p_obj.nil?
      puts 'Person not found'
      return
    end
    p_obj.rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
  end

  private

  def read_input
    gets.to_s.chomp.strip
  end

  def parse_int(str)
    Integer(str.to_s.strip, 10)
  rescue ArgumentError, TypeError
    nil
  end

  def valid_indices?(p_i, b_i)
    return false if p_i.nil? || b_i.nil?

    p_i >= 0 && p_i < @people.length && b_i >= 0 && b_i < @books.length
  end
end