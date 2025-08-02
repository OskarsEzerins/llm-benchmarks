class App
  def initialize
    @books = []
    @people = {}
  end

  def list_books
    puts 'No books available' if @books.empty?
    @books.each { |book| puts "Title: #{book.title}, Author: #{book.author}" }
  end

  def list_people
    puts 'No one has registered' if @people.empty?
    @people.each_value do |person|
      puts "[#{person.class}] ID: #{person.id}, Name: #{person.correct_name}, Age: #{person.age}"
    end
  end

  def create_person
    print 'Do you want to create a student (1) or a teacher (2)? '
    choice = gets.chomp
    create_student if choice == '1'
    create_teacher if choice == '2'
  end

  def create_student
    print 'Name: '
    name = gets.chomp
    print 'Age: '
    age = gets.to_i
    print 'Has parent permission? (Y/N) '
    permission = gets.chomp.upcase == 'Y'
    student = Student.new(age, nil, name, parent_permission: permission)
    @people[student.id] = student
  end

  def create_teacher
    print 'Name: '
    name = gets.chomp
    print 'Age: '
    age = gets.to_i
    print 'Specialization: '
    specialization = gets.chomp
    teacher = Teacher.new(age, specialization, name)
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
    puts 'Select a book by index:'
    @books.each_with_index { |book, index| puts "#{index}: #{book.title}" }
    book_index = gets.to_i
    puts 'Select a person by index:'
    @people.each_value.with_index { |person, index| puts "#{index}: #{person.name}" }
    person_index = gets.to_i
    date = Date.today
    rental = Rental.new(date, @books[book_index], @people.values[person_index])
    @books[book_index].rentals << rental
    @people.values[person_index].rentals << rental
  end

  def list_rentals
    print 'ID of person: '
    person_id = gets.to_i
    person = @people[person_id]
    person.rentals.each { |rental| puts "Date: #{rental.date}, Book: #{rental.book.title}" }
  end

  private

  def valid_indices?(person_index, book_index)
    person_index < @people.length && book_index < @books.length
  end
end

class Nameable
  def correct_name
    ''
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
    @nameable.correct_name[0..9]
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
    @students << student
    student.classroom = self
  end
end

class Person < Nameable
  attr_reader :id, :age
  attr_accessor :name, :rentals

  def initialize(name, age, parent_permission: true)
    super()
    @id = rand(1..1000)
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
    classroom.add_student(self) unless classroom.nil?
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(classroom)
    @classroom = classroom
    classroom.add_student(self) unless classroom.students.include?(self)
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