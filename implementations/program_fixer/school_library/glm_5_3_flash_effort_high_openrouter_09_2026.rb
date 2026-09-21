require 'date'

class App
  def initialize
    @books  = []
    @people = []
  end

  def list_books
    if @books.empty?
      puts 'No books available'
      return
    end
    @books.each do |bk|
      puts "Title: \"#{bk.title}\", Author: #{bk.author}"
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
      return
    end
    @people.each do |human|
      puts "[#{human.class.name}] id: #{human.id}, Name: #{human.correct_name}, Age: #{human.age}"
    end
  end

  def create_person
    print 'Student(3) or Teacher(1)? '
    choice = gets&.chomp&.strip
    case choice
    when '1' then create_teacher
    when '3' then create_student
    else puts 'Invalid selection. Please choose 1 (Teacher) or 3 (Student).'
    end
  end

  def create_student
    name = read_name
    age  = read_age
    perm = read_permission
    student = Student.new(age, nil, name, parent_permission: perm)
    @people << student
    puts 'Student created successfully'
  end

  def create_teacher
    name = read_name
    age  = read_age
    print 'Specialization: '
    spec = gets&.chomp&.strip
    spec = 'Unknown' if spec.nil? || spec.empty?
    teacher = Teacher.new(name, spec, age)
    @people << teacher
    puts 'Teacher created successfully'
  end

  def create_book
    print 'Title: '
    title = gets&.chomp&.strip
    if title.nil? || title.empty?
      puts 'Title cannot be empty'
      return
    end
    print 'Author: '
    author = gets&.chomp&.strip
    if author.nil? || author.empty?
      puts 'Author cannot be empty'
      return
    end
    @books << Book.new(title, author)
    puts 'Book created successfully'
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'You need at least one book and one person to create a rental'
      return
    end

    puts 'Select a book:'
    @books.each_with_index { |b, i| puts "#{i}) #{b.title}" }
    book_index = gets.to_i

    puts 'Select a person:'
    @people.each_with_index { |p, i| puts "#{i}) [#{p.class.name}] #{p.correct_name} (id: #{p.id})" }
    person_index = gets.to_i

    unless valid_indices?(person_index, book_index)
      puts 'Invalid selection. No rental created.'
      return
    end

    print 'Date (YYYY-MM-DD) or press Enter for today: '
    date_input = gets&.chomp&.strip
    date = begin
      date_input.nil? || date_input.empty? ? Date.today : Date.parse(date_input)
    rescue Date::Error
      Date.today
    end

    Rental.new(date, @books[book_index], @people[person_index])
    puts 'Rental created successfully'
  end

  def list_rentals
    print 'ID of person: '
    pid_input = gets&.chomp&.strip
    pid = pid_input.to_i

    person = @people.find { |p| p.id == pid }
    if person.nil?
      puts 'Person not found'
      return
    end

    if person.rentals.empty?
      puts 'No rentals for this person'
      return
    end

    puts 'Rentals:'
    person.rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
  end

  private

  def read_name
    name = nil
    loop do
      print 'Name: '
      name = gets&.chomp&.strip
      break if !name.nil? && !name.empty?
      puts 'Name cannot be empty. Please try again.'
    end
    name
  end

  def read_age
    loop do
      print 'Age: '
      input = gets&.chomp&.strip
      if input&.match?(/\A\d+\z/)
        return input.to_i
      end
      puts 'Please enter a valid non-negative integer age.'
    end
  end

  def read_permission
    loop do
      print 'Has parent permission? [Y/N]: '
      answer = gets&.chomp&.strip&.upcase
      return true if answer == 'Y'
      return false if answer == 'N'
      puts 'Invalid input. Please enter Y or N.'
    end
  end

  def valid_indices?(person_index, book_index)
    person_index >= 0 && person_index < @people.length &&
      book_index >= 0 && book_index < @books.length
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, "#{self.class} has not implemented the correct_name method"
  end
end

class Decorator < Nameable
  attr_reader :nameable

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
  attr_reader :date, :book, :person

  def initialize(date, book, person)
    @date   = date
    @book   = book
    @person = person
    book.rentals << self
    person.rentals << self
  end
end

class Book
  attr_accessor :title, :author, :rentals

  def initialize(title, author)
    @title   = title
    @author  = author
    @rentals = []
  end

  def add_rental(person, date)
    Rental.new(date, self, person)
  end
end

class Classroom
  attr_accessor :label, :students

  def initialize(label)
    @label    = label
    @students = []
  end

  def add_student(student)
    students << student unless students.include?(student)
    student.classroom = self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals
  attr_reader   :parent_permission

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    super()
    @id                = rand(1..1000)
    @name              = name.is_a?(String) && !name.strip.empty? ? name : 'Unknown'
    @age               = age.is_a?(Integer) ? age : 0
    @parent_permission = parent_permission == true
    @rentals           = []
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
    super(name, age, parent_permission: parent_permission)
    @classroom = classroom
    classroom&.add_student(self) unless classroom.nil?
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

  def initialize(age_or_name = 0, specialization = nil, name_or_age = 'Unknown', parent_permission: true)
    if age_or_name.is_a?(Integer)
      age  = age_or_name
      name = name_or_age
    else
      name = age_or_name
      age  = name_or_age.is_a?(Integer) ? name_or_age : 0
    end
    super(name, age, parent_permission: parent_permission)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end