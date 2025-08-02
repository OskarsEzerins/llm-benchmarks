require 'date'

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

class Book
  attr_accessor :title, :author, :rentals

  def initialize(title, author)
    @title = title
    @author = author
    @rentals = []
  end

  def add_rental(date, person)
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
    return unless student

    @students << student unless @students.include?(student)
    student.classroom = self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals

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

  def initialize(age, classroom = nil, name = 'Unknown', parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom if classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    return unless room

    @classroom = room
    room.students << self unless room.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(name, specialization, age = 0)
    super(name, age, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
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

class App
  def initialize
    @books = []
    @people = []
  end

  def list_books
    if @books.empty?
      puts 'No books available'
    else
      @books.each { |b| puts "Title: #{b.title}, Author: #{b.author}" }
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
    else
      @people.each do |p|
        puts "[#{p.class}] ID: #{p.id}, Name: #{p.name}, Age: #{p.age}"
      end
    end
  end

  def create_person
    print 'Do you want to create a Student (1) or a Teacher (2)? [Input the number]: '
    choice = gets.chomp
    case choice
    when '1' then create_student
    when '2' then create_teacher
    else puts 'Invalid choice'
    end
  end

  def create_student
    print 'Name: '
    name = gets.chomp
    name = 'Unknown' if name.strip.empty?
    print 'Age: '
    age = gets.chomp.to_i
    print 'Parent permission? [Y/N]: '
    perm = gets.chomp.upcase
    until %w[Y N].include?(perm)
      print 'Please enter Y or N: '
      perm = gets.chomp.upcase
    end
    student = Student.new(age, nil, name, parent_permission: perm == 'Y')
    @people << student
    puts 'Person created successfully'
  end

  def create_teacher
    print 'Name: '
    name = gets.chomp
    name = 'Unknown' if name.strip.empty?
    print 'Age: '
    age = gets.chomp.to_i
    print 'Specialization: '
    spec = gets.chomp
    spec = 'Unknown' if spec.strip.empty?
    teacher = Teacher.new(name, spec, age)
    @people << teacher
    puts 'Person created successfully'
  end

  def create_book
    print 'Title: '
    title = gets.chomp
    title = 'Unknown' if title.strip.empty?
    print 'Author: '
    author = gets.chomp
    author = 'Unknown' if author.strip.empty?
    book = Book.new(title, author)
    @books << book
    puts 'Book created successfully'
  end

  def create_rental
    if @books.empty?
      puts 'No books available to rent'
      return
    end
    if @people.empty?
      puts 'No people available to rent'
      return
    end

    puts 'Select a book by number:'
    @books.each_with_index { |b, i| puts "#{i}) Title: #{b.title}, Author: #{b.author}" }
    bi = gets.chomp.to_i
    unless valid_index?(bi, @books)
      puts 'Invalid book selection'
      return
    end

    puts 'Select a person by number:'
    @people.each_with_index { |p, i| puts "#{i}) [#{p.class}] Name: #{p.name}, ID: #{p.id}, Age: #{p.age}" }
    pi = gets.chomp.to_i
    unless valid_index?(pi, @people)
      puts 'Invalid person selection'
      return
    end

    print 'Date (YYYY-MM-DD): '
    date = gets.chomp
    Rental.new(date, @books[bi], @people[pi])
    puts 'Rental created successfully'
  end

  def list_rentals
    print 'ID of person: '
    id = gets.chomp.to_i
    person = @people.detect { |p| p.id == id }
    if person.nil?
      puts 'Person not found'
    elsif person.rentals.empty?
      puts 'No rentals for this person'
    else
      person.rentals.each { |r| puts "#{r.date} - #{r.book.title} by #{r.book.author}" }
    end
  end

  private

  def valid_index?(index, array)
    index.is_a?(Integer) && index >= 0 && index < array.length
  end
end