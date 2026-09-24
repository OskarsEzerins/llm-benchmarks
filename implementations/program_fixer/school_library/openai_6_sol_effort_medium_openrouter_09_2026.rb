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
    super[0, 10]
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    super.capitalize
  end
end

class Person < Nameable
  attr_reader :id, :rentals
  attr_accessor :name, :age

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id = self.class.next_id
    @name = name.to_s.strip.empty? ? 'Unknown' : name.to_s.strip
    @age = self.class.valid_age(age) || 0
    @parent_permission = parent_permission == true
    @rentals = []
  end

  def self.next_id
    Person.instance_variable_set(:@next_id, Person.instance_variable_get(:@next_id).to_i + 1)
  end

  def self.valid_age(value)
    return value if value.is_a?(Integer) && value >= 0
    return nil unless value.is_a?(String) && value.strip.match?(/\A\d+\z/)

    value.strip.to_i
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
    assign_classroom(classroom) if classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def assign_classroom(room)
    return @classroom unless room.is_a?(Classroom)

    @classroom.students.delete(self) if @classroom && @classroom != room
    @classroom = room
    room.students << self unless room.students.include?(self)
    room
  end

  alias classroom= assign_classroom
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name)
    super(name, age)
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
    student.assign_classroom(self)
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
    when '1' then create_student
    when '2' then create_teacher
    else
      puts 'Invalid selection'
      nil
    end
  end

  def create_student
    print 'Name: '
    name = read_input
    return invalid_input('name') if name.nil? || name.empty?

    print 'Age: '
    age = Person.valid_age(read_input)
    return invalid_input('age') unless age

    print 'Parent permission? (Y/N): '
    permission = read_input&.upcase
    return invalid_input('parent permission') unless %w[Y N].include?(permission)

    student = Student.new(age, nil, name, parent_permission: permission == 'Y')
    @people << student
    student
  end

  def create_teacher
    print 'Name: '
    name = read_input
    return invalid_input('name') if name.nil? || name.empty?

    print 'Age: '
    age = Person.valid_age(read_input)
    return invalid_input('age') unless age

    print 'Specialization: '
    specialization = read_input
    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    teacher
  end

  def create_book
    print 'Title: '
    title = read_input
    print 'Author: '
    author = read_input
    return invalid_input('book') if title.nil? || title.empty? || author.nil? || author.empty?

    book = Book.new(title, author)
    @books << book
    book
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'A book and a person are required to create a rental'
      return nil
    end

    puts 'Select a book'
    @books.each_with_index { |book, index| puts "#{index}: #{book.title}" }
    book_index = read_index

    puts 'Select a person'
    @people.each_with_index { |person, index| puts "#{index}: #{person.name}" }
    person_index = read_index

    return invalid_input('selection') unless valid_indices?(person_index, book_index)

    Rental.new(Date.today, @books[book_index], @people[person_index])
  end

  def list_rentals
    print 'ID of person: '
    input = read_input
    return invalid_input('person ID') unless input&.match?(/\A\d+\z/)

    person = @people.find { |entry| entry.id == input.to_i }
    return invalid_input('person ID') unless person

    person.rentals.each { |rental| puts "#{rental.date} - #{rental.book.title}" }
  end

  private

  def read_input
    gets&.strip
  end

  def read_index
    input = read_input
    input.to_i if input&.match?(/\A\d+\z/)
  end

  def valid_indices?(person_index, book_index)
    person_index && book_index &&
      person_index < @people.length && book_index < @books.length
  end

  def invalid_input(field)
    puts "Invalid #{field}"
    nil
  end
end