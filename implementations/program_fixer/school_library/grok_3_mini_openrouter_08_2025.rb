class App
  def initialize
    @books = []
    @people = []
  end

  def list_books
    if @books.empty?
      puts 'No books available'
    else
      @books.each do |book|
        puts "Title: #{book.title}, Author: #{book.author}"
      end
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
    else
      @people.each do |person|
        puts "[#{person.class}] ID: #{person.id}, Name: #{person.name}, Age: #{person.age}"
      end
    end
  end

  def create_person
    print 'Do you want to create a student (1) or a teacher (2)? '
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
    print 'Age: '
    age_input = gets.chomp
    age = age_input.to_i
    if age <= 0
      puts 'Age must be a positive integer'
      return
    end
    print 'Name: '
    name = gets.chomp
    print 'Has parent permission? [Y/N]: '
    perm = gets.chomp.upcase
    parent_permission = perm == 'Y'
    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
  end

  def create_teacher
    print 'Age: '
    age_input = gets.chomp
    age = age_input.to_i
    if age <= 0
      puts 'Age must be a positive integer'
      return
    end
    print 'Name: '
    name = gets.chomp
    print 'Specialization: '
    specialization = gets.chomp
    teacher = Teacher.new(name, specialization, age)
    @people << teacher
  end

  def create_book
    print 'Title: '
    title = gets.chomp
    print 'Author: '
    author = gets.chomp
    book = Book.new(title, author)
    @books << book
  end

  def create_rental
    if @books.empty?
      puts 'No books available'
      return
    end
    puts 'Select a book from the following list:'
    @books.each_with_index do |book, index|
      puts "#{index}: #{book.title} by #{book.author}"
    end
    print 'Enter book index: '
    bi_input = gets.chomp.to_i
    if bi_input < 0 || bi_input >= @books.size
      puts 'Invalid book index'
      return
    end
    if @people.empty?
      puts 'No people available'
      return
    end
    puts 'Select a person from the following list:'
    @people.each_with_index do |person, index|
      puts "#{index}: [#{person.class}] Name: #{person.name}, ID: #{person.id}, Age: #{person.age}"
    end
    print 'Enter person index: '
    pi_input = gets.chomp.to_i
    if pi_input < 0 || pi_input >= @people.size
      puts 'Invalid person index'
      return
    end
    print 'Enter rental date (YYYY-MM-DD): '
    date = gets.chomp
    rental = Rental.new(date, @books[bi_input], @people[pi_input])
  end

  def list_rentals
    print 'ID of person: '
    pid = gets.chomp.to_i
    p_obj = @people.find { |person| person.id == pid }
    if p_obj
      p_obj.rentals.each do |rental|
        puts "#{rental.date} - #{rental.book.title}"
      end
    else
      puts 'Person not found'
    end
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, 'Subclasses must implement this method'
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
    @nameable.correct_name.slice(0, 10)
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
    @date = date
    @book = book
    @person = person
    @book.rentals << self unless @book.rentals.nil?
    @person.rentals << self unless @person.rentals.nil?
  end
end

class Book
  attr_accessor :title, :author, :rentals

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
    @id = Random.rand(1..1000)
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

  def of_age?
    @age >= 18
  end
end

class Student < Person
  attr_reader :classroom

  def initialize(age, classroom, name, parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @classroom = classroom
  end

  def classroom=(room)
    @classroom = room
    room.students << self unless room.students.include?(self)
  end

  def play_hooky
    '¯\\_(ツ)_/¯'
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