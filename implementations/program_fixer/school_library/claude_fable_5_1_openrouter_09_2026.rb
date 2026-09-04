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
    student.assign_classroom(self)
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals, :parent_permission

  @@next_id = 0

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @@next_id += 1
    @id = @@next_id
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

  def initialize(age, classroom, name, parent_permission: true)
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

    room.students << self unless room.students.include?(self)
  end

  def assign_classroom(room)
    self.classroom = room
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name)
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
    else puts 'Invalid option'
    end
  end

  def create_student
    print 'Name: '
    name = read_input
    if name.empty?
      puts 'Invalid name'
      return
    end
    print 'Age: '
    age = read_age
    if age.nil?
      puts 'Invalid age'
      return
    end
    print 'Has parent permission? [Y/N]: '
    perm = read_input.upcase
    unless %w[Y N].include?(perm)
      puts 'Invalid permission response'
      return
    end
    student = Student.new(age, nil, name, parent_permission: perm == 'Y')
    @people << student
    puts 'Person created successfully'
    student
  end

  def create_teacher
    print 'Name: '
    name = read_input
    if name.empty?
      puts 'Invalid name'
      return
    end
    print 'Age: '
    age = read_age
    if age.nil?
      puts 'Invalid age'
      return
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
    if title.empty? || author.empty?
      puts 'Invalid book details'
      return
    end
    book = Book.new(title, author)
    @books << book
    puts 'Book created successfully'
    book
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'No books or people available to create a rental'
      return
    end
    puts 'Select a book from the following list by number'
    @books.each_with_index { |b, i| puts "#{i}) Title: #{b.title}, Author: #{b.author}" }
    book_input = read_input
    puts 'Select a person from the following list by number (not id)'
    @people.each_with_index { |p, i| puts "#{i}) [#{p.class}] Name: #{p.name}, ID: #{p.id}, Age: #{p.age}" }
    person_input = read_input
    unless integer_string?(book_input) && integer_string?(person_input)
      puts 'Invalid selection'
      return
    end
    bi = book_input.to_i
    pi = person_input.to_i
    unless valid_indices?(pi, bi)
      puts 'Invalid selection'
      return
    end
    print 'Date: '
    date = read_input
    date = Date.today.to_s if date.empty?
    rental = Rental.new(date, @books[bi], @people[pi])
    puts 'Rental created successfully'
    rental
  end

  def list_rentals
    print 'ID of person: '
    pid_input = read_input
    unless integer_string?(pid_input)
      puts 'Invalid ID'
      return
    end
    pid = pid_input.to_i
    person = @people.detect { |pr| pr.id == pid }
    if person.nil?
      puts 'Person not found'
      return
    end
    if person.rentals.empty?
      puts 'No rentals for this person'
      return
    end
    puts 'Rentals:'
    person.rentals.each { |r| puts "Date: #{r.date}, Book: \"#{r.book.title}\" by #{r.book.author}" }
  end

  private

  def read_input
    input = gets
    input.nil? ? '' : input.to_s.chomp.strip
  end

  def read_age
    input = read_input
    return nil unless integer_string?(input)

    age = input.to_i
    age.negative? ? nil : age
  end

  def integer_string?(str)
    !str.nil? && str.to_s.match?(/\A-?\d+\z/)
  end

  def valid_indices?(p_i, b_i)
    p_i >= 0 && p_i < @people.length && b_i >= 0 && b_i < @books.length
  end
end