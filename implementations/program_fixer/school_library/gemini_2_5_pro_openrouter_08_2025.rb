require 'date'

class App
  def initialize
    @books = []
    @people = []
    @rentals = []
  end

  def list_books
    if @books.empty?
      puts 'No books available in the library.'
    else
      puts 'List of all books:'
      @books.each { |book| puts "Title: \"#{book.title}\", Author: #{book.author}" }
    end
  end

  def list_people
    if @people.empty?
      puts 'No people registered in the library.'
    else
      puts 'List of all people:'
      @people.each do |person|
        role = person.is_a?(Student) ? 'Student' : 'Teacher'
        puts "[#{role}] Name: #{person.name}, ID: #{person.id}, Age: #{person.age}"
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
      puts 'Invalid option. Please choose 1 for a student or 2 for a teacher.'
    end
  end

  def create_student
    age = get_valid_age
    name = get_valid_name
    permission = get_valid_permission

    student = Student.new(age, nil, name, parent_permission: permission)
    @people << student
    puts 'Student created successfully!'
  end

  def create_teacher
    age = get_valid_age
    name = get_valid_name
    print 'Specialization: '
    specialization = gets.chomp

    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    puts 'Teacher created successfully!'
  end

  def create_book
    print 'Title: '
    title = gets.chomp.strip
    print 'Author: '
    author = gets.chomp.strip

    if title.empty? || author.empty?
      puts 'Title and Author cannot be empty.'
      return
    end

    book = Book.new(title, author)
    @books << book
    puts 'Book created successfully!'
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'Cannot create a rental. Please add at least one book and one person.'
      return
    end

    book_index = select_book
    return if book_index.nil?

    person_index = select_person
    return if person_index.nil?

    print 'Date (YYYY-MM-DD): '
    date_str = gets.chomp
    begin
      date = Date.parse(date_str)
    rescue ArgumentError
      puts 'Invalid date format. Please use YYYY-MM-DD.'
      return
    end

    rental = Rental.new(date, @books[book_index], @people[person_index])
    @rentals << rental
    puts 'Rental created successfully!'
  end

  def list_rentals
    print 'ID of person: '
    person_id = gets.chomp.to_i

    person = @people.find { |p| p.id == person_id }

    if person.nil?
      puts "Person with ID #{person_id} not found."
      return
    end

    if person.rentals.empty?
      puts "No rentals found for #{person.name}."
    else
      puts "Rentals for #{person.name}:"
      person.rentals.each do |rental|
        puts "Date: #{rental.date}, Book: \"#{rental.book.title}\" by #{rental.book.author}"
      end
    end
  end

  private

  def get_valid_age
    age = 0
    loop do
      print 'Age: '
      age_input = gets.chomp
      if age_input.match?(/^\d+$/) && age_input.to_i.positive?
        age = age_input.to_i
        break
      else
        puts 'Please enter a valid positive integer for age.'
      end
    end
    age
  end

  def get_valid_name
    name = ''
    loop do
      print 'Name: '
      name = gets.chomp.strip
      break unless name.empty?

      puts 'Name cannot be empty. Please try again.'
    end
    name
  end

  def get_valid_permission
    permission = true
    loop do
      print 'Has parent permission? [Y/N]: '
      perm_input = gets.chomp.upcase
      if %w[Y N].include?(perm_input)
        permission = (perm_input == 'Y')
        break
      else
        puts 'Invalid input. Please enter Y or N.'
      end
    end
    permission
  end

  def select_book
    puts 'Select a book from the following list by number:'
    @books.each_with_index { |book, index| puts "#{index}) Title: \"#{book.title}\", Author: #{book.author}" }

    book_index_input = gets.chomp
    return nil unless book_index_input.match?(/^\d+$/)

    book_index = book_index_input.to_i
    if book_index.negative? || book_index >= @books.length
      puts 'Invalid book selection.'
      return nil
    end
    book_index
  end

  def select_person
    puts 'Select a person from the following list by number (not id):'
    @people.each_with_index do |person, index|
      role = person.is_a?(Student) ? 'Student' : 'Teacher'
      puts "#{index}) [#{role}] Name: #{person.name}, ID: #{person.id}, Age: #{person.age}"
    end

    person_index_input = gets.chomp
    return nil unless person_index_input.match?(/^\d+$/)

    person_index = person_index_input.to_i
    if person_index.negative? || person_index >= @people.length
      puts 'Invalid person selection.'
      return nil
    end
    person_index
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
    name = @nameable.correct_name
    name.length > 10 ? name[0...10] : name
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    @nameable.correct_name.capitalize
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
  attr_reader :parent_permission

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
    self.classroom = classroom if classroom
  end

  def play_hooky
    '¯\(ツ)/¯'
  end

  def classroom=(classroom)
    @classroom = classroom
    classroom.students.push(self) unless classroom.students.include?(self)
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