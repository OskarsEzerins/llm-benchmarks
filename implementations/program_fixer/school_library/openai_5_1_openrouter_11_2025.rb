require 'date'

class App
  def initialize
    @books = []
    @people = []
    @rentals = []
  end

  def list_books
    if @books.empty?
      puts 'No books available'
      return
    end

    @books.each do |book|
      puts "Title: \"#{book.title}\", Author: #{book.author}"
    end
  end

  def list_people
    if @people.empty?
      puts 'No people available'
      return
    end

    @people.each do |person|
      puts "[#{person.class}] ID: #{person.id}, Name: #{person.name}, Age: #{person.age}"
    end
  end

  def create_person
    choice = nil
    loop do
      print 'Do you want to create a student (1) or a teacher (2)? [Input the number]: '
      input = gets
      return unless input
      choice = input.strip
      break if %w[1 2].include?(choice)

      puts 'Invalid option. Please enter 1 for student or 2 for teacher.'
    end

    case choice
    when '1'
      create_student
    when '2'
      create_teacher
    end
  end

  def create_student
    name = nil
    loop do
      print 'Name: '
      input = gets
      return unless input
      name = input.strip
      name = 'Unknown' if name.empty?
      break
    end

    age = nil
    loop do
      print 'Age: '
      input = gets
      return unless input
      if input.strip =~ /^\d+$/
        age = input.to_i
        break
      else
        puts 'Invalid age. Please enter a non-negative number.'
      end
    end

    parent_permission = nil
    loop do
      print 'Has parent permission? [Y/N]: '
      input = gets
      return unless input
      case input.strip.upcase
      when 'Y'
        parent_permission = true
        break
      when 'N'
        parent_permission = false
        break
      else
        puts 'Invalid input. Please enter Y or N.'
      end
    end

    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
    puts 'Student created successfully'
  end

  def create_teacher
    name = nil
    loop do
      print 'Name: '
      input = gets
      return unless input
      name = input.strip
      name = 'Unknown' if name.empty?
      break
    end

    age = nil
    loop do
      print 'Age: '
      input = gets
      return unless input
      if input.strip =~ /^\d+$/
        age = input.to_i
        break
      else
        puts 'Invalid age. Please enter a non-negative number.'
      end
    end

    specialization = nil
    loop do
      print 'Specialization: '
      input = gets
      return unless input
      specialization = input.strip
      specialization = 'Unknown' if specialization.empty?
      break
    end

    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    puts 'Teacher created successfully'
  end

  def create_book
    title = nil
    loop do
      print 'Title: '
      input = gets
      return unless input
      title = input.strip
      title = 'Untitled' if title.empty?
      break
    end

    author = nil
    loop do
      print 'Author: '
      input = gets
      return unless input
      author = input.strip
      author = 'Unknown' if author.empty?
      break
    end

    @books << Book.new(title, author)
    puts 'Book created successfully'
  end

  def create_rental
    if @books.empty?
      puts 'No books available to rent.'
      return
    end

    if @people.empty?
      puts 'No people available to create a rental.'
      return
    end

    puts 'Select a book from the following list by number:'
    @books.each_with_index { |book, index| puts "#{index}) Title: \"#{book.title}\", Author: #{book.author}" }

    book_index = nil
    loop do
      input = gets
      return unless input
      if input.strip =~ /^\d+$/ && input.to_i.between?(0, @books.length - 1)
        book_index = input.to_i
        break
      else
        puts 'Invalid book selection. Please enter a valid index.'
      end
    end

    puts 'Select a person from the following list by number (not id):'
    @people.each_with_index do |person, index|
      puts "#{index}) [#{person.class}] Name: #{person.name}, ID: #{person.id}, Age: #{person.age}"
    end

    person_index = nil
    loop do
      input = gets
      return unless input
      if input.strip =~ /^\d+$/ && input.to_i.between?(0, @people.length - 1)
        person_index = input.to_i
        break
      else
        puts 'Invalid person selection. Please enter a valid index.'
      end
    end

    print 'Date (YYYY-MM-DD): '
    date_input = gets
    return unless date_input
    date = date_input.strip
    date = Date.today.to_s if date.empty?

    book = @books[book_index]
    person = @people[person_index]
    rental = Rental.new(date, book, person)
    @rentals << rental
    puts 'Rental created successfully'
  end

  def list_rentals
    if @rentals.empty?
      puts 'No rentals available'
      return
    end

    print 'ID of person: '
    input = gets
    return unless input
    person_id = input.strip.to_i

    person = @people.find { |p| p.id == person_id }

    if person.nil?
      puts 'Person not found.'
      return
    end

    if person.rentals.empty?
      puts 'No rentals found for this person.'
      return
    end

    person.rentals.each do |rental|
      puts "#{rental.date} - Book: \"#{rental.book.title}\" by #{rental.book.author}"
    end
  end

  private

  def valid_indices?(person_index, book_index)
    person_index.is_a?(Integer) &&
      book_index.is_a?(Integer) &&
      person_index >= 0 &&
      book_index >= 0 &&
      person_index < @people.length &&
      book_index < @books.length
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, 'Subclasses must implement the correct_name method'
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
    name = super
    return '' if name.nil?

    name.length > 10 ? name[0, 10] : name
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    name = super
    return '' if name.nil?

    name.capitalize
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

  def add_student(student)
    @students << student unless @students.include?(student)
    student.classroom = self
  end
end

class Person < Nameable
  attr_reader :id, :age
  attr_accessor :name, :rentals

  def initialize(age, name = 'Unknown', parent_permission: true)
    super()
    @id = Random.rand(1..1000)
    @name = (name.nil? || name.strip.empty?) ? 'Unknown' : name
    @age = age.to_i
    @parent_permission = !!parent_permission
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
    classroom.add_student(self) if classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(classroom)
    @classroom = classroom
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name)
    super(age, name, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end