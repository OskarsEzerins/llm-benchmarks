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
        puts "Title: #{bk.title}, Author: #{bk.author}"
      end
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
    else
      @people.each do |human|
        puts "[#{human.class}] ID: #{human.id}, Name: #{human.name}, Age: #{human.age}"
      end
    end
  end

  def create_person
    print 'Create a Student (1) or a Teacher (2)? '
    choice = gets&.chomp

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
    name = gets&.chomp
    name = 'Unknown' if name.nil? || name.strip.empty?

    print 'Age: '
    age = gets.to_i
    age = 0 if age.negative?

    print 'Parent permission? [Y/N]: '
    perm = gets&.chomp&.upcase
    parent_permission = perm == 'Y'

    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
  end

  def create_teacher
    print 'Name: '
    name = gets&.chomp
    name = 'Unknown' if name.nil? || name.strip.empty?

    print 'Age: '
    age = gets.to_i
    age = 0 if age.negative?

    print 'Specialization: '
    specialization = gets&.chomp

    teacher = Teacher.new(age, specialization, name)
    @people << teacher
  end

  def create_book
    print 'Title: '
    title = gets&.chomp
    print 'Author: '
    author = gets&.chomp
    @books << Book.new(title, author)
  end

  def create_rental
    return puts('No books or people available') if @books.empty? || @people.empty?

    puts 'Select a book by number'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title}" }
    book_index = gets.to_i

    puts 'Select a person by number'
    @people.each_with_index { |p, i| puts "#{i}: #{p.name}" }
    person_index = gets.to_i

    unless valid_indices?(person_index, book_index)
      puts 'Invalid selection'
      return
    end

    Rental.new(Date.today.to_s, @books[book_index], @people[person_index])
    puts 'Rental created successfully'
  end

  def list_rentals
    print 'ID of person: '
    pid = gets.to_i
    person = @people.find { |p| p.id == pid }

    if person.nil?
      puts 'Person not found'
    else
      person.rentals.each do |r|
        puts "#{r.date} - #{r.book.title}"
      end
    end
  end

  private

  def valid_indices?(p_i, b_i)
    p_i.between?(0, @people.length - 1) && b_i.between?(0, @books.length - 1)
  end
end

class Nameable
  def correct_name
    raise NotImplementedError
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
    super[0, 10]
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
    @students << student unless @students.include?(student)
    student.classroom = self
  end
end

class Person < Nameable
  attr_accessor :name, :age, :rentals
  attr_reader :id

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id = rand(1..1000)
    @name = name
    @age = age.to_i
    @parent_permission = parent_permission == true
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
    self.classroom = classroom if classroom
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

  def initialize(age, specialization, name)
    super(name, age, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end