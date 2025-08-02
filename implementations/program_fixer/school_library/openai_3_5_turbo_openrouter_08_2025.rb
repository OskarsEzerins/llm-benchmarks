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
    print 'Student(3) or Teacher(1)? '
    choice = gets.chomp
    create_teacher if choice == '1'
    create_student if choice == '3'
  end

  def create_student
    print 'Name: '
    nm = gets.chomp
    print 'Age: '
    ag = gets.to_i
    print 'Parent permission? '
    perm = gets.chomp
    stu = Student.new(ag, nil, nm, parent_permission: perm == 'Y')
    @people << stu
  end

  def create_teacher
    print 'Name: '
    nm = gets.chomp
    print 'Age: '
    ag = gets.to_i
    print 'Specialization: '
    spec = gets.chomp
    t = Teacher.new(ag, nm, spec)
    @people.push(t)
  end

  def create_book
    print 'Title: '
    t = gets.chomp
    print 'Author: '
    a = gets.chomp
    @books << Book.new(t, a)
  end

  def create_rental
    puts 'Select a book'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title}" }
    bi = gets.to_i
    puts 'Select person'
    @people.each_with_index { |p, i| puts "#{i}: #{p.name}" }
    pi = gets.to_i
    Rental.new(Date.today, @books[bi], @people[pi])
  end

  def list_rentals
    print 'ID of person: '
    pid = gets.to_i
    p_obj = @people.detect { |pr| pr.id == pid }
    p_obj.rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
  end

  private

  def valid_indices?(p_i, b_i)
    p_i < @people.length && b_i < @books.size
  end
end

class Nameable
  def correct_name
    nil
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
    @nameable.correct_name.capitalize
  end
end

class Rental
  attr_reader :date, :book, :person

  def initialize(date, book, person)
    @date   = date
    @book   = book
    @person = person
    book.rentals << self
    person.rentals << self
  end
end

class Book
  attr_reader :title, :author
  attr_accessor :rentals

  def initialize(title, author)
    @title    = title
    @author   = author
    @rentals  = []
  end

  def add_rental(person, date)
    Rental.new(date, self, person)
  end
end

class Classroom
  attr_accessor :label, :students

  def initialize(label)
    @label    = label
    @students = []
  end

  def add_student(stud)
    students << stud
    stud.assign_classroom(self)
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals

  def initialize(age, name = 'Unknown', parent_permission: true)
    @id = rand(1000)
    @name = name
    @age = age
    @parent_permission = parent_permission
    @rentals = []
  end

  def can_use_services?
    of_age? && @parent_permission
  end

  def correct_name
    name
  end

  def add_rental(book, date)
    Rental.new(date, book, self)
  end

  private

  def of_age?
    @age > 17
  end
end

class Student < Person
  attr_reader :classroom

  def initialize(age, classroom, name, parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    @classroom = classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def assign_classroom(room)
    @classroom = room
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, name, specialization)
    super(age, name)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end