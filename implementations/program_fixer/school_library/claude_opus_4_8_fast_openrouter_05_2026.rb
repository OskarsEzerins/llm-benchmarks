require 'date'

class Nameable
  def correct_name
    raise NotImplementedError
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
    name = @nameable.correct_name
    name.nil? ? name : name.capitalize
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals

  def initialize(age = 0, name = 'Unknown', parent_permission: true)
    @id = rand(1000)
    @name = (name.nil? || name.to_s.strip.empty?) ? 'Unknown' : name.to_s
    @age = age.to_i
    @parent_permission = parent_permission ? true : false
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
    super(age, name, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom if classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    return if room.nil?

    @classroom = room
    room.students << self unless room.students.include?(self)
  end

  alias assign_classroom classroom=
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name, parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    @specialization = specialization
  end

  def can_use_services?
    true
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

class Rental
  attr_accessor :date, :book, :person

  def initialize(date, book, person)
    @date   = date
    @book   = book
    @person = person
    book.rentals << self
    person.rentals << self
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
      puts "title: #{bk.title}, author: #{bk.author}"
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
      return
    end
    @people.each do |human|
      puts "[#{human.class}] id: #{human.id}, Name: #{human.name}, Age: #{human.age}"
    end
  end

  def create_person
    print 'Student(1) or Teacher(2)? '
    choice = gets&.chomp
    case choice
    when '1' then create_student
    when '2' then create_teacher
    else
      puts 'Invalid selection'
    end
  end

  def create_student
    print 'Name: '
    name = gets&.chomp
    print 'Age: '
    age = gets&.chomp.to_i
    print 'Parent permission? [Y/N]: '
    perm = gets&.chomp
    permission = perm.to_s.strip.upcase == 'Y'
    student = Student.new(age, nil, name, parent_permission: permission)
    @people << student
    puts 'Person created successfully'
  end

  def create_teacher
    print 'Name: '
    name = gets&.chomp
    print 'Age: '
    age = gets&.chomp.to_i
    print 'Specialization: '
    spec = gets&.chomp
    teacher = Teacher.new(age, spec, name)
    @people << teacher
    puts 'Person created successfully'
  end

  def create_book
    print 'Title: '
    title = gets&.chomp
    print 'Author: '
    author = gets&.chomp
    @books << Book.new(title, author)
    puts 'Book created successfully'
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'Need at least one book and one person'
      return
    end

    puts 'Select a book'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title}" }
    book_index = gets&.chomp.to_i

    puts 'Select person'
    @people.each_with_index { |p, i| puts "#{i}: #{p.name}" }
    person_index = gets&.chomp.to_i

    unless valid_indices?(person_index, book_index)
      puts 'Invalid selection'
      return
    end

    Rental.new(Date.today.to_s, @books[book_index], @people[person_index])
    puts 'Rental created successfully'
  end

  def list_rentals
    print 'ID of person: '
    pid = gets&.chomp.to_i
    person = @people.detect { |pr| pr.id == pid }
    if person.nil?
      puts 'Person not found'
      return
    end
    person.rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
  end

  private

  def valid_indices?(person_index, book_index)
    person_index.between?(0, @people.length - 1) &&
      book_index.between?(0, @books.length - 1)
  end
end