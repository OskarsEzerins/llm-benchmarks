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
    name = @nameable.correct_name.to_s
    name.length > 10 ? name[0, 10] : name
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    @nameable.correct_name.to_s.capitalize
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

class Classroom
  attr_accessor :label
  attr_reader :students

  def initialize(label)
    @label = label
    @students = []
  end

  def add_student(stud)
    @students << stud unless @students.include?(stud)
    stud.classroom = self if stud.classroom != self
  end
end

class Person < Nameable
  attr_accessor :name, :age, :rentals
  attr_reader :id, :parent_permission

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    super()
    @id = rand(1..1_000_000)
    @name = name
    @age = age
    @parent_permission = parent_permission ? true : false
    @rentals = []
  end

  def id=(value)
    @id = value.to_i
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
    @age.to_i >= 18
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

  def initialize(age, specialization, name = 'Unknown')
    super(name, age, parent_permission: true)
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
    print 'Student(3) or Teacher(1)? '
    choice = read_line
    case choice
    when '1' then create_teacher
    when '3' then create_student
    else
      puts 'Invalid option'
      nil
    end
  end

  def create_student
    print 'Name: '
    nm = read_line
    nm = 'Unknown' if nm.empty?
    print 'Age: '
    ag = parse_age(read_line)
    return puts('Invalid age') if ag.nil?

    print 'Parent permission? (Y/N) '
    perm = read_line.upcase
    return puts('Invalid permission response') unless %w[Y N].include?(perm)

    stu = Student.new(ag, nil, nm, parent_permission: perm == 'Y')
    @people << stu
    stu
  end

  def create_teacher
    print 'Name: '
    nm = read_line
    nm = 'Unknown' if nm.empty?
    print 'Age: '
    ag = parse_age(read_line)
    return puts('Invalid age') if ag.nil?

    print 'Specialization: '
    spec = read_line
    t = Teacher.new(ag, spec, nm)
    @people << t
    t
  end

  def create_book
    print 'Title: '
    t = read_line
    print 'Author: '
    a = read_line
    book = Book.new(t, a)
    @books << book
    book
  end

  def create_rental
    return puts('No books or people available') if @books.empty? || @people.empty?

    puts 'Select a book'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title}" }
    bi = Integer(read_line, exception: false)
    puts 'Select person'
    @people.each_with_index { |p, i| puts "#{i}: #{p.name}" }
    pi = Integer(read_line, exception: false)
    return puts('Invalid selection') unless bi && pi && valid_indices?(pi, bi)

    print 'Date: '
    date = read_line
    date = Date.today.to_s if date.empty?
    Rental.new(date, @books[bi], @people[pi])
  end

  def list_rentals
    print 'ID of person: '
    pid = Integer(read_line, exception: false)
    p_obj = @people.detect { |pr| pr.id == pid }
    return puts('Person not found') unless p_obj

    p_obj.rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
  end

  private

  def read_line
    (gets || '').chomp.strip
  end

  def parse_age(str)
    age = Integer(str, exception: false)
    age && age >= 0 ? age : nil
  end

  def valid_indices?(p_i, b_i)
    p_i >= 0 && p_i < @people.length && b_i >= 0 && b_i < @books.size
  end
end