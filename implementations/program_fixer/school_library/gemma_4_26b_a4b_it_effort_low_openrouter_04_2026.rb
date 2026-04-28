require 'date'

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
    super[0..9]
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
  attr_reader :title, :author, :rentals

  def initialize(title, author)
    @title = title
    @author = author
    @rentals = []
  end
end

class Classroom
  attr_accessor :label, :students

  def initialize(label)
    @label = label
    @students = []
  end

  def add_student(stud)
    unless @students.include?(stud)
      @students << stud
      stud.assign_classroom(self)
    end
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals, :parent_permission

  def initialize(name, age, parent_permission: true)
    @id = rand(1000)
    @name = name
    @age = age.to_i
    @parent_permission = parent_permission
    @rentals = []
  end

  def can_use_services?
    of_age? || @parent_permission
  end

  def correct_name
    @name
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
    classroom.add_student(self) if classroom
  end

  def assign_classroom(room)
    @classroom = room
  end

  def classroom=(room)
    @classroom = room
    room.add_student(self) if room
  end

  def play_hooky
    '╰(°▽°)╯'
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

class App
  def initialize
    @books = []
    @people = []
  end

  def list_books
    puts 'No books available' if @books.empty?
    @books.each { |bk| puts "title: #{bk.title}, author: #{bk.author}" }
  end

  def list_people
    puts 'No one has registered' if @people.empty?
    @people.each { |h| puts "[#{h.class}] id: #{h.id}, Name: #{h.name}, Age: #{h.age}" }
  end

  def create_person
    print 'Student(2) or Teacher(1)? '
    choice = gets.chomp
    case choice
    when '1' then create_teacher
    when '2' then create_student
    else puts "Invalid selection"
    end
  end

  def create_student
    print 'Name: '
    nm = gets.chomp
    return puts "Invalid name" if nm.empty?
    print 'Age: '
    ag = gets.chomp.to_i
    return puts "Invalid age" if ag <= 0
    print 'Parent permission? (Y/N) '
    perm_input = gets.chomp.upcase
    return puts "Invalid permission" unless ['Y', 'N'].include?(perm_input)
    perm = (perm_input == 'Y')
    stu = Student.new(ag, nil, nm, parent_permission: perm)
    @people << stu
  end

  def create_teacher
    print 'Name: '
    nm = gets.chomp
    return puts "Invalid name" if nm.empty?
    print 'Age: '
    ag = gets.chomp.to_i
    return puts "Invalid age" if ag <= 0
    print 'Specialization: '
    spec = gets.chomp
    t = Teacher.new(ag, spec, nm)
    @people << t
  end

  def create_book
    print 'Title: '
    t = gets.chomp
    return puts "Invalid title" if t.empty?
    print 'Author: '
    a = gets.chomp
    return puts "Invalid author" if a.empty?
    @books << Book.new(t, a)
  end

  def create_rental
    return puts "No books available" if @books.empty?
    return puts "No people registered" if @people.empty?
    puts 'Select a book'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title}" }
    bi = gets.to_i
    return puts "Invalid book index" unless bi.between?(0, @books.size - 1)
    puts 'Select person'
    @people.each_with_index { |p, i| puts "#{i}: #{p.name}" }
    pi = gets.to_i
    return puts "Invalid person index" unless pi.between?(0, @people.size - 1)
    Rental.new(Date.today, @books[bi], @people[pi])
  end

  def list_rentals
    print 'ID of person: '
    pid_input = gets.chomp
    return puts "Invalid ID" if pid_input.empty?
    pid = pid_input.to_i
    p_obj = @people.find { |pr| pr.id == pid }
    if p_obj
      p_obj.rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
    else
      puts "Person not found"
    end
  end

  def valid_indices?(p_i, b_i)
    p_i >= 0 && p_i < @people.length && b_i >= 0 && b_i < @books.size
  end
end