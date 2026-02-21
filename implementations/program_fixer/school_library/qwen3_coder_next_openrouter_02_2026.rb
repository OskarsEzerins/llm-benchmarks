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
    @people.each_with_index do |human, i|
      puts "[#{human.class}] id: #{human.id}, Name: #{human.name}, Age: #{human.age}"
    end
  end

  def create_person
    print 'Student(1) or Teacher(2)? '
    choice = gets.strip
    case choice
    when '1'
      create_student
    when '2'
      create_teacher
    else
      puts 'Invalid choice'
    end
  end

  def create_student
    print 'Name: '
    nm = gets.strip
    if nm.empty?
      puts 'Name cannot be empty'
      return
    end
    print 'Age: '
    ag_str = gets.strip
    ag = ag_str.to_i
    if ag < 0
      puts 'Age must be non-negative'
      return
    end
    print 'Parent permission? (Y/N): '
    perm_str = gets.strip
    perm = perm_str.upcase == 'Y'
    stu = Student.new(ag, nil, nm, parent_permission: perm)
    @people << stu
  end

  def create_teacher
    print 'Name: '
    nm = gets.strip
    if nm.empty?
      puts 'Name cannot be empty'
      return
    end
    print 'Age: '
    ag_str = gets.strip
    ag = ag_str.to_i
    if ag < 0
      puts 'Age must be non-negative'
      return
    end
    print 'Specialization: '
    spec = gets.strip
    t = Teacher.new(ag, spec, nm)
    @people << t
  end

  def create_book
    print 'Title: '
    t = gets.strip
    print 'Author: '
    a = gets.strip
    @books << Book.new(t, a)
  end

  def create_rental
    puts 'Select a book:'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title}" }
    bi = gets.to_i
    if bi < 0 || bi >= @books.length
      puts 'Invalid book index'
      return
    end
    puts 'Select person:'
    @people.each_with_index { |p, i| puts "#{i}: #{p.name}" }
    pi = gets.to_i
    if pi < 0 || pi >= @people.length
      puts 'Invalid person index'
      return
    end
    print 'Date (YYYY-MM-DD): '
    d = gets.strip
    Rental.new(d, @books[bi], @people[pi])
  end

  def list_rentals
    print 'ID of person: '
    pid_str = gets.strip
    pid = pid_str.to_i
    p_obj = @people.find { |pr| pr.id == pid }
    if p_obj
      p_obj.rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
    else
      puts 'Person not found'
    end
  end

  private

  def valid_indices?(p_i, b_i)
    p_i >= 0 && p_i < @people.length && b_i >= 0 && b_i < @books.length
  end
end

class Nameable
  def correct_name
    raise NotImplementedError
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
    name = @nameable.correct_name
    name[0..9]
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    @nameable.correct_name.capitalize
  end
end

class Rental
  def initialize(date, book, person)
    @date = date
    @book = book
    @person = person
    @book.rentals << self
    @person.rentals << self
  end

  attr_reader :date, :book, :person
end

class Book
  def initialize(title, author)
    @title = title
    @author = author
    @rentals = []
  end

  attr_reader :title, :author, :rentals
end

class Classroom
  attr_accessor :label

  def initialize(label)
    @label = label
    @students = []
  end

  def students
    @students
  end

  def add_student(stud)
    students << stud unless students.include?(stud)
    stud.classroom = self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals
  attr_reader :parent_permission

  def initialize(age, specialization_or_classroom = nil, name = 'Unknown', parent_permission: true)
    @id = rand(1000)
    @name = name
    @age = age.to_i
    @parent_permission = parent_permission
    @rentals = []
  end

  def can_use_services?
    of_age? && @parent_permission
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
    super(age, nil, name, parent_permission: parent_permission)
    @classroom = nil
    @classroom = classroom unless classroom.nil?
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    @classroom = room
    room.students << self unless room.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name)
    super(age, nil, name, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end