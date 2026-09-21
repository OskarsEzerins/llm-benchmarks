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
      puts "[#{human.class}] ID: #{human.id}, Name: #{human.name}, Age: #{human.age}"
    end
  end

  def create_person
    print 'Student (1) or Teacher (2)? '
    choice = gets.to_s.chomp
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
    name = gets.to_s.chomp
    name = 'Unknown' if name.nil? || name.strip.empty?
    age = read_age
    print 'Parent permission? [Y/N]: '
    perm = gets.to_s.chomp
    perm = 'N' unless %w[Y y N n].include?(perm)
    parent_permission = perm.downcase == 'y'
    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
    puts 'Student created'
    student
  end

  def create_teacher
    print 'Name: '
    name = gets.to_s.chomp
    name = 'Unknown' if name.nil? || name.strip.empty?
    age = read_age
    print 'Specialization: '
    spec = gets.to_s.chomp
    teacher = Teacher.new(name, spec, age)
    @people << teacher
    puts 'Teacher created'
    teacher
  end

  def create_book
    print 'Title: '
    title = gets.to_s.chomp
    print 'Author: '
    author = gets.to_s.chomp
    book = Book.new(title, author)
    @books << book
    puts 'Book created'
    book
  end

  def create_rental
    return if @books.empty? || @people.empty?
    puts 'Select a book'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title}" }
    book_index = gets.to_s.chomp.to_i
    puts 'Select a person'
    @people.each_with_index { |p, i| puts "#{i}: #{p.name} (ID: #{p.id})" }
    person_index = gets.to_s.chomp.to_i
    unless valid_indices?(person_index, book_index)
      puts 'Invalid indices'
      return
    end
    print 'Date [YYYY-MM-DD]: '
    date_input = gets.to_s.chomp
    date = Date.parse(date_input) rescue Date.today
    rental = Rental.new(date, @books[book_index], @people[person_index])
    puts 'Rental created'
    rental
  end

  def list_rentals
    print 'ID of person: '
    pid = gets.to_s.chomp.to_i
    person = @people.detect { |p| p.id == pid }
    if person.nil?
      puts 'Person not found'
      return
    end
    person.rentals.each { |r| puts "#{r.date} - Book: '#{r.book.title}' by #{r.book.author}" }
  end

  private

  def read_age
    print 'Age: '
    age = gets.to_s.chomp.to_i
    age = 0 if age.negative?
    age
  end

  def valid_indices?(person_index, book_index)
    person_index.between?(0, @people.length - 1) && book_index.between?(0, @books.length - 1)
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, "#{self.class} has not implemented correct_name"
  end
end

class Decorator < Nameable
  attr_reader :nameable

  def initialize(nameable)
    super()
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
    @nameable.correct_name.capitalize
  end
end

class Rental
  attr_reader :date, :book, :person

  def initialize(date, book, person)
    @date = date
    @book = book
    @person = person
    book.rentals << self unless book.rentals.include?(self)
    person.rentals << self unless person.rentals.include?(self)
  end
end

class Book
  attr_reader :rentals
  attr_accessor :title, :author

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
  attr_accessor :name, :age
  attr_reader :id, :rentals

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    super()
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
    @classroom = classroom
    classroom&.add_student(self)
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

  def initialize(name, specialization, age = 0)
    super(name, age, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end