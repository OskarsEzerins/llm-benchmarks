class App
  def initialize
    @books = []
    @people = []
    @classrooms = []
    @rentals = []
  end

  def list_books
    if @books.empty?
      puts 'No books available'
    else
      @books.each do |bk|
        puts "title: #{bk.title}, author: #{bk.author}"
      end
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
    else
      @people.each do |human|
        puts "[#{human.class}] id: #{human.id}, Name: #{human.name}, Age: #{human.age}"
      end
    end
  end

  def create_person
    print 'Enter 1 to create a Student or 2 to create a Teacher: '
    choice = gets.chomp
    case choice
    when '1'
      create_student
    when '2'
      create_teacher
    else
      puts 'Invalid selection. Try again.'
    end
  end

  def create_student
    name = prompt_for_name
    age = prompt_for_age
    parent_permission = prompt_for_parent_permission
    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
    puts 'Student created successfully'
  end

  def create_teacher
    name = prompt_for_name
    age = prompt_for_age
    print 'Specialization: '
    specialization = gets.chomp
    teacher = Teacher.new(name, specialization, age)
    @people << teacher
    puts 'Teacher created successfully'
  end

  def create_book
    print 'Title: '
    title = gets.chomp
    print 'Author: '
    author = gets.chomp
    book = Book.new(title, author)
    @books << book
    puts 'Book created successfully'
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'No books or people available to create a rental.'
      return
    end

    puts 'Select a book from the following list by number'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title} by #{b.author}" }
    book_index = gets.chomp.to_i
    if book_index < 0 || book_index >= @books.size
      puts 'Invalid book selection'
      return
    end

    puts 'Select a person from the following list by number (not id)'
    @people.each_with_index { |p, i| puts "#{i}: [#{p.class}] Name: #{p.name}, Id: #{p.id}, Age: #{p.age}" }
    person_index = gets.chomp.to_i
    if person_index < 0 || person_index >= @people.size
      puts 'Invalid person selection'
      return
    end

    print 'Date (YYYY-MM-DD): '
    date = gets.chomp
    rental = Rental.new(date, @books[book_index], @people[person_index])
    @rentals << rental
    puts 'Rental created successfully'
  end

  def list_rentals
    print 'ID of person: '
    pid = gets.chomp.to_i
    person = @people.find { |pr| pr.id == pid }
    if person.nil?
      puts 'No person with that ID.'
      return
    end
    if person.rentals.empty?
      puts 'No rentals found for this person.'
      return
    end
    person.rentals.each { |r| puts "#{r.date} - #{r.book.title} by #{r.book.author}" }
  end

  private

  def prompt_for_name
    name = ''
    loop do
      print 'Name: '
      name = gets.chomp
      break unless name.nil? || name.strip.empty?
      puts 'Name cannot be empty.'
    end
    name
  end

  def prompt_for_age
    age = nil
    loop do
      print 'Age: '
      input = gets.chomp
      if input =~ /^\d+$/
        age = input.to_i
        break if age >= 0
      end
      puts 'Invalid age. Please enter a non-negative integer.'
    end
    age
  end

  def prompt_for_parent_permission
    loop do
      print 'Has parent permission? [Y/N]: '
      input = gets.chomp.strip.upcase
      return true if input == 'Y'
      return false if input == 'N'
      puts 'Invalid input. Please enter Y or N.'
    end
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, 'correct_name must be implemented'
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

class Rental
  attr_accessor :date, :book, :person

  def initialize(date, book, person)
    @date = date
    @book = book
    @person = person
    book.rentals << self unless book.rentals.include?(self)
    person.rentals << self unless person.rentals.include?(self)
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

  def add_student(stud)
    @students << stud unless @students.include?(stud)
    stud.classroom = self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id = self.class.generate_id
    @name = name
    @age = age.to_i
    @parent_permission = !!parent_permission
    @rentals = []
  end

  def self.generate_id
    @current_id ||= 0
    @current_id += 1
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
    self.classroom = classroom unless classroom.nil?
  end

  def play_hooky
    '¯(ツ)/¯'
  end

  def classroom=(room)
    @classroom = room
    unless room.nil?
      room.students << self unless room.students.include?(self)
    end
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