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
        puts "[#{human.class}] id: #{human.id}, Name: #{human.name}, Age: #{human.age}"
      end
    end
  end

  def create_person
    print 'Student(3) or Teacher(1)? '
    choice = gets.chomp

    case choice
    when '1'
      create_teacher
    when '3'
      create_student
    else
      puts 'Invalid selection'
    end
  end

  def create_student
    print 'Name: '
    nm = gets.chomp
    print 'Age: '
    ag = gets.chomp.to_i
    print 'Parent permission? (Y/N): '
    perm_input = gets.chomp.upcase
    perm = perm_input == 'Y'

    if ag < 0
      puts 'Invalid age. Age must be a positive number.'
      return
    end

    stu = Student.new(ag, nil, nm, parent_permission: perm)
    @people << stu
  end

  def create_teacher
    print 'Name: '
    nm = gets.chomp
    print 'Age: '
    ag = gets.chomp.to_i
    print 'Specialization: '
    spec = gets.chomp

    if ag < 0
      puts 'Invalid age. Age must be a positive number.'
      return
    end

    t = Teacher.new(ag, spec, nm)
    @people << t
  end

  def create_book
    print 'Title: '
    t = gets.chomp
    print 'Author: '
    a = gets.chomp

    @books << Book.new(t, a)
  end

  def create_rental
    if @books.empty?
      puts 'No books available'
      return
    end

    if @people.empty?
      puts 'No people available'
      return
    end

    puts 'Select a book'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title}" }

    begin
      bi = Integer(gets.chomp)
    rescue ArgumentError
      puts 'Invalid input for book selection'
      return
    end

    if bi < 0 || bi >= @books.size
      puts 'Invalid book selection'
      return
    end

    puts 'Select person'
    @people.each_with_index { |p, i| puts "#{i}: #{p.name}" }

    begin
      pi = Integer(gets.chomp)
    rescue ArgumentError
      puts 'Invalid input for person selection'
      return
    end

    if pi < 0 || pi >= @people.size
      puts 'Invalid person selection'
      return
    end

    Rental.new(Date.today, @books[bi], @people[pi])
  end

  def list_rentals
    print 'ID of person: '
    pid = gets.chomp.to_i

    p_obj = @people.detect { |pr| pr.id == pid }

    if p_obj
      if p_obj.rentals.empty?
        puts 'No rentals for this person'
      else
        p_obj.rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
      end
    else
      puts 'Person not found'
    end
  end

  private

  def valid_indices?(p_i, b_i)
    p_i >= 0 && p_i < @people.size && b_i >= 0 && b_i < @books.size
  end
end

class Nameable
  def correct_name
    name
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
  attr_accessor :date, :book, :person

  def initialize(date, book, person)
    @date = date
    @book = book
    @person = person
    @book.rentals << self
    @person.rentals << self
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
  attr_accessor :id, :name, :age, :rentals

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id = rand(1000) + 1
    @name = name
    @age = age
    @parent_permission = parent_permission
    @rentals = []
  end

  def can_use_services?
    of_age? || parent_permission
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

  def assign_classroom(room)
    @classroom = room
    room.add_student(self) if room
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name)
    super(name, age)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end