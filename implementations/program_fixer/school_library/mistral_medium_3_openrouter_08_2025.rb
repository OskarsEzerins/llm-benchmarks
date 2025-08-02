class App
  def initialize
    @books = []
    @people = []
  end

  def list_books
    puts 'No books available' if @books.empty?
    @books.each do |bk|
      puts "Title: #{bk.title}, Author: #{bk.author}"
    end
  end

  def list_people
    puts 'No one has registered' if @people.empty?
    @people.each do |human|
      puts "[#{human.class}] ID: #{human.id}, Name: #{human.name}, Age: #{human.age}"
    end
  end

  def create_person
    print 'Student (1) or Teacher (2)? '
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
    print 'Age: '
    age = gets.chomp.to_i
    print 'Parent permission? (Y/N) '
    permission = gets.chomp.upcase == 'Y'
    student = Student.new(age, nil, name, parent_permission: permission)
    @people << student
    puts 'Student created successfully'
  end

  def create_teacher
    print 'Name: '
    name = gets.chomp
    print 'Age: '
    age = gets.chomp.to_i
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
    puts 'Select a book by number:'
    @books.each_with_index { |b, i| puts "#{i}) Title: #{b.title}, Author: #{b.author}" }
    book_index = gets.chomp.to_i

    puts 'Select a person by number:'
    @people.each_with_index { |p, i| puts "#{i}) Name: #{p.name}, ID: #{p.id}" }
    person_index = gets.chomp.to_i

    if valid_indices?(person_index, book_index)
      rental = Rental.new(Date.today, @books[book_index], @people[person_index])
      puts 'Rental created successfully'
    else
      puts 'Invalid selection'
    end
  end

  def list_rentals
    print 'ID of person: '
    id = gets.chomp.to_i
    person = @people.find { |p| p.id == id }
    if person
      puts "Rentals for #{person.name}:"
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
    raise NotImplementedError, 'You must implement the correct_name method'
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
    name = @nameable.correct_name
    name.length > 10 ? name[0..9] : name
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
    @book.rentals << self
    @person.rentals << self
  end
end

class Book
  attr_accessor :title, :author, :rentals

  def initialize(title, author)
    @title = title
    @author = author
    @rentals = []
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
  attr_accessor :id, :name, :age, :parent_permission, :rentals

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id = rand(1000..9999)
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

  private

  def of_age?
    @age >= 18
  end
end

class Student < Person
  attr_accessor :classroom

  def initialize(age, classroom, name, parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @classroom = classroom
  end

  def play_hooky
    '╰(°▽°)╯'
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