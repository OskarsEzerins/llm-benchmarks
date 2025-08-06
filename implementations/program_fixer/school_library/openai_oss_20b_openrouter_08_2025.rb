class App
  def initialize
    @books  = []
    @people = []
  end

  def list_books
    puts 'No books available' if @books.empty?
    @books.each do |bk|
      puts "Title: #{bk.title}, Author: #{bk.author}"
    end
  end

  def list_people
    puts 'No people registered' if @people.empty?
    @people.each do |human|
      puts "[#{human.class}] ID: #{human.id}, Name: #{human.name}, Age: #{human.age}"
    end
  end

  def create_person
    print 'Teacher(1) or Student(2)? '
    choice = gets.chomp
    case choice
    when '1'
      create_teacher
    when '2'
      create_student
    else
      puts 'Invalid choice'
    end
  end

  def create_student
    name = prompt_non_empty('Name: ')
    age  = prompt_positive_integer('Age: ')
    parent_permission = prompt_yes_no('Parent permission? (Y/N): ')
    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
    puts 'Student created'
  end

  def create_teacher
    name = prompt_non_empty('Name: ')
    age  = prompt_positive_integer('Age: ')
    spec = prompt_non_empty('Specialization: ')
    teacher = Teacher.new(name, spec, age)
    @people << teacher
    puts 'Teacher created'
  end

  def create_book
    title = prompt_non_empty('Title: ')
    author = prompt_non_empty('Author: ')
    book = Book.new(title, author)
    @books << book
    puts 'Book created'
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'No books or people available for rental'
      return
    end
    puts 'Select a book by number:'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title}" }
    book_index = prompt_integer_in_range('Book index: ', 0, @books.size - 1)
    puts 'Select a person by number:'
    @people.each_with_index { |p, i| puts "#{i}: #{p.name}" }
    person_index = prompt_integer_in_range('Person index: ', 0, @people.size - 1)
    Rental.new(Date.today, @people[person_index], @books[book_index])
    puts 'Rental created'
  end

  def list_rentals
    print 'ID of person: '
    pid = gets.chomp.to_i
    person = @people.find { |p| p.id == pid }
    if person
      if person.rentals.empty?
        puts 'No rentals for this person'
      else
        person.rentals.each do |r|
          puts "#{r.date} - #{r.book.title}"
        end
      end
    else
      puts 'Person not found'
    end
  end

  private

  def prompt_non_empty(message)
    loop do
      print message
      value = gets.chomp.strip
      return value unless value.empty?
      puts 'Value cannot be empty'
    end
  end

  def prompt_positive_integer(message)
    loop do
      print message
      value = gets.chomp
      if value.to_i.to_s == value && value.to_i >= 0
        return value.to_i
      else
        puts 'Please enter a valid non‑negative integer'
      end
    end
  end

  def prompt_integer_in_range(message, min, max)
    loop do
      print message
      value = gets.chomp
      if value.to_i.to_s == value
        int = value.to_i
        return int if int.between?(min, max)
      end
      puts "Please enter a number between #{min} and #{max}"
    end
  end

  def prompt_yes_no(message)
    loop do
      print message
      value = gets.chomp.downcase
      return true if value == 'y'
      return false if value == 'n'
      puts 'Please enter Y or N'
    end
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
    super[0..9]
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    super.capitalize
  end
end

class Rental
  attr_reader :date, :person, :book

  def initialize(date, person, book)
    @date   = date
    @person = person
    @book   = book
    @book.rentals << self
    @person.rentals << self
  end
end

class Book
  attr_reader :title, :author, :rentals

  def initialize(title, author)
    @title   = title
    @author  = author
    @rentals = []
  end

  def add_rental(person, date)
    Rental.new(date, person, self)
  end
end

class Classroom
  attr_accessor :label, :students

  def initialize(label)
    @label   = label
    @students = []
  end

  def add_student(stud)
    unless @students.include?(stud)
      @students << stud
      stud.classroom = self
    end
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals, :parent_permission

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id                = rand(1000..9999)
    @name              = name
    @age               = age
    @parent_permission = parent_permission
    @rentals           = []
  end

  def can_use_services?
    of_age? && @parent_permission
  end

  def correct_name
    @name
  end

  def add_rental(book, date)
    Rental.new(date, self, book)
  end

  private

  def of_age?
    @age >= 18
  end
end

class Student < Person
  attr_accessor :classroom

  def initialize(age, classroom, name, parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom if classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    return if room.nil?
    @classroom = room
    room.add_student(self) unless room.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(name, specialization, age = 0)
    super(name, age)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end