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
        puts "Title: #{book.title}, Author: #{book.author}"
      end
    end
  end

  def list_people
    if @people.empty?
      puts 'No people registered'
    else
      @people.each do |person|
        puts "[#{person.class}] ID: #{person.id}, Name: #{person.name}, Age: #{person.age}"
      end
    end
  end

  def create_person
    loop do
      print 'Do you want to create a student(1) or a teacher(2)? [Input the number]: '
      choice = gets
      return if choice.nil?

      case choice.chomp
      when '1'
        create_student
        return
      when '2'
        create_teacher
        return
      else
        puts 'Invalid option. Please enter 1 or 2.'
      end
    end
  end

  def create_student
    name = prompt_non_empty('Name: ')
    age = prompt_non_negative_integer('Age: ')
    return unless name && age

    parent_permission = prompt_boolean('Parent permission? [Y/N]: ')
    return if parent_permission.nil?

    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
    puts 'Student created successfully'
  end

  def create_teacher
    name = prompt_non_empty('Name: ')
    age = prompt_non_negative_integer('Age: ')
    specialization = prompt_non_empty('Specialization: ')
    return unless name && age && specialization

    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    puts 'Teacher created successfully'
  end

  def create_book
    title = prompt_non_empty('Title: ')
    author = prompt_non_empty('Author: ')
    return unless title && author

    book = Book.new(title, author)
    @books << book
    puts 'Book created successfully'
  end

  def create_rental
    if @books.empty?
      puts 'There are no books available'
      return
    end

    if @people.empty?
      puts 'There are no people registered'
      return
    end

    puts 'Select a book from the following list by number'
    @books.each_with_index do |book, index|
      puts "#{index}) Title: #{book.title}, Author: #{book.author}"
    end
    book_index = prompt_index('Book number: ', @books.length)
    return if book_index.nil?

    puts 'Select a person from the following list by number (not id)'
    @people.each_with_index do |person, index|
      puts "#{index}) [#{person.class}] Name: #{person.name}, ID: #{person.id}, Age: #{person.age}"
    end
    person_index = prompt_index('Person number: ', @people.length)
    return if person_index.nil?

    print 'Date (YYYY-MM-DD): '
    date_input = gets
    return if date_input.nil?

    Rental.new(date_input.chomp, @books[book_index], @people[person_index])
    puts 'Rental created successfully'
  end

  def list_rentals
    print 'ID of person: '
    input = gets
    return if input.nil?

    person_id = input.chomp.to_i
    person = @people.find { |p| p.id == person_id }

    if person.nil?
      puts 'Person not found'
      return
    end

    if person.rentals.empty?
      puts 'No rentals for this person'
    else
      person.rentals.each do |rental|
        puts "Date: #{rental.date}, Book: #{rental.book.title} by #{rental.book.author}"
      end
    end
  end

  private

  def prompt_non_empty(message)
    loop do
      print message
      input = gets
      return nil if input.nil?

      value = input.chomp.strip
      return value unless value.empty?

      puts 'Input cannot be empty. Please try again.'
    end
  end

  def prompt_non_negative_integer(message)
    loop do
      print message
      input = gets
      return nil if input.nil?

      value = input.chomp.strip
      if value.match?(/^\d+$/)
        return value.to_i
      else
        puts 'Invalid input. Please enter a non-negative integer.'
      end
    end
  end

  def prompt_boolean(message)
    loop do
      print message
      input = gets
      return nil if input.nil?

      value = input.chomp.strip.upcase
      return true if value == 'Y'
      return false if value == 'N'

      puts "Invalid input. Please enter 'Y' or 'N'."
    end
  end

  def prompt_index(message, max)
    loop do
      print message
      input = gets
      return nil if input.nil?

      value = input.chomp.strip
      if value.match?(/^\d+$/)
        index = value.to_i
        return index if index >= 0 && index < max
      end

      puts "Invalid input. Please enter a number between 0 and #{max - 1}."
    end
  end

  def valid_indices?(person_index, book_index)
    person_index >= 0 && person_index < @people.length &&
      book_index >= 0 && book_index < @books.length
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
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
    @students << student unless @students.include?(student)
    student.classroom = self
  end
end

class Person < Nameable
  attr_reader :id, :parent_permission
  attr_accessor :name, :age, :rentals

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id = rand(1..1000)
    @name = name
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
    super(name, age, parent_permission: parent_permission)
    @classroom = classroom
    self.classroom = classroom if classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    @classroom = room
    room&.students&.push(self) unless room&.students&.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name = 'Unknown', parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end