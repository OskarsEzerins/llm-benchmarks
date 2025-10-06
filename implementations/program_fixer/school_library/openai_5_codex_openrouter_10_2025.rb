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
    else
      @books.each do |book|
        puts "Title: \"#{book.title}\", Author: #{book.author}"
      end
    end
  end

  def list_people
    if @people.empty?
      puts 'No people found'
    else
      @people.each do |person|
        puts "[#{person.class}] ID: #{person.id}, Name: #{person.name}, Age: #{person.age}"
      end
    end
  end

  def create_person
    puts 'Do you want to create a student (1) or a teacher (2)? [Input the number]:'
    choice = nil
    loop do
      choice = gets&.strip
      break if %w[1 2].include?(choice)

      puts 'Invalid selection. Please enter 1 for student or 2 for teacher:'
    end

    choice == '1' ? create_student : create_teacher
  end

  def create_student
    name = prompt_for_non_empty('Name: ')
    age = prompt_for_integer('Age: ')
    parent_permission = prompt_for_permission('Parent permission? [Y/N]: ')
    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
    puts 'Student created successfully'
  end

  def create_teacher
    name = prompt_for_non_empty('Name: ')
    age = prompt_for_integer('Age: ')
    specialization = prompt_for_non_empty('Specialization: ')
    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    puts 'Teacher created successfully'
  end

  def create_book
    title = prompt_for_non_empty('Title: ')
    author = prompt_for_non_empty('Author: ')
    book = Book.new(title, author)
    @books << book
    puts 'Book created successfully'
  end

  def create_rental
    if @books.empty?
      puts 'No books available to create a rental'
      return
    end

    if @people.empty?
      puts 'No people available to create a rental'
      return
    end

    puts 'Select a book from the following list by number'
    @books.each_with_index do |book, index|
      puts "#{index}) Title: \"#{book.title}\", Author: #{book.author}"
    end
    book_index = prompt_for_index(@books.length, 'Book number: ')

    puts 'Select a person from the following list by number (not ID)'
    @people.each_with_index do |person, index|
      puts "#{index}) [#{person.class}] Name: #{person.name}, ID: #{person.id}, Age: #{person.age}"
    end
    person_index = prompt_for_index(@people.length, 'Person number: ')

    print 'Date (YYYY-MM-DD): '
    date_input = gets&.strip
    date =
      if date_input.nil? || date_input.empty?
        Date.today.to_s
      else
        begin
          Date.parse(date_input).to_s
        rescue ArgumentError
          puts 'Invalid date format. Using today\'s date.'
          Date.today.to_s
        end
      end

    rental = Rental.new(date, @books[book_index], @people[person_index])
    @rentals << rental
    puts 'Rental created successfully'
  end

  def list_rentals
    print 'ID of person: '
    id_input = gets&.strip
    if id_input.nil? || id_input.empty? || id_input !~ /\A\d+\z/
      puts 'Invalid ID provided'
      return
    end

    person_id = id_input.to_i
    person = @people.find { |p| p.id == person_id }

    if person.nil?
      puts 'Person not found'
      return
    end

    if person.rentals.empty?
      puts 'No rentals found for this person'
    else
      person.rentals.each do |rental|
        puts "#{rental.date} - \"#{rental.book.title}\" by #{rental.book.author}"
      end
    end
  end

  private

  def prompt_for_non_empty(message)
    loop do
      print message
      input = gets&.strip
      return input unless input.nil? || input.empty?

      puts 'Input cannot be empty. Please try again.'
    end
  end

  def prompt_for_integer(message)
    loop do
      print message
      input = gets&.strip
      if input.nil? || input.empty?
        puts 'Input cannot be empty. Please enter a number.'
        next
      end

      unless input.match?(/\A-?\d+\z/)
        puts 'Please enter a valid integer.'
        next
      end

      value = input.to_i
      return value if value >= 0

      puts 'Number cannot be negative. Please try again.'
    end
  end

  def prompt_for_permission(message)
    loop do
      print message
      input = gets&.strip
      if input.nil? || input.empty?
        puts 'Please enter Y or N.'
        next
      end

      case input.downcase
      when 'y' then return true
      when 'n' then return false
      else
        puts 'Please enter Y or N.'
      end
    end
  end

  def prompt_for_index(size, message)
    loop do
      print message
      input = gets&.strip
      if input.nil? || input.empty?
        puts 'Input cannot be empty. Please enter a valid number.'
        next
      end

      unless input.match?(/\A\d+\z/)
        puts 'Please enter a valid number.'
        next
      end

      index = input.to_i
      return index if index.between?(0, size - 1)

      puts 'Selection out of range. Please try again.'
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
    return '' if name.nil?

    name.length > 10 ? name[0, 10] : name
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    name = super
    name.nil? ? '' : name.capitalize
  end
end

class Rental
  attr_reader :date, :book, :person

  def initialize(date, book, person)
    @date = date
    @book = book
    @person = person
    @book.rentals << self unless @book.rentals.include?(self)
    @person.rentals << self unless @person.rentals.include?(self)
  end
end

class Book
  attr_reader :title, :author, :rentals

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
    return if @students.include?(student)

    @students << student
    student.assign_classroom(self)
  end
end

class Person < Nameable
  attr_accessor :name, :age
  attr_reader :id, :rentals

  @@id_sequence = 0

  def self.generate_id
    @@id_sequence += 1
  end

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id = self.class.generate_id
    @name = (name.nil? || name.strip.empty?) ? 'Unknown' : name.strip
    @age = age.to_i.negative? ? 0 : age.to_i
    @parent_permission = !!parent_permission
    @rentals = []
  end

  def can_use_services?
    of_age? || parent_permission?
  end

  def parent_permission?
    @parent_permission
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
    self.classroom = classroom if classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def assign_classroom(classroom)
    self.classroom = classroom
  end

  def classroom=(room)
    return if room.nil?

    @classroom = room
    room.students << self unless room.students.include?(self)
  end
end

class Teacher < Person
  attr_reader :specialization

  def initialize(age, specialization, name)
    super(name, age, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end