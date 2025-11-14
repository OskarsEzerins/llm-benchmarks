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
    @books.each do |book|
      puts "Title: #{book.title}, Author: #{book.author}"
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered yet'
      return
    end

    @people.each do |person|
      puts "[#{person.class}] ID: #{person.id}, Name: #{person.correct_name}, Age: #{person.age}"
    end
  end

  def create_person
    loop do
      print 'Create a student(1) or teacher(2)? [1/2]: '
      choice = gets.chomp
      case choice
      when '1'
        create_student
        break
      when '2'
        create_teacher
        break
      else
        puts 'Invalid option. Please enter 1 for student or 2 for teacher.'
      end
    end
  end

  def create_student
    name = prompt_non_empty('Name')
    age = prompt_age
    parent_permission = prompt_permission
    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
    puts 'Student created successfully'
  end

  def create_teacher
    name = prompt_non_empty('Name')
    age = prompt_age
    print 'Specialization: '
    specialization = gets.chomp.strip
    specialization = 'General' if specialization.empty?
    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    puts 'Teacher created successfully'
  end

  def create_book
    title = prompt_non_empty('Title')
    author = prompt_non_empty('Author')
    @books << Book.new(title, author)
    puts 'Book created successfully'
  end

  def create_rental
    if @books.empty?
      puts 'No books available'
      return
    end

    if @people.empty?
      puts 'No people registered'
      return
    end

    puts 'Select a book from the following list by number'
    book_index = select_index(@books) { |book| "#{book.title} by #{book.author}" }

    puts 'Select a person from the following list by number'
    person_index = select_index(@people) { |person| "[#{person.class}] #{person.name}, ID: #{person.id}" }

    date = prompt_date
    Rental.new(date, @books[book_index], @people[person_index])
    puts 'Rental created successfully'
  end

  def list_rentals
    print 'ID of person: '
    id_input = gets.chomp
    id = id_input.to_i
    person = @people.find { |p| p.id == id }
    unless person
      puts 'Person not found'
      return
    end

    if person.rentals.empty?
      puts 'No rentals found for this person'
      return
    end

    person.rentals.each do |rental|
      puts "#{rental.date} - #{rental.book.title} by #{rental.book.author}"
    end
  end

  private

  def prompt_non_empty(field)
    loop do
      print "#{field}: "
      input = gets.chomp.strip
      return input unless input.empty?

      puts "#{field} cannot be empty."
    end
  end

  def prompt_age
    loop do
      print 'Age: '
      input = gets.chomp
      return input.to_i if integer_string?(input) && input.to_i >= 0

      puts 'Invalid age. Please enter a non-negative integer.'
    end
  end

  def prompt_permission
    loop do
      print 'Parent permission? [Y/N]: '
      input = gets.chomp.strip.upcase
      return true if input == 'Y'
      return false if input == 'N'

      puts 'Please enter Y or N.'
    end
  end

  def prompt_date
    loop do
      print 'Date (YYYY-MM-DD) [leave empty for today]: '
      input = gets.chomp.strip
      return Date.today.to_s if input.empty?
      return input if valid_date_format?(input)

      puts 'Invalid date format. Expected YYYY-MM-DD.'
    end
  end

  def valid_date_format?(str)
    /\A\d{4}-\d{2}-\d{2}\z/.match?(str)
  end

  def integer_string?(str)
    /\A\d+\z/.match?(str)
  end

  def select_index(collection)
    loop do
      collection.each_with_index { |item, index| puts "#{index}) #{yield(item)}" }
      print 'Enter number: '
      input = gets.chomp
      index = input.to_i
      return index if input.match?(/\A\d+\z/) && index >= 0 && index < collection.length

      puts 'Invalid selection. Try again.'
    end
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
    return name unless name.is_a?(String)

    name[0, 10]
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    name = super
    return name unless name.is_a?(String)

    name.split.map(&:capitalize).join(' ')
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
    return if students.include?(student)

    students << student
    student.classroom = self unless student.classroom == self
  end
end

class Person < Nameable
  attr_reader :id
  attr_accessor :name, :age, :rentals

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id = self.class.next_id
    @name = name
    @age = age
    @parent_permission = parent_permission
    @rentals = []
  end

  def self.next_id
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
    @classroom = nil
    self.classroom = classroom if classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    return if room.nil?

    @classroom = room
    room.students << self unless room.students.include?(self)
  end

  def assign_classroom(room)
    self.classroom = room
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name)
    super(name, age, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end