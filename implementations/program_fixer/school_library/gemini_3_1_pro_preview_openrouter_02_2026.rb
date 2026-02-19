require 'date'

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
    name.length > 10 ? name[0..9] : name
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    @nameable.correct_name.capitalize
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals, :parent_permission

  def initialize(age, name = 'Unknown', parent_permission: true)
    super()
    @id = Random.rand(1..10_000)
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

  def add_rental(date, book)
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
    @classroom = classroom
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

  def initialize(age, specialization, name = 'Unknown')
    super(age, name, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
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
    print 'Student(1) or Teacher(2)? '
    choice = gets.to_s.chomp
    
    case choice
    when '1'
      create_student
    when '2'
      create_teacher
    else
      puts 'Invalid choice. Returning to menu.'
    end
  end

  def create_student
    print 'Name: '
    name = gets.to_s.chomp
    name = 'Unknown' if name.strip.empty?
    
    print 'Age: '
    age_input = gets.to_s.chomp
    age = age_input.to_i
    age = 0 if age < 0
    
    print 'Parent permission? [Y/N]: '
    perm_input = gets.to_s.chomp.upcase
    perm = (perm_input == 'Y')
    
    student = Student.new(age, nil, name, parent_permission: perm)
    @people << student
    puts 'Person created successfully'
  end

  def create_teacher
    print 'Name: '
    name = gets.to_s.chomp
    name = 'Unknown' if name.strip.empty?
    
    print 'Age: '
    age_input = gets.to_s.chomp
    age = age_input.to_i
    age = 0 if age < 0
    
    print 'Specialization: '
    spec = gets.to_s.chomp
    spec = 'General' if spec.strip.empty?
    
    teacher = Teacher.new(age, spec, name)
    @people << teacher
    puts 'Person created successfully'
  end

  def create_book
    print 'Title: '
    title = gets.to_s.chomp
    title = 'Unknown' if title.strip.empty?
    
    print 'Author: '
    author = gets.to_s.chomp
    author = 'Unknown' if author.strip.empty?
    
    @books << Book.new(title, author)
    puts 'Book created successfully'
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'Need both books and people to create a rental'
      return
    end
    
    puts 'Select a book from the following list by number'
    @books.each_with_index do |book, index|
      puts "#{index}) Title: #{book.title}, Author: #{book.author}"
    end
    b_idx = gets.to_s.chomp.to_i
    
    puts 'Select person from the following list by number'
    @people.each_with_index do |person, index|
      puts "#{index}) [#{person.class}] Name: #{person.name}, ID: #{person.id}"
    end
    p_idx = gets.to_s.chomp.to_i
    
    if valid_indices?(p_idx, b_idx)
      print 'Date (YYYY-MM-DD): '
      date = gets.to_s.chomp
      date = Date.today.to_s if date.strip.empty?
      
      Rental.new(date, @books[b_idx], @people[p_idx])
      puts 'Rental created successfully'
    else
      puts 'Invalid selection. Rental not created.'
    end
  end

  def list_rentals
    print 'ID of person: '
    pid = gets.to_s.chomp.to_i
    person = @people.find { |pr| pr.id == pid }
    
    if person.nil?
      puts "No person found with ID #{pid}"
      return
    end
    
    if person.rentals.empty?
      puts 'This person has no rentals.'
      return
    end
    
    puts 'Rentals:'
    person.rentals.each do |rental|
      puts "#{rental.date} - #{rental.book.title} by #{rental.book.author}"
    end
  end

  private

  def valid_indices?(p_i, b_i)
    p_i >= 0 && p_i < @people.size && b_i >= 0 && b_i < @books.size
  end
end