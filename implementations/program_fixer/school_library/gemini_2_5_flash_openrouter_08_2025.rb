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
        puts "[#{human.class.name}] ID: #{human.id}, Name: #{human.name}, Age: #{human.age}"
      end
    end
  end

  def create_person
    print 'Do you want to create a student (1) or a teacher (2)? [Input the number]: '
    choice = gets.chomp
    case choice
    when '1'
      create_student
    when '2'
      create_teacher
    else
      puts 'Invalid choice. Please enter 1 or 2.'
    end
  end

  def create_student
    print 'Age: '
    age_input = gets.chomp
    age = age_input.to_i
    if age <= 0
      puts 'Invalid age. Age must be a positive integer.'
      return
    end

    print 'Name: '
    name = gets.chomp
    if name.empty?
      puts 'Name cannot be empty.'
      return
    end

    print 'Has parent permission? [Y/N]: '
    perm_input = gets.chomp.upcase
    parent_permission = false
    case perm_input
    when 'Y'
      parent_permission = true
    when 'N'
      parent_permission = false
    else
      puts 'Invalid input for parent permission. Assuming No.'
    end

    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
    puts "Student '#{name}' created successfully."
  end

  def create_teacher
    print 'Age: '
    age_input = gets.chomp
    age = age_input.to_i
    if age <= 0
      puts 'Invalid age. Age must be a positive integer.'
      return
    end

    print 'Name: '
    name = gets.chomp
    if name.empty?
      puts 'Name cannot be empty.'
      return
    end

    print 'Specialization: '
    specialization = gets.chomp

    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    puts "Teacher '#{name}' created successfully."
  end

  def create_book
    print 'Title: '
    title = gets.chomp
    if title.empty?
      puts 'Title cannot be empty.'
      return
    end

    print 'Author: '
    author = gets.chomp
    if author.empty?
      puts 'Author cannot be empty.'
      return
    end

    book = Book.new(title, author)
    @books << book
    puts "Book '#{title}' by #{author} created successfully."
  end

  def create_rental
    if @books.empty?
      puts 'No books available to rent.'
      return
    end
    puts 'Select a book from the following list by number:'
    @books.each_with_index { |b, i| puts "#{i}) Title: \"#{b.title}\", Author: #{b.author}" }
    book_index_input = gets.chomp
    book_index = book_index_input.to_i

    if book_index < 0 || book_index >= @books.length
      puts 'Invalid book selection.'
      return
    end

    if @people.empty?
      puts 'No people registered to rent books.'
      return
    end
    puts 'Select a person from the following list by number (not id):'
    @people.each_with_index { |p, i| puts "#{i}) [#{p.class.name}] Name: #{p.name}, ID: #{p.id}, Age: #{p.age}" }
    person_index_input = gets.chomp
    person_index = person_index_input.to_i

    if person_index < 0 || person_index >= @people.length
      puts 'Invalid person selection.'
      return
    end

    book = @books[book_index]
    person = @people[person_index]

    rental = Rental.new(Date.today.to_s, book, person)
    puts 'Rental created successfully.'
  end

  def list_rentals
    print 'ID of person: '
    person_id_input = gets.chomp
    person_id = person_id_input.to_i

    person_obj = @people.find { |pr| pr.id == person_id }

    if person_obj.nil?
      puts "No person found with ID: #{person_id}"
      return
    end

    if person_obj.rentals.empty?
      puts "No rentals found for person ID: #{person_id}"
      return
    end

    puts 'Rentals:'
    person_obj.rentals.each do |r|
      puts "Date: #{r.date}, Book: \"#{r.book.title}\" by #{r.book.author}"
    end
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end
end

class Decorator < Nameable
  def initialize(nameable)
    super()
    @nameable = nameable
  end

  def correct_name
    @nameable.correct_name
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    super.capitalize
  end
end

class TrimmerDecorator < Decorator
  def correct_name
    name = super
    name.length > 10 ? name[0..9] : name
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
  attr_accessor :label
  attr_reader :students

  def initialize(label)
    @label = label
    @students = []
  end

  def add_student(student)
    @students << student
    student.classroom = self # set the classroom for the student
  end
end

class Person < Nameable
  attr_reader :id
  attr_accessor :name, :age, :rentals

  def initialize(age, name = 'Unknown', parent_permission: true)
    super()
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

  def initialize(age, classroom, name = 'Unknown', parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    @classroom = classroom # Initialize, not assign directly with setter
  end

  def classroom=(classroom)
    @classroom = classroom
    classroom.add_student(self) unless classroom.students.include?(self)
  end

  def play_hooky
    '¯\(ツ)/¯'
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name = 'Unknown')
    super(age, name, parent_permission: true) # Teachers always have permission
    @specialization = specialization
  end

  def can_use_services?
    true # Teachers can always use services
  end
end