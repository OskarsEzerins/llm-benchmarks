require 'date'

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
    choice = nil
    loop do
      print 'Do you want to create a student (1) or a teacher (2)? [Input the number]: '
      choice = gets.chomp
      break if %w[1 2].include?(choice)
      puts 'Invalid choice. Please enter 1 or 2.'
    end

    case choice
    when '1'
      create_student
    when '2'
      create_teacher
    end
  end

  def create_student
    name = nil
    loop do
      print 'Name: '
      name = gets.chomp
      break unless name.strip.empty?
      puts 'Name cannot be empty.'
    end

    age = nil
    loop do
      print 'Age: '
      input = gets.chomp
      age = Integer(input) rescue nil
      if age.nil? || age < 0
        puts 'Please enter a valid non-negative integer for age.'
      else
        break
      end
    end

    perm = nil
    loop do
      print 'Parent permission? (Y/N): '
      perm_input = gets.chomp.strip.upcase
      if %w[Y N].include?(perm_input)
        perm = (perm_input == 'Y')
        break
      end
      puts 'Please answer Y or N.'
    end

    student = Student.new(age, nil, name, parent_permission: perm)
    @people << student
    puts 'Student created successfully.'
  end

  def create_teacher
    name = nil
    loop do
      print 'Name: '
      name = gets.chomp
      break unless name.strip.empty?
      puts 'Name cannot be empty.'
    end

    age = nil
    loop do
      print 'Age: '
      input = gets.chomp
      age = Integer(input) rescue nil
      if age.nil? || age < 0
        puts 'Please enter a valid non-negative integer for age.'
      else
        break
      end
    end

    print 'Specialization: '
    spec = gets.chomp

    teacher = Teacher.new(name, spec, age)
    @people << teacher
    puts 'Teacher created successfully.'
  end

  def create_book
    print 'Title: '
    title = gets.chomp
    print 'Author: '
    author = gets.chomp
    book = Book.new(title, author)
    @books << book
    puts 'Book created successfully.'
  end

  def create_rental
    if @books.empty?
      puts 'No books available. Please create a book first.'
      return
    end
    puts 'Select a book'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title}" }
    bi = gets.chomp.to_i

    if @people.empty?
      puts 'No people registered. Please add a person first.'
      return
    end
    puts 'Select person'
    @people.each_with_index { |p, i| puts "#{i}: #{p.name}" }
    pi = gets.chomp.to_i

    unless valid_indices?(pi, bi)
      puts 'Invalid selection. Rental not created.'
      return
    end

    Rental.new(Date.today.to_s, @books[bi], @people[pi])
    puts 'Rental created successfully.'
  end

  def list_rentals
    print 'ID of person: '
    pid = gets.chomp.to_i
    p_obj = @people.find { |pr| pr.id == pid }
    if p_obj.nil?
      puts "Person with ID #{pid} not found."
    elsif p_obj.rentals.empty?
      puts 'No rentals found.'
    else
      p_obj.rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
    end
  end

  private

  def valid_indices?(p_i, b_i)
    p_i >= 0 && p_i < @people.size && b_i >= 0 && b_i < @books.size
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, 'This method should be overridden in subclasses'
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

  def add_student(stud)
    students << stud
    stud.classroom = self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id = rand(1..1000000)
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

  def initialize(age, classroom, name, parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @classroom = nil
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    @classroom = room
    room.students << self unless room.students.include?(self)
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