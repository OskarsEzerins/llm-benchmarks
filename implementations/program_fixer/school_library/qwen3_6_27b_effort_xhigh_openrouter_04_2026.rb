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
    super[0, 10]
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
    @date   = date
    @book   = book
    @person = person
    @book.rentals << self
    @person.rentals << self
  end
end

class Book
  attr_reader :title, :author, :rentals

  def initialize(t, a)
    @title    = t
    @author   = a
    @rentals  = []
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

  def add_student(stud)
    students << stud unless students.include?(stud)
    stud.classroom = self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals
  attr_reader :parent_permission

  def initialize(name = 'Unknown', age = 0, parent_permission: false)
    @id = rand(10000)
    @name = name
    @age = age.to_i
    @parent_permission = parent_permission
    @rentals = []
  end

  def can_use_services?
    @age >= 18 || @parent_permission
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

  def initialize(age, classroom, name, parent_permission: false)
    super(name, age, parent_permission: parent_permission)
    @classroom = classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    return unless room
    room.students << self unless room.students.include?(self)
    @classroom = room
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
    choice = gets.chomp.strip
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
    nm = gets.chomp.strip
    print 'Age: '
    ag = gets.chomp.strip.to_i
    ag = 0 if ag < 0
    print 'Parent permission? (Y/N): '
    perm = gets.chomp.strip.upcase
    stu = Student.new(ag, nil, nm, parent_permission: perm == 'Y')
    @people << stu
    puts "Student created: #{stu.name}"
  end

  def create_teacher
    print 'Name: '
    nm = gets.chomp.strip
    print 'Age: '
    ag = gets.chomp.strip.to_i
    ag = 0 if ag < 0
    t = Teacher.new(nm, nil, ag)
    @people << t
    puts "Teacher created: #{t.name}"
  end

  def create_book
    print 'Title: '
    t = gets.chomp.strip
    print 'Author: '
    a = gets.chomp.strip
    @books << Book.new(t, a)
    puts "Book created: #{t}"
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'No books or people available.'
      return
    end
    puts 'Select a book:'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title}" }
    bi = gets.chomp.strip.to_i
    puts 'Select person:'
    @people.each_with_index { |p, i| puts "#{i}: #{p.name}" }
    pi = gets.chomp.strip.to_i

    if valid_indices?(pi, bi)
      Rental.new(Date.today, @books[bi], @people[pi])
      puts "Rental created successfully."
    else
      puts "Invalid selection."
    end
  end

  def list_rentals
    print 'ID of person: '
    pid = gets.chomp.strip.to_i
    p_obj = @people.detect { |pr| pr.id == pid }
    if p_obj
      puts p_obj.rentals.empty? ? 'No rentals found.' : ''
      p_obj.rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
    else
      puts 'Person not found.'
    end
  end

  private

  def valid_indices?(p_i, b_i)
    p_i >= 0 && p_i < @people.length && b_i >= 0 && b_i < @books.length
  end
end