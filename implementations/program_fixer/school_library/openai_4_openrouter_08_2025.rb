class App
  attr_accessor :books, :people

  def initialize
    @books = []
    @people = []
  end

  def list_books
    if @books.empty?
      puts 'No books available'
    else
      @books.each { |book| puts "Title: #{book.title}, Author: #{book.author}" }
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
    else
      @people.each { |person| puts "[#{person.class}] ID: #{person.id}, Name: #{person.name}, Age: #{person.age}" }
    end
  end

  def create_person
    print 'Student(1) or Teacher(2)? '
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
    print 'Name: '
    name = gets.chomp
    print 'Age: '
    age = gets.chomp.to_i
    print 'Parent permission (Y/N)? '
    permission = gets.chomp.downcase
    permission = permission == 'y' ? true : false
    student = Student.new(name, age, parent_permission: permission)
    @people << student
  end

  def create_teacher
    print 'Name: '
    name = gets.chomp
    print 'Age: '
    age = gets.chomp.to_i
    print 'Specialization: '
    specialization = gets.chomp
    teacher = Teacher.new(name, age, specialization)
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
    puts 'Select a book by index'
    @books.each_with_index { |book, index| puts "#{index}: #{book.title}" }
    book_index = gets.chomp.to_i
    puts 'Select person by index'
    @people.each_with_index { |person, index| puts "#{index}: #{person.name}" }
    person_index = gets.chomp.to_i
    print 'Date (YYYY-MM-DD): '
    date = gets.chomp
    Rental.new(date, @people[person_index], @books[book_index])
  end

  def list_rentals
    print 'ID of person: '
    id = gets.chomp.to_i
    person = @people.find { |person| person.id == id }
    person.rentals.each { |rental| puts "#{rental.date} - #{rental.book.title}" }
  end
end


class Nameable
  def correct_name
    @name
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
  attr_accessor :date, :book, :person

  def initialize(date, person, book)
    @date   = date
    @book   = book
    @person = person
    book.rentals << self
    person.rentals << self
  end
end

class Book
  attr_accessor :title, :author, :rentals

  def initialize(title, author)
    @title   = title
    @author  = author
    @rentals = []
  end
end

class Classroom
  attr_accessor :label, :students

  def initialize(label)
    @label   = label
    @students = []
  end

  def add_student(student)
    students << student
    student.classroom = self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals, :parent_permission

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id = rand(1000)
    @name = name
    @age = age
    @parent_permission = parent_permission
    @rentals = []
  end

  def can_use_services?
    @parent_permission || of_age?
  end

  def add_rental(book, date)
    Rental.new(date, self, book)
  end

  private

  def of_age?
    @age >= 18
  end
end

class Student < Person
  attr_accessor :classroom

  def initialize(name, age, parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @classroom = nil
  end

  def classroom=(classroom)
    @classroom = classroom
    classroom.students << self unless classroom.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(name, age, specialization)
    super(name, age)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end