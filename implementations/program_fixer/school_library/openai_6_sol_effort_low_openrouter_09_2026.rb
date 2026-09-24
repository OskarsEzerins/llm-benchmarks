require 'date'

class Nameable
  def correct_name
    raise NotImplementedError, 'Subclasses must implement correct_name'
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
    super.to_s[0, 10]
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    super.to_s.capitalize
  end
end

class Person < Nameable
  attr_reader :id, :rentals
  attr_accessor :name, :age

  def initialize(age = 0, name = 'Unknown', parent_permission: true)
    @id = self.class.next_id
    @age = Integer(age, exception: false) || 0
    @age = 0 if @age.negative?
    @name = name.to_s.strip
    @name = 'Unknown' if @name.empty?
    @parent_permission = parent_permission == true
    @rentals = []
  end

  def self.next_id
    Person.instance_variable_set(:@next_id, Person.instance_variable_get(:@next_id).to_i + 1)
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
    self.classroom = classroom unless classroom.nil?
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    return if room.nil?

    @classroom.students.delete(self) if @classroom && @classroom != room
    @classroom = room
    room.students << self unless room.students.include?(self)
  end

  alias assign_classroom classroom=
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

class Classroom
  attr_accessor :label
  attr_reader :students

  def initialize(label)
    @label = label
    @students = []
  end

  def add_student(student)
    student.classroom = self
  end
end

class Book
  attr_accessor :title, :author
  attr_reader :rentals

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
  attr_reader :date, :book, :person

  def initialize(date, book, person)
    @date = date
    @book = book
    @person = person
    book.rentals << self
    person.rentals << self
  end
end

class App
  attr_reader :books, :people

  def initialize
    @books = []
    @people = []
  end

  def list_books
    puts 'No books available' if @books.empty?
    @books.each { |book| puts "title: #{book.title}, author: #{book.author}" }
  end

  def list_people
    puts 'No one has registered' if @people.empty?
    @people.each do |person|
      puts "[#{person.class}] id: #{person.id}, Name: #{person.name}, Age: #{person.age}"
    end
  end

  def create_person
    print 'Student(1) or Teacher(2)? '
    case read_input
    when '1', '3' then create_student
    when '2' then create_teacher
    else puts 'Invalid selection'
    end
  end

  def create_student
    print 'Name: '
    name = read_input
    print 'Age: '
    age = valid_age(read_input)
    return unless age

    print 'Parent permission? (Y/N): '
    permission = read_input&.upcase
    unless %w[Y N].include?(permission)
      puts 'Invalid parent permission'
      return
    end

    @people << Student.new(age, nil, name, parent_permission: permission == 'Y')
  end

  def create_teacher
    print 'Name: '
    name = read_input
    print 'Age: '
    age = valid_age(read_input)
    return unless age

    print 'Specialization: '
    specialization = read_input
    @people << Teacher.new(age, specialization, name)
  end

  def create_book
    print 'Title: '
    title = read_input
    print 'Author: '
    author = read_input
    @books << Book.new(title, author)
  end

  def create_rental
    puts 'Select a book'
    @books.each_with_index { |book, index| puts "#{index}: #{book.title}" }
    book_index = Integer(read_input, exception: false)

    puts 'Select person'
    @people.each_with_index { |person, index| puts "#{index}: #{person.name}" }
    person_index = Integer(read_input, exception: false)

    unless valid_indices?(person_index, book_index)
      puts 'Invalid selection'
      return
    end

    print 'Date: '
    date = read_input
    date = Date.today.to_s if date.nil? || date.empty?
    Rental.new(date, @books[book_index], @people[person_index])
  end

  def list_rentals
    print 'ID of person: '
    id = Integer(read_input, exception: false)
    person = @people.find { |entry| entry.id == id }
    unless person
      puts 'Person not found'
      return
    end

    person.rentals.each { |rental| puts "#{rental.date} - #{rental.book.title}" }
  end

  private

  def read_input
    gets&.strip
  end

  def valid_age(input)
    age = Integer(input, exception: false)
    return age if age && age >= 0

    puts 'Invalid age'
    nil
  end

  def valid_indices?(person_index, book_index)
    person_index && book_index &&
      person_index >= 0 && person_index < @people.length &&
      book_index >= 0 && book_index < @books.length
  end
end