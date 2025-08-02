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
        puts "Title: #{bk.title}, Author: #{bk.author}"
      end
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
    else
      @people.each do |person|
        puts "[#{person.class}] ID: #{person.id}, Name: #{person.correct_name}, Age: #{person.age}"
      end
    end
  end

  def create_person
    print 'Student (1) or Teacher (2)? '
    choice = gets.chomp
    case choice
    when '1'
      create_student
    when '2'
      create_teacher
    else
      puts "Invalid choice"
    end
  end

  def create_student
    print 'Name: '
    name = gets.chomp
    print 'Age: '
    age = gets.to_i
    print 'Parent permission? (Y/N) '
    perm = gets.chomp
    parent_permission = perm.upcase == 'Y'
    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
  end

  def create_teacher
    print 'Name: '
    name = gets.chomp
    print 'Age: '
    age = gets.to_i
    print 'Specialization: '
    spec = gets.chomp
    teacher = Teacher.new(age, spec, name)
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
    puts 'Select a book by number:'
    @books.each_with_index { |book, index| puts "#{index}: #{book.title}" }
    book_index = gets.to_i
    puts 'Select a person by number:'
    @people.each_with_index { |person, index| puts "#{index}: #{person.correct_name}" }
    person_index = gets.to_i
    if valid_indices?(person_index, book_index)
      date = Date.today.to_s
      Rental.new(date, @books[book_index], @people[person_index])
    else
      puts "Invalid selection."
    end
  end

  def list_rentals
    print 'ID of person: '
    person_id = gets.to_i
    person = @people.find { |p| p.id == person_id }
    if person && person.rentals.any?
      person.rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
    else
      puts "No rentals found for this ID."
    end
  end

  private

  def valid_indices?(person_index, book_index)
    person_index >= 0 && person_index < @people.length && book_index >= 0 && book_index < @books.length
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, 'You must implement the correct_name method'
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
    @nameable.correct_name.capitalize
  end
end

class Rental
  attr_accessor :date, :book, :person

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
  attr_accessor :id, :name, :age, :rentals

  def initialize(age, name, parent_permission: true)
    @id = rand(1000)
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
  attr_accessor :classroom

  def initialize(age, classroom, name, parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    @classroom = classroom
  end

  def play_hooky
    '¯\\_(ツ)_/¯'
  end

  def classroom=(room)
    @classroom = room
    room.students << self unless room.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name)
    super(age, name, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end