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

    @books.each do |book|
      puts "title: #{book.title}, author: #{book.author}"
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
      return
    end

    @people.each do |person|
      puts "[#{person.class}] id: #{person.id}, Name: #{person.name}, Age: #{person.age}"
    end
  end

  def create_person
    print 'Student(3) or Teacher(1)? '
    choice = gets&.chomp

    case choice
    when '1'
      create_teacher
    when '3'
      create_student
    else
      puts 'Invalid option'
    end
  end

  def create_student
    print 'Name: '
    name = gets&.chomp
    name = 'Unknown' if name.nil? || name.empty?

    print 'Age: '
    age = gets&.chomp.to_i
    age = 0 if age.negative?

    print 'Parent permission? (Y/N): '
    permission = gets&.chomp&.upcase
    parent_permission = permission == 'Y'

    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
  end

  def create_teacher
    print 'Name: '
    name = gets&.chomp
    name = 'Unknown' if name.nil? || name.empty?

    print 'Age: '
    age = gets&.chomp.to_i
    age = 0 if age.negative?

    print 'Specialization: '
    specialization = gets&.chomp
    specialization = 'General' if specialization.nil? || specialization.empty?

    teacher = Teacher.new(age, specialization, name)
    @people << teacher
  end

  def create_book
    print 'Title: '
    title = gets&.chomp
    title = 'Unknown' if title.nil? || title.empty?

    print 'Author: '
    author = gets&.chomp
    author = 'Unknown' if author.nil? || author.empty?

    @books << Book.new(title, author)
  end

  def create_rental
    if @books.empty?
      puts 'No books available'
      return
    end

    if @people.empty?
      puts 'No people registered'
      return
    end

    puts 'Select a book'
    @books.each_with_index { |book, index| puts "#{index}: #{book.title}" }
    print 'Book index: '
    book_index = gets&.chomp.to_i

    puts 'Select person'
    @people.each_with_index { |person, index| puts "#{index}: #{person.name}" }
    print 'Person index: '
    person_index = gets&.chomp.to_i

    if valid_indices?(person_index, book_index)
      Rental.new(Date.today, @books[book_index], @people[person_index])
    else
      puts 'Invalid selection'
    end
  end

  def list_rentals
    print 'ID of person: '
    person_id = gets&.chomp.to_i
    person = @people.find { |p| p.id == person_id }

    if person.nil?
      puts 'Person not found'
      return
    end

    person.rentals.each do |rental|
      puts "#{rental.date} - #{rental.book.title}"
    end
  end

  private

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
    name = super
    name.length > 10 ? name[0, 10] : name
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

  def add_student(student)
    student.classroom = self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals

  @@id_counter = 0

  def self.next_id
    @@id_counter += 1
  end

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id = self.class.next_id
    @name = name.to_s
    @name = 'Unknown' if @name.empty?
    @age = age.to_i
    @parent_permission = !!parent_permission
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
    self.classroom = classroom if classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    @classroom = room
    return if room.nil?

    room.students << self unless room.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name = 'Unknown')
    super(name, age)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end