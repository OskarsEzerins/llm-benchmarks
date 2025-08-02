class App
  def initialize
    @books = []
    @people = {}
  end

  def list_books
    puts 'No books available' if @books.empty?
    @books.each do |book|
      puts "Title: #{book.title}, Author: #{book.author}"
    end
  end

  def list_people
    puts 'No one has registered' if @people.empty?
    @people.each do |id, person|
      puts "[#{person.class}] ID: #{id}, Name: #{person.correct_name}, Age: #{person.age}"
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
    parent_permission = gets.chomp.upcase == 'Y'
    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people[student.id] = student
  end

  def create_teacher
    print 'Name: '
    name = gets.chomp
    print 'Age: '
    age = gets.chomp.to_i
    print 'Specialization: '
    specialization = gets.chomp
    teacher = Teacher.new(name, specialization, age)
    @people[teacher.id] = teacher
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
    puts 'Select a book'
    @books.each_with_index { |book, i| puts "#{i}: #{book.title}" }
    book_index = gets.chomp.to_i
    puts 'Select a person'
    @people.each { |id, person| puts "#{id}: #{person.correct_name}" }
    person_id = gets.chomp.to_i
    person = @people[person_id]
    book = @books[book_index]
    Rental.new(Date.today, person, book)
  end

  def list_rentals
    print 'ID of person: '
    person_id = gets.chomp.to_i
    person = @people[person_id]
    person.rentals.each { |rental| puts "#{rental.date} - #{rental.book.title}" }
  end

  private

  def valid_indices?(person_index, book_index)
    person_index >= 0 && person_index < @people.size && book_index >= 0 && book_index < @books.size
  end
end

class Nameable
  attr_accessor :name

  def initialize(name)
    @name = name
  end

  def correct_name
    name
  end
end

class Decorator < Nameable
  def initialize(nameable)
    super(nameable.name)
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
    super.upcase
  end
end

class Rental
  attr_reader :date, :book, :person

  def initialize(date, person, book)
    @date = date
    @book = book
    @person = person
    book.rentals << self
    person.rentals << self
  end
end

class Book
  attr_reader :title, :author
  attr_accessor :rentals

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
    students << student unless students.include?(student)
  end
end

class Person < Nameable
  attr_accessor :id, :age, :rentals, :parent_permission

  def initialize(name, age, parent_permission: true)
    super(name)
    @id = rand(1000..9999)
    @age = age
    @parent_permission = parent_permission
    @rentals = []
  end

  def can_use_services?
    age >= 18 || (age < 18 && parent_permission)
  end
end

class Student < Person
  attr_accessor :classroom

  def initialize(age, classroom, name, parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @classroom = classroom
  end

  def assign_classroom(classroom)
    @classroom = classroom
    classroom.add_student(self) unless classroom.students.include?(self)
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