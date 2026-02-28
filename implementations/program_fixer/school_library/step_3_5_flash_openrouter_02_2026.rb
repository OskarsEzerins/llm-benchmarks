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
    puts 'Select person type:'
    puts '1 - Teacher'
    puts '3 - Student'
    print 'Choice: '
    choice = gets.chomp

    case choice
    when '1'
      create_teacher
    when '3'
      create_student
    else
      puts 'Invalid choice'
    end
  end

  def create_student
    print 'Name: '
    name = gets.chomp
    print 'Age: '
    age = get_valid_age
    print 'Parent permission? (Y/N): '
    permission = get_valid_permission
    student = Student.new(age, nil, name, parent_permission: permission)
    @people << student
  end

  def create_teacher
    print 'Name: '
    name = gets.chomp
    print 'Age: '
    age = get_valid_age
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
    @books << Book.new(title, author)
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'No books or people available'
      return
    end

    puts 'Select a book:'
    @books.each_with_index { |book, i| puts "#{i}: #{book.title}" }
    book_index = gets.to_i
    puts 'Select a person:'
    @people.each_with_index { |person, i| puts "#{i}: #{person.name}" }
    person_index = gets.to_i

    if valid_indices?(person_index, book_index)
      Rental.new(Date.today, @books[book_index], @people[person_index])
    else
      puts 'Invalid selection'
    end
  end

  def list_rentals
    print 'ID of person: '
    id = gets.to_i
    person = @people.find { |p| p.id == id }
    if person
      person.rentals.each { |rental| puts "#{rental.date} - #{rental.book.title}" }
    else
      puts 'Person not found'
    end
  end

  private

  def get_valid_age
    loop do
      input = gets.chomp
      begin
        age = Integer(input)
        return age if age >= 0
        puts 'Age must be a positive number'
      rescue ArgumentError
        puts 'Please enter a valid integer for age'
      end
    end
  end

  def get_valid_permission
    loop do
      input = gets.chomp.upcase
      return true if input == 'Y'
      return false if input == 'N'
      puts 'Please enter Y or N'
    end
  end

  def valid_indices?(person_index, book_index)
    person_index >= 0 && person_index < @people.length &&
      book_index >= 0 && book_index < @books.length
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
end

class TrimmerDecorator < Decorator
  def correct_name
    super[0..9]
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    name = super
    name[0] = name[0].upcase if name[0]
    name
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
  attr_reader :title, :author, :rentals

  def initialize(title, author)
    @title = title
    @author = author
    @rentals = []
  end
end

class Classroom
  attr_reader :label, :students

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
  attr_reader :id, :name, :age, :rentals

  def initialize(name, age, parent_permission: true)
    @id = rand(1..1000)
    @name = name
    @age = age
    @parent_permission = parent_permission
    @rentals = []
  end

  def can_use_services?
    of_age? || (@parent_permission && !of_age?)
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
    @classroom = nil
    self.classroom = classroom if classroom
  end

  def classroom=(room)
    return if room == @classroom
    if @classroom
      @classroom.students.delete(self)
    end
    @classroom = room
    room.students << self unless room.students.include?(self)
  end

  def play_hooky
    '( ͡° ͜ʖ ͡°)'
  end
end

class Teacher < Person
  attr_reader :specialization

  def initialize(name, specialization, age)
    super(name, age)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end