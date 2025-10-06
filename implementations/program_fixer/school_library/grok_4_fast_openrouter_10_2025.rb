require 'date'

class App
  def initialize
    @books = []
    @people = []
  end

  def list_books
    if @books.empty?
      puts 'No books available'
      return
    end
    @books.each do |bk|
      puts "Title: #{bk.title}, Author: #{bk.author}"
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
      return
    end
    @people.each do |human|
      puts "[#{human.class}] Id: #{human.id}, Name: #{human.name}, Age: #{human.age}"
    end
  end

  def create_person
    print 'Do you want to create a student (1) or a teacher (2)? [Input the number]: '
    choice = gets.chomp
    case choice
    when '1'
      create_student
    when '2'
      create_teacher
    else
      puts 'Invalid choice'
    end
  end

  def create_student
    print 'Enter name: '
    name = gets.chomp
    print 'Enter age: '
    age_str = gets.chomp
    age = age_str.to_i
    age = 0 if age < 0
    print 'Has parent permission? [Y/N]: '
    permission = gets.chomp.upcase == 'Y'
    stu = Student.new(age, nil, name, parent_permission: permission)
    @people << stu
    puts 'Student created successfully'
  end

  def create_teacher
    print 'Enter name: '
    name = gets.chomp
    print 'Enter age: '
    age_str = gets.chomp
    age = age_str.to_i
    age = 0 if age < 0
    print 'Enter specialization: '
    spec = gets.chomp
    t = Teacher.new(age, spec, name)
    @people << t
    puts 'Teacher created successfully'
  end

  def create_book
    print 'Enter title: '
    title = gets.chomp
    print 'Enter author: '
    author = gets.chomp
    book = Book.new(title, author)
    @books << book
    puts 'Book created successfully'
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'Cannot create rental: No books or people available'
      return
    end
    puts 'Select a book from the following list by number'
    @books.each_with_index { |b, i| puts "#{i}) \"#{b.title}\" by #{b.author}" }
    book_index_str = gets.chomp
    book_index = book_index_str.to_i
    if !valid_index?(book_index, @books.length)
      puts 'Invalid book selection'
      return
    end
    puts 'Select a person from the following list by number (not id)'
    @people.each_with_index do |p, i|
      puts "#{i}) [#{p.class.name}] Name: #{p.name}, ID: #{p.id}, age: #{p.age}"
    end
    person_index_str = gets.chomp
    person_index = person_index_str.to_i
    if !valid_index?(person_index, @people.length)
      puts 'Invalid person selection'
      return
    end
    print 'Enter rental date (YYYY-MM-DD): '
    date = gets.chomp
    date = Date.today.strftime('%Y-%m-%d') if date.empty?
    Rental.new(date, @books[book_index], @people[person_index])
    puts 'Rental created successfully'
  end

  def list_rentals
    if @people.empty?
      puts 'No people available'
      return
    end
    print 'ID of person: '
    id_str = gets.chomp
    id = id_str.to_i
    p_obj = @people.find { |pr| pr.id == id }
    if p_obj.nil?
      puts 'Person with that ID not found'
      return
    end
    if p_obj.rentals.empty?
      puts 'No rentals for this person'
      return
    end
    puts 'Rentals:'
    p_obj.rentals.each { |r| puts "#{r.date} - #{r.book.title} by #{r.book.author}" }
  end

  private

  def valid_index?(index, length)
    index >= 0 && index < length
  end
end

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

  protected

  attr_reader :nameable
end

class TrimmerDecorator < Decorator
  def correct_name
    super()[0, 10]
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    super().capitalize
  end
end

class Rental
  attr_reader :date, :book, :person

  def initialize(date, book, person)
    @date = date
    @book = book
    @person = person
    @book.rentals << self
    @person.rentals << self
  end

  def to_s
    "Rental: #{@date} - #{@book.title} by #{@book.author} rented by #{@person.name}"
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

  def add_student(stud)
    @students << stud unless @students.include?(stud)
    stud.assign_classroom(self)
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals
  attr_reader :parent_permission

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id = rand(1..1000)
    @name = name
    @age = age
    @parent_permission = parent_permission
    @rentals = []
  end

  def correct_name
    @name
  end

  def can_use_services?
    of_age? || @parent_permission
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
    @classroom = classroom
    @classroom.add_student(self) if @classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def assign_classroom(classroom)
    @classroom = classroom
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