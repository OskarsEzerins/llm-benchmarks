require 'date'

class Nameable
  def correct_name
    raise NotImplementedError, "#{self.class} must implement correct_name"
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
    name = super.to_s
    name.length > 10 ? name[0..9] : name
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
    book.rentals << self
    person.rentals << self
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
  attr_accessor :id, :name, :age, :rentals, :parent_permission

  @@next_id = 1

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id = @@next_id
    @@next_id += 1
    @name = (name.nil? || name.to_s.strip.empty?) ? 'Unknown' : name.to_s
    @age = age.to_i
    @parent_permission = parent_permission ? true : false
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
    super(name, age, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom if classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    @classroom = room
    return if room.nil?
    room.students ||= []
    room.students << self unless room.students.include?(self)
  end

  def assign_classroom(room)
    self.classroom = room
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name = 'Unknown')
    super(name, age, parent_permission: true)
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
    print 'Do you want to create a student (1) or a teacher (2)? '
    choice = read_input
    case choice
    when '1' then create_student
    when '2' then create_teacher
    else puts 'Invalid selection'
    end
  end

  def create_student
    name = read_name
    return unless name
    age = read_age
    return unless age
    print 'Has parent permission? [Y/N]: '
    perm = read_input.to_s.upcase
    unless %w[Y N].include?(perm)
      puts 'Invalid response'
      return
    end
    stu = Student.new(age, nil, name, parent_permission: perm == 'Y')
    @people << stu
    puts 'Person created successfully'
    stu
  end

  def create_teacher
    name = read_name
    return unless name
    age = read_age
    return unless age
    print 'Specialization: '
    spec = read_input
    t = Teacher.new(age, spec, name)
    @people << t
    puts 'Person created successfully'
    t
  end

  def create_book
    print 'Title: '
    t = read_input
    print 'Author: '
    a = read_input
    if t.to_s.empty? || a.to_s.empty?
      puts 'Invalid book details'
      return
    end
    book = Book.new(t, a)
    @books << book
    puts 'Book created successfully'
    book
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'Need at least one book and one person to create a rental'
      return
    end
    puts 'Select a book from the following list by number'
    @books.each_with_index { |b, i| puts "#{i}) Title: #{b.title}, Author: #{b.author}" }
    bi = read_input.to_s
    puts 'Select a person from the following list by number (not id)'
    @people.each_with_index { |p, i| puts "#{i}) [#{p.class}] Name: #{p.name}, ID: #{p.id}, Age: #{p.age}" }
    pi = read_input.to_s
    unless bi.match?(/\A\d+\z/) && pi.match?(/\A\d+\z/) && valid_indices?(pi.to_i, bi.to_i)
      puts 'Invalid selection'
      return
    end
    print 'Date: '
    date = read_input
    date = Date.today.to_s if date.nil? || date.empty?
    rental = Rental.new(date, @books[bi.to_i], @people[pi.to_i])
    puts 'Rental created successfully'
    rental
  end

  def list_rentals
    print 'ID of person: '
    pid = read_input.to_i
    p_obj = @people.find { |pr| pr.id == pid }
    if p_obj.nil?
      puts 'Person not found'
      return
    end
    puts 'No rentals found' if p_obj.rentals.empty?
    p_obj.rentals.each { |r| puts "Date: #{r.date}, Book: \"#{r.book.title}\" by #{r.book.author}" }
  end

  private

  def read_input
    line = gets
    line.nil? ? nil : line.chomp.strip
  end

  def read_name
    print 'Name: '
    name = read_input
    if name.nil? || name.empty?
      puts 'Invalid name'
      return nil
    end
    name
  end

  def read_age
    print 'Age: '
    age = read_input.to_s
    unless age.match?(/\A\d+\z/)
      puts 'Invalid age'
      return nil
    end
    age.to_i
  end

  def valid_indices?(p_i, b_i)
    p_i >= 0 && p_i < @people.length && b_i >= 0 && b_i < @books.length
  end
end