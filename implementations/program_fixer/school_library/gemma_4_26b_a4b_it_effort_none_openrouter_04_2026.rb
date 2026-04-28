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
    puts 'No one has registered' if @people.empty?
    @people.each do |human|
      puts "[#{human.class}] id: #{human.id}, Name: #{human.name}, Age: #{human.age}"
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
      puts "Invalid choice"
    end
  end

  def create_student
    print 'Name: '
    nm = gets.chomp
    return puts "Name cannot be empty" if nm.empty?
    print 'Age: '
    ag_input = gets.chomp
    ag = ag_input.to_i
    return puts "Invalid age" if ag <= 0 && ag_input != "0"

    print 'Parent permission? (Y/N) '
    perm_input = gets.chomp.upcase
    unless ['Y', 'N'].include?(perm_input)
      puts "Invalid input"
      return
    end
    perm = perm_input == 'Y'

    stu = Student.new(ag, nil, nm, parent_permission: perm)
    @people << stu
  end

  def create_teacher
    print 'Name: '
    nm = gets.chomp
    return puts "Name cannot be empty" if nm.empty?
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
    return puts "Title cannot be empty" if t.empty?
    print 'Author: '
    a = gets.chomp
    return puts "Author cannot be empty" if a.empty?
    @books << Book.new(t, a)
  end

  def create_rental
    return puts "No books available" if @books.empty?
    return puts "No people registered" if @people.empty?

    puts 'Select a book'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title}" }
    bi = gets.to_i

    puts 'Select person'
    @people.each_with_index { |p, i| puts "#{i}: #{p.name}" }
    pi = gets.to_i

    if bi >= 0 && bi < @books.size && pi >= 0 && pi < @people.size
      Rental.new(Date.today, @books[bi], @people[pi])
    else
      puts "Invalid selection"
    end
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
    super[0..9]
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    super.split.map(&:capitalize).join(' ')
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
  attr_accessor :title, :author, :rentals
  def initialize(t, a)
    @title    = t
    @author   = a
    @rentals  = []
  end
end

class Classroom
  attr_accessor :label, :students

  def initialize(label)
    @label   = label
    @students = []
  end

  def add_student(stud)
    @students << stud unless @students.include?(stud)
    stud.classroom = self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals, :parent_permission

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id = rand(1000..9999)
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

  def initialize(name, specialization, age = 0)
    super(name, age)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end