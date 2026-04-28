require 'date'

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
    super.to_s[0..9]
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    super.to_s.capitalize
  end
end

class Person < Nameable
  attr_reader :id, :name, :age, :rentals

  def initialize(name = 'Unknown', age = 0, parent_permission: false)
    @id = rand(1000)
    @name = name.to_s
    @age = age.to_i
    @parent_permission = !!parent_permission
    @rentals = []
  end

  def can_use_services?
    @age >= 18 || @parent_permission
  end

  def correct_name
    @name
  end

  def parent_permission
    @parent_permission
  end
end

class Student < Person
  attr_reader :classroom

  def initialize(age, classroom, name, parent_permission: false)
    super(name, age, parent_permission: parent_permission)
    @classroom = classroom
    classroom.students << self if classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    return if room.nil?
    @classroom = room
    room.students << self unless room.students.include?(self)
  end
end

class Teacher < Person
  attr_reader :specialization

  def initialize(name, specialization, age = 0)
    super(name, age)
    @specialization = specialization
  end

  def can_use_services?
    true
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

class Classroom
  attr_accessor :label, :students

  def initialize(label)
    @label = label
    @students = []
  end

  def add_student(stud)
    students << stud
    stud.classroom = self
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
    choice = gets.to_s.chomp
    case choice
    when '1' then create_teacher
    when '3' then create_student
    else puts 'Invalid selection'
    end
  end

  def create_student
    print 'Name: '
    nm = gets.to_s.chomp
    nm = 'Unknown' if nm.empty?
    print 'Age: '
    ag = gets.to_s.chomp.to_i
    ag = 0 if ag < 0
    print 'Parent permission? (Y/N) '
    perm = gets.to_s.chomp.upcase
    perm = 'N' unless ['Y', 'N'].include?(perm)
    stu = Student.new(ag, nil, nm, parent_permission: perm == 'Y')
    @people << stu
  end

  def create_teacher
    print 'Name: '
    nm = gets.to_s.chomp
    nm = 'Unknown' if nm.empty?
    print 'Age: '
    ag = gets.to_s.chomp.to_i
    ag = 0 if ag < 0
    print 'Specialization: '
    spec = gets.to_s.chomp
    spec = nil if spec.empty?
    t = Teacher.new(nm, spec, ag)
    @people << t
  end

  def create_book
    print 'Title: '
    t = gets.to_s.chomp
    print 'Author: '
    a = gets.to_s.chomp
    @books << Book.new(t, a)
  end

  def create_rental
    puts 'Select a book'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title}" }
    bi = gets.to_s.chomp.to_i
    puts 'Select person'
    @people.each_with_index { |p, i| puts "#{i}: #{p.name}" }
    pi = gets.to_s.chomp.to_i

    if valid_indices?(pi, bi)
      Rental.new(Date.today.to_s, @books[bi], @people[pi])
      puts 'Rental created successfully'
    else
      puts 'Invalid indices'
    end
  end

  def list_rentals
    print 'ID of person: '
    pid = gets.to_s.chomp.to_i
    p_obj = @people.find { |pr| pr.id == pid }
    if p_obj.nil?
      puts 'Person not found'
    else
      p_obj.rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
    end
  end

  private

  def valid_indices?(p_i, b_i)
    p_i >= 0 && p_i < @people.length && b_i >= 0 && b_i < @books.length
  end
end