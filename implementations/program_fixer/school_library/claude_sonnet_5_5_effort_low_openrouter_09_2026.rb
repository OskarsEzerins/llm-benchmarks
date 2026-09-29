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
    stud.instance_variable_set(:@classroom, self)
  end
end

class Person < Nameable
  attr_accessor :name, :age, :rentals
  attr_reader :id, :parent_permission
  attr_writer :id

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    super()
    @id = rand(1..100_000)
    @name = (name.nil? || name.to_s.strip.empty?) ? 'Unknown' : name.to_s
    @age = age.to_i
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
    room.students << self if room && !room.students.include?(self)
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

class App
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
    choice = gets.to_s.chomp
    case choice
    when '1' then create_student
    when '2' then create_teacher
    else puts 'Invalid option'
    end
  end

  def create_student
    print 'Name: '
    nm = gets.to_s.chomp
    ag = read_age
    return if ag.nil?

    print 'Parent permission? [Y/N]: '
    perm = gets.to_s.chomp.upcase
    unless %w[Y N].include?(perm)
      puts 'Invalid permission response'
      return
    end
    stu = Student.new(ag, nil, nm, parent_permission: perm == 'Y')
    @people << stu
    puts 'Student created'
    stu
  end

  def create_teacher
    print 'Name: '
    nm = gets.to_s.chomp
    ag = read_age
    return if ag.nil?

    print 'Specialization: '
    spec = gets.to_s.chomp
    t = Teacher.new(ag, spec, nm)
    @people << t
    puts 'Teacher created'
    t
  end

  def create_book
    print 'Title: '
    t = gets.to_s.chomp
    print 'Author: '
    a = gets.to_s.chomp
    book = Book.new(t, a)
    @books << book
    puts 'Book created'
    book
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'Need at least one book and one person'
      return
    end
    puts 'Select a book'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title}" }
    bi = Integer(gets.to_s.chomp, exception: false)
    puts 'Select person'
    @people.each_with_index { |p, i| puts "#{i}: #{p.name}" }
    pi = Integer(gets.to_s.chomp, exception: false)
    unless valid_indices?(pi, bi)
      puts 'Invalid selection'
      return
    end
    print 'Date: '
    date = gets.to_s.chomp
    date = Date.today.to_s if date.empty?
    Rental.new(date, @books[bi], @people[pi])
  end

  def list_rentals
    print 'ID of person: '
    pid = Integer(gets.to_s.chomp, exception: false)
    p_obj = @people.detect { |pr| pr.id == pid }
    if p_obj.nil?
      puts 'Person not found'
      return
    end
    p_obj.rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
  end

  private

  def read_age
    print 'Age: '
    ag = Integer(gets.to_s.chomp, exception: false)
    if ag.nil? || ag.negative?
      puts 'Invalid age'
      return nil
    end
    ag
  end

  def valid_indices?(p_i, b_i)
    return false if p_i.nil? || b_i.nil?

    p_i >= 0 && p_i < @people.length && b_i >= 0 && b_i < @books.size
  end
end