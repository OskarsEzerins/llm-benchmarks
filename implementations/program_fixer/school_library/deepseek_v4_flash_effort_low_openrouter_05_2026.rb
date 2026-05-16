class Nameable
  def correct_name
    raise NotImplementedError, 'Subclasses must implement correct_name'
  end
end

class Decorator < Nameable
  attr_accessor :nameable

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
  attr_accessor :id, :name, :age, :rentals, :parent_permission

  def initialize(age, name = 'Unknown', parent_permission: true)
    super()
    @id = rand(1000)
    @name = name.to_s.empty? ? 'Unknown' : name
    @age = age.to_i
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
    super(age, name, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom if classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    return if room.nil? || @classroom == room

    @classroom&.students&.delete(self)
    @classroom = room
    room.students << self unless room.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization = nil, name = 'Unknown')
    super(age, name)
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
      @books.each do |book|
        puts "title: #{book.title}, author: #{book.author}"
      end
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
    else
      @people.each do |person|
        puts "[#{person.class}] id: #{person.id}, Name: #{person.name}, Age: #{person.age}"
      end
    end
  end

  def create_person
    print 'Student(1) or Teacher(2)? [1/2]: '
    choice = gets.chomp.strip
    case choice
    when '1'
      create_student
    when '2'
      create_teacher
    else
      puts 'Invalid choice. Please enter 1 for Student or 2 for Teacher.'
    end
  end

  def create_student
    print 'Name: '
    name = gets.chomp.strip
    name = 'Unknown' if name.empty?
    print 'Age: '
    age = gets.chomp
    age = age.to_i
    if age <= 0
      puts 'Invalid age. Setting age to 0.'
      age = 0
    end
    print 'Parent permission? (Y/N): '
    perm = gets.chomp.strip.upcase
    parent_permission = perm == 'Y'
    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
    puts 'Student created successfully.'
  end

  def create_teacher
    print 'Name: '
    name = gets.chomp.strip
    name = 'Unknown' if name.empty?
    print 'Age: '
    age = gets.chomp
    age = age.to_i
    if age <= 0
      puts 'Invalid age. Setting age to 0.'
      age = 0
    end
    print 'Specialization: '
    specialization = gets.chomp.strip
    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    puts 'Teacher created successfully.'
  end

  def create_book
    print 'Title: '
    title = gets.chomp.strip
    title = 'Untitled' if title.empty?
    print 'Author: '
    author = gets.chomp.strip
    author = 'Unknown' if author.empty?
    book = Book.new(title, author)
    @books << book
    puts 'Book created successfully.'
  end

  def create_rental
    if @books.empty?
      puts 'No books available. Please create a book first.'
      return
    end
    if @people.empty?
      puts 'No people available. Please create a person first.'
      return
    end

    puts 'Select a book from the following list by number:'
    @books.each_with_index { |b, i| puts "#{i}) Title: #{b.title}, Author: #{b.author}" }
    print 'Book index: '
    book_index = gets.chomp.to_i
    unless book_index.between?(0, @books.length - 1)
      puts 'Invalid book index.'
      return
    end

    puts 'Select a person from the following list by number:'
    @people.each_with_index do |p, i|
      puts "#{i}) [#{p.class}] Name: #{p.name}, ID: #{p.id}"
    end
    print 'Person index: '
    person_index = gets.chomp.to_i
    unless person_index.between?(0, @people.length - 1)
      puts 'Invalid person index.'
      return
    end

    print 'Date (YYYY-MM-DD): '
    date = gets.chomp.strip
    date = Time.now.strftime('%Y-%m-%d') if date.empty?

    book = @books[book_index]
    person = @people[person_index]
    Rental.new(date, book, person)
    puts 'Rental created successfully.'
  end

  def list_rentals
    print 'ID of person: '
    person_id = gets.chomp.to_i
    person = @people.detect { |p| p.id == person_id }
    if person.nil?
      puts 'Person not found.'
      return
    end
    if person.rentals.empty?
      puts 'No rentals for this person.'
    else
      person.rentals.each do |rental|
        puts "Date: #{rental.date}, Book: #{rental.book.title} by #{rental.book.author}"
      end
    end
  end
end