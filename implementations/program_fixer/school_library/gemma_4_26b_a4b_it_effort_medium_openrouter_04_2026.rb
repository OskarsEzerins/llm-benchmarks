require 'date'

class Nameable
  def correct_name
    raise NotImplementedError
  end
end

class Decorator < Nameable
  def initialize(nameable)
    @nameble = nameable
  end

  def correct_name
    @nameble.correct_name
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

  def add_student(student)
    @students << student unless @students.include?(student)
    student.classroom = self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals, :parent_permission

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
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
  attr_accessor :classroom

  def initialize(age, classroom, name, parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @classroom = classroom
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
    choice = gets.chomp
    if choice == '3'
      create_student
    elsif choice == '1'
      create_teacher
    else
      puts 'Invalid selection'
    end
  end

  def create_student
    print 'Name: '
    nm = gets.chomp
    return if nm.empty?
    print 'Age: '
    ag = gets.to_i
    print 'Parent permission? (Y/N) '
    perm = gets.chomp.upcase == 'Y'
    stu = Student.new(ag, nil, nm, parent_permission: perm)
    @people << stu
  end

  def create_teacher
    print 'Name: '
    nm = gets.chomp
    return if nm.empty?
    print 'Age: '
    ag = gets.to_i
    print 'Specialization: '
    spec = gets.chomp
    t = Teacher.new(ag, spec, nm)
    @people << t
  end

  def create_book
    print 'Title: '
    t = gets.chomp
    return if t.empty?
    print 'Author: '
    a = gets.chomp
    return if a.empty?
    @books << Book.new(t, a)
  end

  def create_rental
    return if @books.empty? || @people.empty?
    puts 'Select a book'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title}" }
    bi = gets.to_i
    return puts 'Invalid index' if bi < 0 || bi >= @books.size

    puts 'Select person'
    @people.each_with_index { |p, i| puts "#{i}: #{p.name}" }
    pi = gets.to_i
    return puts 'Invalid index' if pi < 0 || pi >= @people.size

    Rental.new(Date.today.to_s, @books[bi], @people[pi])
  end

  def list_rentals
    print 'ID of person: '
    pid = gets.to_i
    p_obj = @people.find { |pr| pr.id == pid }
    if p_obj
      p_obj.rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
    else
      puts "Person not found"
    end
  end
end