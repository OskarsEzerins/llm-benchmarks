require 'date'

# Decorator Pattern for name formatting
class Nameable
  def correct_name
    raise NotImplementedError, 'Subclasses must implement correct_name'
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
    value = super
    value[0, 10]
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    super.capitalize
  end
end

# Core domain models
class Book
  attr_accessor :title, :author, :rentals

  def initialize(title, author)
    @title = title
    @author = author
    @rentals = []
  end

  def add_rental(rental)
    @rentals << rental
  end
end

class Rental
  attr_reader :date, :book, :person

  def initialize(date, book, person)
    @date = date
    @book = book
    @person = person
    book.add_rental(self)
    person.add_rental(self)
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
    student.classroom = self if student.respond_to?(:classroom=) && student.classroom != self
  end
end

class Person
  @@next_id = 1
  attr_reader :id
  attr_accessor :name, :age, :rentals

  def initialize(age, name, parent_permission: true)
    @id = @@next_id
    @@next_id += 1
    @age = age
    @name = name
    @parent_permission = parent_permission
    @rentals = []
  end

  def can_use_services?
    @age >= 18 && @parent_permission
  end

  def correct_name
    @name
  end

  def add_rental(rental)
    @rentals << rental
  end

  protected

  def parent_permission
    @parent_permission
  end
end

class Student < Person
  attr_accessor :classroom

  def initialize(age, classroom, name, parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    @classroom = classroom
  end

  def classroom=(room)
    @classroom = room
  end

  def play_hooky
    '╰(°▽°)╯'
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name)
    super(age, name, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end

# Application orchestrator
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
    puts 'Student(3) or Teacher(1)? '
    choice = gets
    case choice&.strip
    when '3'
      create_student
    when '1'
      create_teacher
    else
      puts 'Invalid option'
    end
  end

  def create_student
    print 'Name: '
    nm = gets&.chomp
    nm = '' if nm.nil?
    print 'Age: '
    ag = gets.to_i
    print 'Parent permission? '
    perm = gets&.chomp
    parent_permission = (perm&.strip&.upcase == 'Y')
    if nm.strip.empty? || ag <= 0
      puts 'Invalid student data'
      return
    end
    stu = Student.new(ag, nil, nm, parent_permission: parent_permission)
    @people << stu
  end

  def create_teacher
    print 'Name: '
    nm = gets&.chomp
    print 'Age: '
    ag = gets.to_i
    print 'Specialization: '
    spec = gets&.chomp
    if nm.nil? || nm.strip.empty? || ag <= 0
      puts 'Invalid teacher data'
      return
    end
    t = Teacher.new(ag, spec, nm)
    @people << t
  end

  def create_book
    print 'Title: '
    t = gets&.chomp
    print 'Author: '
    a = gets&.chomp
    if t.nil? || t.strip.empty? || a.nil? || a.strip.empty?
      puts 'Invalid book data'
      return
    end
    book = Book.new(t, a)
    @books << book
  end

  def create_rental
    if @books.empty?
      puts 'No books available'
      return
    end
    if @people.empty?
      puts 'No people registered'
      return
    end
    puts 'Select a book by number'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title} by #{b.author}" }
    bi = gets.to_i
    unless bi.is_a?(Integer) && bi >= 0 && bi < @books.length
      puts 'Invalid book index'
      return
    end
    puts 'Select a person by number'
    @people.each_with_index { |p, i| puts "#{i}: #{p.name} (id: #{p.id})" }
    pi = gets.to_i
    unless pi.is_a?(Integer) && pi >= 0 && pi < @people.length
      puts 'Invalid person index'
      return
    end
    date = Date.today
    Rental.new(date, @books[bi], @people[pi])
  end

  def list_rentals
    print 'ID of person: '
    pid_str = STDIN.gets&.chomp
    pid = pid_str.to_i
    p_obj = @people.find { |pr| pr.id == pid }
    if p_obj.nil?
      puts 'No person found with that ID'
      return
    end
    if p_obj.rentals.nil? || p_obj.rentals.empty?
      puts 'No rentals found for this person'
    else
      p_obj.rentals.each do |r|
        puts "#{r.date} - #{r.book.title}"
      end
    end
  end
end