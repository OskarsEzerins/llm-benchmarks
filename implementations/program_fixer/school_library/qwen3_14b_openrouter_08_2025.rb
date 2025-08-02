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
      puts "[#{human.class}] id: #{human.id}, Name: #{human.correct_name}, Age: #{human.age}"
    end
  end

  def create_person
    print 'Student(3) or Teacher(1)? '
    choice = gets.chomp
    if choice == '1'
      create_teacher
    elsif choice == '3'
      create_student
    else
      puts 'Invalid choice'
    end
  end

  def create_student
    print 'Name: '
    nm = gets.chomp
    print 'Age: '
    ag = gets.chomp
    print 'Parent permission? (Y/N) '
    perm = gets.chomp
    begin
      age = Integer(ag)
      if age < 0
        puts 'Invalid age. Must be a positive integer.'
        return
      end
    rescue ArgumentError
      puts 'Invalid age. Must be a positive integer.'
      return
    end
    perm_valid = perm.upcase == 'Y' || perm.upcase == 'N'
    if !perm_valid
      puts 'Invalid parent permission. Must be Y or N.'
      return
    end
    stu = Student.new(age, nil, nm, parent_permission: perm_valid)
    @people << stu
  end

  def create_teacher
    print 'Name: '
    nm = gets.chomp
    print 'Age: '
    ag = gets.chomp
    print 'Specialization: '
    spec = gets.chomp
    begin
      age = Integer(ag)
      if age < 0
        puts 'Invalid age. Must be a positive integer.'
        return
      end
    rescue ArgumentError
      puts 'Invalid age. Must be a positive integer.'
      return
    end
    t = Teacher.new(nm, spec, age)
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
    puts 'Select a book'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title}" }
    bi = gets.chomp.to_i
    puts 'Select person'
    @people.each_with_index { |p, i| puts "#{i}: #{p.correct_name}" }
    pi = gets.chomp.to_i
    if bi.between?(0, @books.size - 1) && pi.between?(0, @people.size - 1)
      Rental.new(Date.today, @people[pi], @books[bi])
    else
      puts 'Invalid selection'
    end
  end

  def list_rentals
    print 'ID of person: '
    pid = gets.chomp
    p_obj = @people.find { |pr| pr.id == pid }
    if p_obj
      p_obj.rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
    else
      puts 'Person not found'
    end
  end

  private

  def valid_indices?(p_i, b_i)
    p_i.between?(0, @people.size - 1) && b_i.between?(0, @books.size - 1)
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
    super.capitalize
  end
end

class Rental
  def initialize(date, person, book)
    @date   = date
    @book   = book
    @person = person
    book.rentals << self
    person.rentals << self
  end
end

class Book
  def initialize(title, author)
    @title    = title
    @author   = author
    @rentals  = []
  end

  def add_rental(person, date)
    Rental.new(date, person, self)
  end
end

class Classroom
  attr_accessor :label, :students

  def initialize(label)
    @label  = label
    @students = []
  end

  def add_student(stud)
    students << stud
    stud.assign_classroom(self)
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
    @age >= 18 || @parent_permission
  end

  def correct_name
    @name
  end

  def add_rental(book, date)
    Rental.new(date, self, book)
  end

  private

  def of_age?
    @age > 17
  end
end

class Student < Person
  attr_reader :classroom

  def initialize(age, classroom, name, parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @classroom = nil
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

  def initialize(name, specialization, age = 0)
    super(name, age)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end