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
    print 'Do you want to create a student (1) or a teacher (2)? '
    choice = read_input
    case choice
    when '1'
      create_student
    when '2'
      create_teacher
    else
      puts 'Invalid option'
    end
  end

  def create_student
    print 'Name: '
    nm = read_input
    return puts('Invalid name') unless valid_name?(nm)

    print 'Age: '
    ag = parse_age(read_input)
    return puts('Invalid age') if ag.nil?

    print 'Has parent permission? [Y/N]: '
    perm_input = read_input.upcase
    unless %w[Y N].include?(perm_input)
      puts 'Invalid permission response, please enter Y or N'
      return
    end
    perm = perm_input == 'Y'

    stu = Student.new(ag, nil, nm, parent_permission: perm)
    @people << stu
    puts 'Person created successfully'
    stu
  end

  def create_teacher
    print 'Name: '
    nm = read_input
    return puts('Invalid name') unless valid_name?(nm)

    print 'Age: '
    ag = parse_age(read_input)
    return puts('Invalid age') if ag.nil?

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
    return puts('Invalid title') unless valid_name?(t)

    print 'Author: '
    a = read_input
    return puts('Invalid author') unless valid_name?(a)

    book = Book.new(t, a)
    @books << book
    puts 'Book created successfully'
    book
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'You need at least one book and one person to create a rental'
      return
    end

    puts 'Select a book from the following list by number'
    @books.each_with_index { |b, i| puts "#{i}) Title: #{b.title}, Author: #{b.author}" }
    bi = read_input.to_i

    puts 'Select a person from the following list by number (not id)'
    @people.each_with_index do |p, i|
      puts "#{i}) [#{p.class}] Name: #{p.name}, ID: #{p.id}, Age: #{p.age}"
    end
    pi = read_input.to_i

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
    pid = read_input.to_i
    p_obj = @people.find { |pr| pr.id == pid }
    if p_obj.nil?
      puts 'Person not found'
      return
    end
    if p_obj.rentals.empty?
      puts 'No rentals found for this person'
      return
    end
    puts 'Rentals:'
    p_obj.rentals.each { |r| puts "Date: #{r.date}, Book \"#{r.book.title}\" by #{r.book.author}" }
  end

  private

  def read_input
    input = gets
    input.nil? ? '' : input.chomp.strip
  end

  def valid_name?(nm)
    !nm.nil? && !nm.strip.empty?
  end

  def parse_age(input)
    return nil if input.nil? || input.strip.empty?
    return nil unless input.strip.match?(/\A\d+\z/)

    age = input.strip.to_i
    age.negative? ? nil : age
  end

  def valid_indices?(p_i, b_i)
    p_i >= 0 && p_i < @people.length && b_i >= 0 && b_i < @books.length
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
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
    name = super
    name.length > 10 ? name[0..9] : name
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

  def add_student(stud)
    @students << stud unless @students.include?(stud)
    stud.assign_classroom(self)
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals
  attr_reader :parent_permission

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    super()
    @id = rand(1..1000)
    @name = name
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
    room.students << self unless room.nil? || room.students.include?(self)
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