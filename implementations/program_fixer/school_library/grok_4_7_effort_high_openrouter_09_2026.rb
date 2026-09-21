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
    super[0, 10]
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    super.capitalize
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
  attr_accessor :title, :author
  attr_writer :rentals

  def initialize(title, author)
    @title = title
    @author = author
    @rentals = []
  end

  def rentals
    @rentals ||= []
  end

  def rentals=(value)
    @rentals = value.is_a?(Array) ? value : []
  end

  def add_rental(person, date)
    Rental.new(date, self, person)
  end
end

class Classroom
  attr_accessor :label
  attr_writer :students

  def initialize(label)
    @label = label
    @students = []
  end

  def students
    @students ||= []
  end

  def students=(value)
    @students = value.is_a?(Array) ? value : []
  end

  def add_student(student)
    students << student unless students.include?(student)
    student.classroom = self
  end
end

class Person < Nameable
  attr_accessor :name
  attr_writer :rentals

  def initialize(age, name = 'Unknown', parent_permission: true)
    super()
    @id = rand(1..1000)
    self.name = name
    self.age = age
    self.parent_permission = parent_permission
    @rentals = []
  end

  def id
    @id.to_i
  end

  def id=(value)
    @id = value.to_i
  end

  def age
    @age.to_i
  end

  def age=(value)
    @age = value.to_i
  end

  def parent_permission
    !!@parent_permission
  end

  def parent_permission=(value)
    @parent_permission = case value
                         when String
                           value.strip.upcase == 'Y'
                         else
                           !!value
                         end
  end

  def rentals
    @rentals ||= []
  end

  def rentals=(value)
    @rentals = value.is_a?(Array) ? value : []
  end

  def name=(value)
    @name = value.nil? || value.to_s.strip.empty? ? 'Unknown' : value.to_s
  end

  def can_use_services?
    of_age? || parent_permission
  end

  def correct_name
    @name
  end

  def add_rental(book, date)
    Rental.new(date, book, self)
  end

  private

  def of_age?
    age >= 18
  end
end

class Student < Person
  attr_reader :classroom

  def initialize(age, classroom, name = 'Unknown', parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom unless classroom.nil?
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    @classroom = room
    return if room.nil?

    room.students << self unless room.students.include?(self)
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
      puts 'No one has registered'
      return
    end

    @people.each do |person|
      puts "[#{person.class}] ID: #{person.id}, Name: #{person.name}, Age: #{person.age}"
    end
  end

  def create_person
    print 'Do you want to create a student (1) or a teacher (2)? [Input the number]: '
    choice = gets&.chomp&.strip
    case choice
    when '1'
      create_student
    when '2'
      create_teacher
    else
      puts 'Invalid option'
    end
  end

  def create_student
    name = prompt_non_empty('Name: ')
    return if name.nil?

    age = prompt_age
    return if age.nil?

    print 'Parent permission? [Y/N]: '
    permission = gets&.chomp&.strip&.upcase
    unless %w[Y N].include?(permission)
      puts 'Invalid parent permission. Please enter Y or N'
      return
    end

    @people << Student.new(age, nil, name, parent_permission: permission == 'Y')
    puts 'Student created successfully'
  end

  def create_teacher
    name = prompt_non_empty('Name: ')
    return if name.nil?

    age = prompt_age
    return if age.nil?

    specialization = prompt_non_empty('Specialization: ')
    return if specialization.nil?

    @people << Teacher.new(age, specialization, name)
    puts 'Teacher created successfully'
  end

  def create_book
    title = prompt_non_empty('Title: ')
    return if title.nil?

    author = prompt_non_empty('Author: ')
    return if author.nil?

    @books << Book.new(title, author)
    puts 'Book created successfully'
  end

  def create_rental
    if @books.empty?
      puts 'No books available'
      return
    end

    if @people.empty?
      puts 'No one has registered'
      return
    end

    puts 'Select a book'
    @books.each_with_index { |book, index| puts "#{index}: #{book.title}" }
    book_index = prompt_index
    return if book_index.nil?

    puts 'Select a person'
    @people.each_with_index { |person, index| puts "#{index}: #{person.name}" }
    person_index = prompt_index
    return if person_index.nil?

    unless valid_indices?(person_index, book_index)
      puts 'Invalid selection'
      return
    end

    Rental.new(Time.now.strftime('%Y-%m-%d'), @books[book_index], @people[person_index])
    puts 'Rental created successfully'
  end

  def list_rentals
    print 'ID of person: '
    raw_id = gets&.chomp&.strip
    unless raw_id =~ /\A\d+\z/
      puts 'Invalid ID'
      return
    end

    person = @people.find { |entry| entry.id == raw_id.to_i }
    if person.nil?
      puts 'Person not found'
      return
    end

    if person.rentals.empty?
      puts 'No rentals found'
      return
    end

    person.rentals.each { |rental| puts "#{rental.date} - #{rental.book.title}" }
  end

  private

  def valid_indices?(person_index, book_index)
    person_index >= 0 && person_index < @people.length &&
      book_index >= 0 && book_index < @books.length
  end

  def prompt_non_empty(prompt)
    print prompt
    value = gets&.chomp&.strip
    if value.nil? || value.empty?
      puts 'Input cannot be empty'
      return nil
    end
    value
  end

  def prompt_age
    print 'Age: '
    raw = gets&.chomp&.strip
    unless raw =~ /\A\d+\z/
      puts 'Invalid age. Please enter a non-negative integer'
      return nil
    end

    age = raw.to_i
    if age.negative?
      puts 'Invalid age. Please enter a non-negative integer'
      return nil
    end
    age
  end

  def prompt_index
    raw = gets&.chomp&.strip
    unless raw =~ /\A-?\d+\z/
      puts 'Invalid selection'
      return nil
    end
    raw.to_i
  end
end