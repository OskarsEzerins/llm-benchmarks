require 'date'

class Nameable
  def correct_name
    raise NotImplementedError
  end
end

class Decorator
  attr_accessor :nameable

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

class Book
  attr_reader :title, :author
  attr_accessor :rentals

  def initialize(title, author)
    @title = title
    @author = author
    @rentals = []
  end

  def add_rental(person, date)
    Rental.new(date, self, person)
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
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals, :parent_permission

  def initialize(age, name = 'Unknown', parent_permission = false)
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
  attr_accessor :classroom

  def initialize(age, classroom, name, parent_permission = false)
    super(age, name, parent_permission)
    @classroom = classroom
    classroom.add_student(self) unless classroom.nil?
  end

  def play_hooky
    '╰(°▽°)╯'
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name)
    super(age, name, true)
    @specialization = specialization
  end

  def can_use_services?
    true
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

class App
  def initialize
    @books = []
    @people = []
  end

  def list_books
    if @books.empty?
      puts 'No books available!'
      return
    end
    @books.each do |book|
      puts "Title: \"#{book.title}\", Author: #{book.author}"
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
      return
    end
    @people.each do |person|
      puts "[#{person.class}] ID: #{person.id}, Name: #{person.name}, Age: #{person.age}"
    end
  end

  def create_person
    print 'Student(1) or Teacher(2)? [Input the number]: '
    choice = gets.chomp
    case choice
    when '1'
      create_student
    when '2'
      create_teacher
    else
      puts 'Invalid selection'
    end
  end

  def create_student
    print 'Name: '
    name = gets.chomp
    name = 'Unknown' if name.empty?
    print 'Age: '
    age_input = gets.chomp
    age = age_input.to_i
    age = 0 if age < 0
    print 'Parent permission? [Y/N]: '
    perm_input = gets.chomp.downcase
    parent_permission = %w[y yes].include?(perm_input)
    student = Student.new(age, nil, name, parent_permission)
    @people << student
    puts 'Student created successfully'
  end

  def create_teacher
    print 'Name: '
    name = gets.chomp
    name = 'Unknown' if name.empty?
    print 'Age: '
    age_input = gets.chomp
    age = age_input.to_i
    age = 0 if age < 0
    print 'Specialization: '
    specialization = gets.chomp
    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    puts 'Teacher created successfully'
  end

  def create_book
    print 'Title: '
    title = gets.chomp
    print 'Author: '
    author = gets.chomp
    author = 'Unknown' if author.empty?
    @books << Book.new(title, author)
    puts 'Book created successfully'
  end

  def create_rental
    return puts 'No books available!' if @books.empty?
    return puts 'No people available!' if @people.empty?

    puts 'Select a book from the following list by number'
    @books.each_with_index { |book, index| puts "#{index}) \"#{book.title}\" by #{book.author}" }
    print '> '
    book_index = gets.chomp.to_i

    puts 'Select a person from the following list by number (not id)'
    @people.each_with_index { |person, index| puts "#{index}) #{person.name} (#{person.class})" }
    print '> '
    person_index = gets.chomp.to_i

    if valid_indices?(book_index, person_index)
      print 'Date (YYYY-MM-DD): '
      rental_date = gets.chomp
      Rental.new(rental_date, @books[book_index], @people[person_index])
      puts 'Rental created successfully'
    else
      puts 'Invalid selection'
    end
  end

  def list_rentals
    print 'ID of person: '
    id_input = gets.chomp.to_i
    person = @people.find { |p| p.id == id_input }
    if person.nil?
      puts 'No person found with that ID'
      return
    end
    if person.rentals.empty?
      puts 'No rentals found for this person'
      return
    end
    puts 'Rentals:'
    person.rentals.each do |rental|
      puts "#{rental.date} - #{rental.book.title} (#{rental.person.name})"
    end
  end

  private

  def valid_indices?(book_index, person_index)
    book_index >= 0 && book_index < @books.length &&
      person_index >= 0 && person_index < @people.length
  end
end