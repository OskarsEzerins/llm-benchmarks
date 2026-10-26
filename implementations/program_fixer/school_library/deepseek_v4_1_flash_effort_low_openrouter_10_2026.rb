require 'date'

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
      puts 'No one has registered'
    else
      @people.each do |person|
        puts "[#{person.class}] id: #{person.id}, Name: #{person.name}, Age: #{person.age}"
      end
    end
  end

  def create_person
    print 'Student(1) or Teacher(2)? '
    choice = gets&.chomp
    case choice
    when '1', '3'
      create_student
    when '2'
      create_teacher
    else
      puts 'Invalid option'
    end
  end

  def create_student
    print 'Name: '
    name = gets&.chomp
    name = 'Unknown' if name.nil? || name.strip.empty?
    print 'Age: '
    age = gets&.chomp.to_i
    age = 0 if age < 0
    print 'Parent permission? [Y/N]: '
    permission = gets&.chomp
    parent_permission = permission&.upcase == 'Y'
    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
    student
  end

  def create_teacher
    print 'Name: '
    name = gets&.chomp
    name = 'Unknown' if name.nil? || name.strip.empty?
    print 'Age: '
    age = gets&.chomp.to_i
    age = 0 if age < 0
    print 'Specialization: '
    specialization = gets&.chomp
    specialization = 'Unknown' if specialization.nil? || specialization.strip.empty?
    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    teacher
  end

  def create_book
    print 'Title: '
    title = gets&.chomp
    title = 'Unknown' if title.nil? || title.strip.empty?
    print 'Author: '
    author = gets&.chomp
    author = 'Unknown' if author.nil? || author.strip.empty?
    book = Book.new(title, author)
    @books << book
    book
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'No books or people available'
      return
    end

    puts 'Select a book'
    @books.each_with_index { |book, index| puts "#{index}: #{book.title}" }
    book_index = gets&.to_i

    puts 'Select person'
    @people.each_with_index { |person, index| puts "#{index}: #{person.name}" }
    person_index = gets&.to_i

    if valid_indices?(person_index, book_index)
      Rental.new(Date.today, @books[book_index], @people[person_index])
    else
      puts 'Invalid selection'
    end
  end

  def list_rentals
    print 'ID of person: '
    person_id = gets&.chomp.to_i
    person = @people.find { |p| p.id == person_id }
    if person
      person.rentals.each { |rental| puts "#{rental.date} - #{rental.book.title}" }
    else
      puts 'No person found'
    end
  end

  private

  def valid_indices?(person_index, book_index)
    person_index >= 0 && person_index < @people.length &&
      book_index >= 0 && book_index < @books.length
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, 'correct_name must be implemented'
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
    students << student unless students.include?(student)
    student.classroom = self unless student.classroom == self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals
  attr_reader :parent_permission

  @@id_counter = 0

  def self.next_id
    @@id_counter += 1
  end

  def initialize(age_or_name = 0, name_or_age = 'Unknown', parent_permission: true)
    super()
    if age_or_name.is_a?(String) && name_or_age.is_a?(Integer)
      age = name_or_age
      name = age_or_name
    else
      age = age_or_name
      name = name_or_age
    end

    @id = Person.next_id
    @name = (name.nil? || name.to_s.strip.empty?) ? 'Unknown' : name
    @age = age.to_i
    @age = 0 if @age < 0
    @parent_permission = case parent_permission
                         when true, 'Y', 'y' then true
                         else false
                         end
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
    @classroom = nil
    self.classroom = classroom if classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    @classroom = room
    room.students << self unless room.nil? || room.students.include?(self)
  end

  def assign_classroom(room)
    self.classroom = room
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name = 'Unknown', parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end