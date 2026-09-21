require 'date'

class App
  def initialize
    @books   = []
    @people  = []
    @rentals = []
  end

  def list_books
    puts 'No books available' if @books.empty?
    @books.each do |bk|
      puts "title: #{bk.title}, author: #{bk.author}"
    end
  end

  def list_people
    puts 'No one has registered' if @people.empty?
    @people.each do |human|
      puts "[#{human.class}] id: #{human.id}, Name: #{human.name}, Age: #{human.age}"
    end
  end

  def create_person
    loop do
      print 'Student(3) or Teacher(1)? '
      choice = gets&.chomp
      if choice == '1'
        create_teacher
        return
      elsif choice == '3'
        create_student
        return
      else
        puts 'Invalid selection, please enter 1 or 3'
      end
    end
  end

  def create_student
    print 'Name: '
    nm = gets&.chomp
    nm = 'Unknown' if nm.nil? || nm.strip.empty?
    print 'Age: '
    ag = read_age
    perm = read_permission
    stu = Student.new(ag, nil, nm, parent_permission: perm)
    @people << stu
    puts 'Student created'
  end

  def create_teacher
    print 'Name: '
    nm = gets&.chomp
    nm = 'Unknown' if nm.nil? || nm.strip.empty?
    print 'Age: '
    ag = read_age
    print 'Specialization: '
    spec = gets&.chomp
    spec = 'Unknown' if spec.nil? || spec.strip.empty?
    t = Teacher.new(ag, spec, nm)
    @people.push(t)
    puts 'Teacher created'
  end

  def create_book
    print 'Title: '
    t = gets&.chomp
    t = 'Untitled' if t.nil? || t.strip.empty?
    print 'Author: '
    a = gets&.chomp
    a = 'Unknown' if a.nil? || a.strip.empty?
    @books << Book.new(t, a)
    puts 'Book created'
  end

  def create_rental
    return puts 'No books available' if @books.empty?
    return puts 'No people registered' if @people.empty?

    puts 'Select a book'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title}" }
    bi = gets.to_i
    puts 'Select person'
    @people.each_with_index { |p, i| puts "#{i}: #{p.name}" }
    pi = gets.to_i
    unless valid_indices?(pi, bi)
      puts 'Invalid selection'
      return
    end
    rental = Rental.new(Date.today.to_s, @books[bi], @people[pi])
    @rentals << rental
    puts 'Rental created'
  end

  def list_rentals
    print 'ID of person: '
    pid = gets.to_i
    p_obj = @people.detect { |pr| pr.id == pid }
    if p_obj.nil?
      puts 'Person not found'
      return
    end
    puts 'Rentals:'
    p_obj.rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
  end

  private

  def read_age
    loop do
      input = gets
      value = input.to_i
      return value if input&.match?(/\A\d+\z/)
      print 'Invalid age, enter a non-negative integer: '
    end
  end

  def read_permission
    loop do
      print 'Parent permission? (Y/N): '
      answer = gets&.chomp.to_s.strip.upcase
      return true if answer == 'Y'
      return false if answer == 'N'
      puts 'Invalid response, please answer Y or N'
    end
  end

  def valid_indices?(p_i, b_i)
    p_i >= 0 && p_i < @people.length && b_i >= 0 && b_i < @books.length
  end
end

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
  @next_id = 0

  def self.next_id
    @next_id += 1
  end

  attr_accessor :id, :name, :age, :rentals

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    super()
    @id = Person.next_id
    @name = name.to_s.empty? ? 'Unknown' : name
    @age = age.to_i
    @parent_permission = parent_permission == true
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
    super(name, age, parent_permission: parent_permission)
    @classroom = classroom
    classroom&.students << self if classroom && !classroom.students.include?(self)
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

  def initialize(age = 0, specialization = 'Unknown', name = 'Unknown', parent_permission: true)
    super(name, age, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end