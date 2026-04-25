require 'date'

class App
  def initialize
    @books  = []
    @people = []
  end

  def list_books
    puts 'No books available' if @books.empty?
    @books.each do |bk|
      puts "title: #{bk.title}, author: #{bk.author}"
    end
  end

  def list_people
    puts 'No one has registered' unless @people.any?
    @people.each do |human|
      puts "[#{human.class}] id: #{human.id}, Name: #{human.name}, Age: #{human.age}"
    end
  end

  def create_person
    print 'Student(1) or Teacher(2)? '
    choice = gets.chomp
    if choice == '1'
      create_student
    elsif choice == '2'
      create_teacher
    else
      puts 'Invalid choice'
    end
  end

  def create_student
    print 'Name: '
    nm = gets.chomp
    print 'Age: '
    ag = gets.chomp.to_i
    print 'Has parent permission? [Y/N]: '
    perm = gets.chomp
    parent_perm = (perm.upcase == 'Y')
    stu = Student.new(ag, nil, nm, parent_permission: parent_perm)
    @people << stu
    puts 'Person created!'
  end

  def create_teacher
    print 'Name: '
    nm = gets.chomp
    print 'Age: '
    ag = gets.chomp.to_i
    print 'Specialization: '
    spec = gets.chomp
    t = Teacher.new(ag, spec, nm)
    @people << t
    puts 'Person created!'
  end

  def create_book
    print 'Title: '
    t = gets.chomp
    print 'Author: '
    a = gets.chomp
    book = Book.new(t, a)
    @books << book
    puts 'Book created!'
  end

  def create_rental
    puts 'Select a book from the following list by number:'
    @books.each_with_index { |b, i| puts "#{i}) #{b.title}" }
    bi = gets.chomp.to_i
    
    puts 'Select a person from the following list by number (not id):'
    @people.each_with_index { |p, i| puts "#{i}) [#{p.class}] Name: #{p.name}, ID: #{p.id}, Age: #{p.age}" }
    pi = gets.chomp.to_i

    unless valid_indices?(pi, bi)
      puts 'Invalid selection.'
      return
    end

    date = Date.today.to_s
    Rental.new(date, @people[pi], @books[bi])
    puts 'Rental created!'
  end

  def list_rentals
    print 'ID of person: '
    pid = gets.chomp.to_i
    p_obj = @people.detect { |pr| pr.id == pid }
    
    if p_obj
      p_obj.rentals.each { |r| puts "Date: #{r.date}, Book: #{r.book.title}" }
    else
      puts 'Person not found.'
    end
  end

  private

  def valid_indices?(p_i, b_i)
    p_i >= 0 && p_i < @people.length && b_i >= 0 && b_i < @books.size
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
    name = super
    name.length > 10 ? name[0..9] : name
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    name = super
    name.capitalize
  end
end

class Rental
  attr_reader :date, :book, :person

  def initialize(date, person, book)
    @date   = date
    @person = person
    @book   = book
    
    @book.rentals << self
    @person.rentals << self
  end
end

class Book
  attr_reader :title, :author, :rentals

  def initialize(title, author)
    @title    = title
    @author   = author
    @rentals  = []
  end
end

class Classroom
  attr_accessor :label, :students

  def initialize(label)
    @label  = label
    @students = []
  end

  def add_student(student)
    @students << student
    student.classroom = self unless student.classroom == self
  end
end

class Person < Nameable
  attr_accessor :name, :age, :rentals
  attr_reader :id

  @@id_counter = 0

  def initialize(id = nil, name = 'Unknown', age = 0, parent_permission: true)
    @id = id || generate_id
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

  private

  def generate_id
    @@id_counter += 1
    @@id_counter
  end

  def of_age?
    @age >= 18
  end
end

class Student < Person
  attr_reader :classroom

  def initialize(age, classroom, name, parent_permission: true)
    super(nil, name, age, parent_permission: parent_permission)
    @classroom = classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    @classroom = room
    room.add_student(self) unless room.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name)
    super(nil, name, age, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end