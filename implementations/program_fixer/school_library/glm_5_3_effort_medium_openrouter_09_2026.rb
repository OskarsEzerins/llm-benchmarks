class Nameable
  def correct_name
    raise NotImplementedError, "#{self.class} must implement correct_name"
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

class TrimmerDecorator < Decorator
  def correct_name
    name = super
    name.length > 10 ? name[0, 10] : name
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    name = super
    name.empty? ? name : name[0].upcase + name[1..]
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
    students << student unless students.include?(student)
    student.classroom = self
  end
end

class Person < Nameable
  attr_accessor :name, :age, :rentals, :parent_permission
  attr_reader :id

  def initialize(age = 0, name = 'Unknown', parent_permission: true)
    super()
    @id = rand(1..1000)
    @name = name || 'Unknown'
    @age = age.is_a?(Integer) ? age : age.to_i
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

  def initialize(age, classroom = nil, name = 'Unknown', parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    @classroom = nil
    classroom.add_student(self) if classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    @classroom = room
    room.students << self unless room.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization = nil, name = 'Unknown', parent_permission: true)
    super(age, name, parent_permission: parent_permission)
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
    puts 'No books available' if @books.empty?
    @books.each do |book|
      puts "Title: #{book.title}, Author: #{book.author}"
    end
  end

  def list_people
    puts 'No one has registered' if @people.empty?
    @people.each do |person|
      puts "[#{person.class}] Name: #{person.name}, ID: #{person.id}, Age: #{person.age}"
    end
  end

  def create_person
    print 'Do you want to create a student (1) or a teacher (2)? [Input the number]: '
    choice = gets&.chomp
    case choice
    when '1' then create_student
    when '2' then create_teacher
    else
      puts 'Invalid option. Please try again.'
    end
  end

  def create_student
    print 'Name: '
    name = gets&.chomp
    name = 'Unknown' if name.nil? || name.empty?
    print 'Age: '
    age = gets&.chomp.to_i
    age = 0 if age.negative?
    print 'Has parent permission? [Y/N]: '
    perm = gets&.chomp.upcase
    parent_permission = case perm
                        when 'Y' then true
                        when 'N' then false
                        else
                          puts 'Invalid input, defaulting to true.'
                          true
                        end
    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
    puts 'Student created successfully'
  end

  def create_teacher
    print 'Name: '
    name = gets&.chomp
    name = 'Unknown' if name.nil? || name.empty?
    print 'Age: '
    age = gets&.chomp.to_i
    age = 0 if age.negative?
    print 'Specialization: '
    spec = gets&.chomp
    teacher = Teacher.new(age, spec, name)
    @people << teacher
    puts 'Teacher created successfully'
  end

  def create_book
    print 'Title: '
    title = gets&.chomp
    print 'Author: '
    author = gets&.chomp
    book = Book.new(title, author)
    @books << book
    puts 'Book created successfully'
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'Need at least one book and one person to create a rental.'
      return
    end
    puts 'Select a book from the following list by number:'
    @books.each_with_index { |book, i| puts "#{i}) Title: #{book.title}, Author: #{book.author}" }
    book_index = gets&.chomp.to_i
    unless book_index >= 0 && book_index < @books.length
      puts 'Invalid book selection.'
      return
    end
    puts 'Select a person from the following list by number (not ID):'
    @people.each_with_index { |person, i| puts "#{i}) [#{person.class}] Name: #{person.name}, ID: #{person.id}, Age: #{person.age}" }
    person_index = gets&.chomp.to_i
    unless person_index >= 0 && person_index < @people.length
      puts 'Invalid person selection.'
      return
    end
    print 'Date (YYYY-MM-DD): '
    date = gets&.chomp
    Rental.new(date, @books[book_index], @people[person_index])
    puts 'Rental created successfully'
  end

  def list_rentals
    print 'ID of person: '
    id = gets&.chomp.to_i
    person = @people.detect { |p| p.id == id }
    if person.nil?
      puts 'Person not found.'
      return
    end
    puts 'Rentals:'
    person.rentals.each do |rental|
      puts "Date: #{rental.date}, Book: #{rental.book.title} by #{rental.book.author}"
    end
  end
end