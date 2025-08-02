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
    print 'Do you want to create a student (1) or a teacher (2)? [Input the number]: '
    choice = gets.chomp

    case choice
    when '1'
      create_student
    when '2'
      create_teacher
    else
      puts 'Invalid option. Please select 1 for student or 2 for teacher.'
    end
  end

  def create_student
    print 'Name: '
    name = gets.chomp
    print 'Age: '
    age_input = gets.chomp
    age = age_input.to_i

    if age_input != age.to_s || age < 0
      puts 'Invalid age. Please enter a valid positive integer.'
      return
    end

    print 'Has parent permission? [Y/N]: '
    permission_input = gets.chomp.upcase
    parent_permission = case permission_input
                        when 'Y'
                          true
                        when 'N'
                          false
                        else
                          puts 'Invalid input for parent permission. Assuming no permission.'
                          false
                        end

    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
    puts 'Student created successfully'
  end

  def create_teacher
    print 'Name: '
    name = gets.chomp
    print 'Age: '
    age_input = gets.chomp
    age = age_input.to_i

    if age_input != age.to_s || age < 0
      puts 'Invalid age. Please enter a valid positive integer.'
      return
    end

    print 'Specialization: '
    specialization = gets.chomp

    teacher = Teacher.new(age, specialization, name)
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
    return puts 'No books available' if @books.empty?
    return puts 'No people registered' if @people.empty?

    puts 'Select a book from the following list by number'
    @books.each_with_index { |book, index| puts "#{index}) #{book.title}, #{book.author}" }
    book_index = gets.chomp.to_i

    unless (0...@books.length).include?(book_index)
      puts 'Invalid book selection'
      return
    end

    puts 'Select a person from the following list by number (not ID)'
    @people.each_with_index { |person, index| puts "#{index}) [#{person.class}] #{person.name}" }
    person_index = gets.chomp.to_i

    unless (0...@people.length).include?(person_index)
      puts 'Invalid person selection'
      return
    end

    print 'Date (YYYY-MM-DD): '
    date = gets.chomp

    rental = Rental.new(date, @books[book_index], @people[person_index])
    puts 'Rental created successfully'
  end

  def list_rentals
    print 'ID of person: '
    id_input = gets.chomp
    person_id = id_input.to_i

    if id_input != person_id.to_s
      puts 'Invalid ID format'
      return
    end

    person = @people.find { |p| p.id == person_id }

    if person.nil?
      puts 'Person not found'
      return
    end

    if person.rentals.empty?
      puts 'No rentals found for this person'
      return
    end

    person.rentals.each do |rental|
      puts "Date: #{rental.date}, Book: \"#{rental.book.title}\" by #{rental.book.author}"
    end
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
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
    name = super
    name.length > 10 ? name[0..9] : name
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    name = super
    name.capitalize
  end
end

class Rental
  attr_accessor :date, :book, :person

  def initialize(date, book, person)
    @date = date

    @book = book
    book.rentals << self unless book.rentals.include?(self)

    @person = person
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

  def add_student(student)
    return if students.include?(student)
    students << student
    student.classroom = self
  end
end

class Person < Nameable
  attr_accessor :name, :age, :rentals
  attr_reader :id

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
  attr_accessor :classroom

  def initialize(age, classroom, name, parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    @classroom = classroom
  end

  def play_hooky
    '¯\(ツ)/¯'
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name = 'Unknown')
    super(age, name, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end