class App
  def initialize
    @books = []
    @people = []
  end

  def list_books
    puts 'No books available' if @books&.empty?
    @books.each do |bk|
      puts "title: #{bk.title}, author: #{bk.author}"
    end
  end

  def list_people
    puts 'No one has registered' unless @people.any?
    @people.each do |human|
      puts "[#{human.class}] id: #{human.id}, Name: #{human.name}, Age: #{human.age}"
    end
  end

  def create_person
    print 'Student(1) or Teacher(2)? '
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
    print 'Age: '
    age = gets.chomp.to_i
    print 'Parent permission? (Y/N): '
    perm = gets.chomp.upcase
    student = Student.new(age, nil, name, parent_permission: perm == 'Y')
    @people << student
  end

  def create_teacher
    print 'Name: '
    name = gets.chomp
    print 'Age: '
    age = gets.chomp.to_i
    print 'Specialization: '
    spec = gets.chomp
    teacher = Teacher.new(age, spec, name)
    @people.push(teacher)
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
    puts 'Select a book'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title}" }
    book_index = gets.chomp.to_i
    puts 'Select person'
    @people.each_with_index { |p, i| puts "#{i}: #{p.name}" }
    person_index = gets.chomp.to_i
    
    return unless valid_indices?(person_index, book_index)
    
    Rental.new('2023-01-01', @books[book_index], @people[person_index])
  end

  def list_rentals
    print 'ID of person: '
    pid = gets.chomp.to_i
    person = @people.detect { |p| p.id == pid }
    if person
      person.rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
    else
      puts 'Person not found'
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
    raise NotImplementedError, 'Must implement correct_name'
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
    @students << student
    student.classroom = self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals
  
  def initialize(age, name = 'Unknown', parent_permission: true)
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
  attr_reader :classroom
  
  def initialize(age, classroom, name, parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    @classroom = classroom
    classroom&.add_student(self)
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    @classroom = room
    room&.add_student(self)
  end
end

class Teacher < Person
  attr_accessor :specialization
  
  def initialize(age, specialization, name = 'Unknown')
    super(age, name)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end