class App
  def initialize
    @books = []
    @people = []
  end

  def list_books
    if @books.empty?
      puts 'No books available'
    else
      @books.each do |bk|
        puts "title: #{bk.title}, author: #{bk.author}"
      end
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
    else
      @people.each do |human|
        puts "[#{human.class}] id: #{human.id}, Name: #{human.correct_name}, Age: #{human.age}"
      end
    end
  end

  def create_person
    print 'Teacher(1) or Student(3)? '
    choice = gets.chomp
    case choice
    when '1'
      create_teacher
    when '3'
      create_student
    else
      puts 'Invalid choice'
    end
  end

  def create_student
    print 'Name: '
    nm = gets.chomp
    print 'Age: '
    ag = gets.chomp.to_i
    print 'Parent permission? [Y/N]: '
    perm_input = gets.chomp.upcase
    parent_permission = perm_input == 'Y'
    stu = Student.new(ag, nil, nm, parent_permission: parent_permission)
    @people << stu
  end

  def create_teacher
    print 'Name: '
    nm = gets.chomp
    print 'Age: '
    ag = gets.chomp.to_i
    print 'Specialization: '
    spec = gets.chomp
    t = Teacher.new(nm, spec, ag)
    @people << t
  end

  def create_book
    print 'Title: '
    t = gets.chomp
    print 'Author: '
    a = gets.chomp
    book = Book.new(t, a)
    @books << book
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'You need at least one book and one person to create a rental'
      return
    end
    puts 'Select a book:'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title}" }
    bi = gets.chomp.to_i
    if bi < 0 || bi >= @books.size
      puts 'Invalid book selection'
      return
    end
    puts 'Select a person:'
    @people.each_with_index { |p, i| puts "#{i}: #{p.name}" }
    pi = gets.chomp.to_i
    if pi < 0 || pi >= @people.size
      puts 'Invalid person selection'
      return
    end
    print 'Date (YYYY-MM-DD): '
    date = gets.chomp
    Rental.new(date, @books[bi], @people[pi])
  end

  def list_rentals
    print 'ID of person: '
    pid = gets.chomp.to_i
    person = @people.detect { |pr| pr.id == pid }
    if person
      if person.rentals.empty?
        puts 'No rentals found for this person'
      else
        person.rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
      end
    else
      puts 'Person not found'
    end
  end

  private

  def valid_indices?(p_i, b_i)
    p_i < @people.length && b_i < @books.size
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, 'This method should be overridden in a subclass'
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
    super[0...10]
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
    book.rentals << self
    person.rentals << self
  end
end

class Book
  attr_reader :title, :author
  attr_accessor :rentals

  def initialize(t, a)
    @title = t
    @author = a
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
    student.classroom = self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id = rand(1000)
    @name = name
    @age = age
    @parent_permission = parent_permission
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
  attr_accessor :classroom

  def initialize(age, classroom, name, parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @classroom = classroom
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

  def initialize(name, specialization, age = 0)
    super(name, age, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end