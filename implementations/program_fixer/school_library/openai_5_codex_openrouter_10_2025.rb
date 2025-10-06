require 'date'

class App
  attr_reader :books, :people, :rentals

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
      puts 'No one has registered'
    else
      @people.each do |person|
        puts "[#{person.class}] ID: #{person.id}, Name: #{person.name}, Age: #{person.age}"
      end
    end
  end

  def create_person
    choice = nil
    loop do
      print 'Do you want to create a student (1) or a teacher (2)? '
      choice = gets&.strip
      break if %w[1 2].include?(choice)

      puts 'Invalid choice. Please enter 1 or 2.'
    end

    case choice
    when '1'
      create_student
    when '2'
      create_teacher
    end
  end

  def create_student
    name = prompt_for_name
    age = prompt_for_age('Age: ')
    parent_permission = prompt_for_permission
    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
    puts 'Student created successfully'
    student
  end

  def create_teacher
    name = prompt_for_name
    age = prompt_for_age('Age: ')
    specialization = prompt_for_specialization
    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    puts 'Teacher created successfully'
    teacher
  end

  def create_book
    title = prompt_for_text('Title: ')
    author = prompt_for_text('Author: ')
    book = Book.new(title, author)
    @books << book
    puts 'Book created successfully'
    book
  end

  def create_rental
    if @books.empty?
      puts 'No books available to rent.'
      return nil
    elsif @people.empty?
      puts 'No people available to create a rental.'
      return nil
    end

    puts 'Select a book from the following list by number'
    @books.each_with_index do |book, index|
      puts "#{index}) Title: \"#{book.title}\", Author: #{book.author}"
    end
    book = select_from_collection(@books, 'Book number: ')
    return nil if book.nil?

    puts 'Select a person from the following list by number (not ID)'
    @people.each_with_index do |person, index|
      puts "#{index}) [#{person.class}] Name: #{person.name}, ID: #{person.id}, Age: #{person.age}"
    end
    person = select_from_collection(@people, 'Person number: ')
    return nil if person.nil?

    date = prompt_for_date('Date (YYYY-MM-DD): ')
    rental = Rental.new(date, book, person)
    @rentals << rental
    puts 'Rental created successfully'
    rental
  end

  def list_rentals
    print 'ID of person: '
    input = gets
    if input.nil?
      puts 'No ID provided.'
      return
    end

    id = extract_integer(input.strip)
    if id.nil?
      puts 'Invalid ID.'
      return
    end

    person = @people.find { |p| p.id == id }
    if person.nil?
      puts 'Person not found'
      return
    end

    if person.rentals.empty?
      puts 'No rentals found for this person.'
    else
      person.rentals.each do |rental|
        puts "#{rental.date} - \"#{rental.book.title}\" by #{rental.book.author}"
      end
    end
  end

  private

  def prompt_for_name
    prompt_for_text('Name: ')
  end

  def prompt_for_text(prompt)
    print prompt
    input = gets
    return 'Unknown' if input.nil?

    text = input.strip
    text.empty? ? 'Unknown' : text
  end

  def prompt_for_age(prompt)
    loop do
      print prompt
      input = gets
      return 0 if input.nil?

      value = extract_integer(input.strip)
      unless value.nil?
        value = 0 if value.negative?
        return value
      end
      puts 'Please enter a valid numeric age.'
    end
  end

  def prompt_for_permission
    loop do
      print 'Parent permission? [Y/N]: '
      input = gets
      return false if input.nil?

      value = input.strip.downcase
      return true if %w[y yes].include?(value)
      return false if %w[n no].include?(value)

      puts 'Please enter Y or N.'
    end
  end

  def prompt_for_specialization
    prompt_for_text('Specialization: ')
  end

  def prompt_for_date(prompt)
    print prompt
    input = gets
    return Date.today.to_s if input.nil?

    text = input.strip
    return Date.today.to_s if text.empty?

    Date.parse(text).to_s
  rescue ArgumentError
    puts 'Invalid date format. Using today\'s date.'
    Date.today.to_s
  end

  def select_from_collection(collection, prompt)
    loop do
      print prompt
      input = gets
      return nil if input.nil?

      index = extract_integer(input.strip)
      if !index.nil? && index >= 0 && index < collection.length
        return collection[index]
      end
      puts 'Invalid selection. Please choose a valid number from the list.'
    end
  end

  def extract_integer(value)
    Integer(value)
  rescue ArgumentError, TypeError
    nil
  end

  def valid_indices?(person_index, book_index)
    return false unless person_index.is_a?(Integer) && book_index.is_a?(Integer)

    person_index >= 0 && person_index < @people.length &&
      book_index >= 0 && book_index < @books.length
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, 'Subclasses must implement #correct_name'
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
    super.to_s.capitalize
  end
end

class Rental
  attr_reader :date, :book, :person

  def initialize(date, book, person)
    raise ArgumentError, 'Book must be provided' if book.nil?
    raise ArgumentError, 'Person must be provided' if person.nil?

    @date = date.to_s
    @book = book
    @person = person
    book.rentals << self unless book.rentals.include?(self)
    person.rentals << self unless person.rentals.include?(self)
  end
end

class Book
  attr_reader :title, :author, :rentals

  def initialize(title, author)
    @title = sanitize_text(title, 'Untitled')
    @author = sanitize_text(author, 'Unknown')
    @rentals = []
  end

  def add_rental(person, date)
    Rental.new(date, self, person)
  end

  private

  def sanitize_text(value, fallback)
    text = value.to_s.strip
    text.empty? ? fallback : text
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
    return if student.nil?

    @students << student unless @students.include?(student)
    student.classroom = self unless student.classroom == self
  end
end

class Person < Nameable
  attr_reader :id, :name, :age, :rentals, :parent_permission

  def initialize(age, name = 'Unknown', parent_permission: true)
    @id = Random.rand(1..1000)
    self.age = age
    self.name = name
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

  def age=(value)
    integer_age = begin
      Integer(value)
    rescue ArgumentError, TypeError
      0
    end
    @age = integer_age.negative? ? 0 : integer_age
  end

  def name=(value)
    text = value.to_s.strip
    @name = text.empty? ? 'Unknown' : text
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
    @classroom = nil
    self.classroom = classroom if classroom
  end

  def classroom=(classroom)
    return if classroom.nil?

    @classroom = classroom
    classroom.add_student(self) unless classroom.students.include?(self)
  end

  def play_hooky
    '╰(°▽°)╯'
  end
end

class Teacher < Person
  attr_reader :specialization

  def initialize(age, specialization, name = 'Unknown')
    super(age, name, parent_permission: true)
    self.specialization = specialization
  end

  def specialization=(value)
    text = value.to_s.strip
    @specialization = text.empty? ? 'General' : text
  end

  def can_use_services?
    true
  end
end