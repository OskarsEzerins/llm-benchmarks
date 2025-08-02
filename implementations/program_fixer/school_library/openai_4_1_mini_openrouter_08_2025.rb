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
    choice = gets.chomp
    case choice
    when '1'
      create_student
    when '2'
      create_teacher
    else
      puts 'Invalid option'
      create_person
    end
  end

  def create_student
    print 'Name: '
    nm = gets.chomp
    if nm.nil? || nm.strip.empty?
      puts 'Name cannot be empty'
      return
    end

    print 'Age: '
    ag_input = gets.chomp
    ag = ag_input.to_i
    if ag_input !~ /^\d+$/ || ag < 0
      puts 'Invalid age'
      return
    end

    perm = nil
    loop do
      print 'Parent permission? [Y/N]: '
      perm_input = gets.chomp.upcase
      if %w[Y N].include?(perm_input)
        perm = perm_input == 'Y'
        break
      else
        puts "Please input 'Y' or 'N'"
      end
    end

    stu = Student.new(ag, nil, nm, parent_permission: perm)
    @people << stu
    puts 'Person created successfully'
  end

  def create_teacher
    print 'Name: '
    nm = gets.chomp
    if nm.nil? || nm.strip.empty?
      puts 'Name cannot be empty'
      return
    end

    print 'Age: '
    ag_input = gets.chomp
    ag = ag_input.to_i
    if ag_input !~ /^\d+$/ || ag < 0
      puts 'Invalid age'
      return
    end

    print 'Specialization: '
    spec = gets.chomp
    spec = 'Unknown' if spec.nil? || spec.strip.empty?

    t = Teacher.new(nm, spec, ag)
    @people << t
    puts 'Person created successfully'
  end

  def create_book
    print 'Title: '
    t = gets.chomp
    if t.nil? || t.strip.empty?
      puts 'Title cannot be empty'
      return
    end

    print 'Author: '
    a = gets.chomp
    if a.nil? || a.strip.empty?
      puts 'Author cannot be empty'
      return
    end

    @books << Book.new(t, a)
    puts 'Book created successfully'
  end

  def create_rental
    if @books.empty?
      puts 'No books available'
      return
    end
    if @people.empty?
      puts 'No people available'
      return
    end

    puts 'Select a book from the following list by number'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title} by #{b.author}" }
    bi = gets.chomp
    if bi !~ /^\d+$/ || bi.to_i < 0 || bi.to_i >= @books.length
      puts 'Invalid book selection'
      return
    end
    bi = bi.to_i

    puts 'Select a person from the following list by number (not id)'
    @people.each_with_index { |p, i| puts "#{i}: #{p.name} (#{p.class})" }
    pi = gets.chomp
    if pi !~ /^\d+$/ || pi.to_i < 0 || pi.to_i >= @people.length
      puts 'Invalid person selection'
      return
    end
    pi = pi.to_i

    print 'Date [YYYY-MM-DD]: '
    date_input = gets.chomp
    begin
      date = Date.parse(date_input)
    rescue ArgumentError
      puts 'Invalid date format'
      return
    end

    Rental.new(date, @books[bi], @people[pi])
    puts 'Rental created successfully'
  end

  def list_rentals
    print 'ID of person: '
    pid_input = gets.chomp
    if pid_input !~ /^\d+$/
      puts 'Invalid ID format'
      return
    end
    pid = pid_input.to_i
    p_obj = @people.detect { |pr| pr.id == pid }
    if p_obj.nil?
      puts 'Person not found'
      return
    end
    if p_obj.rentals.empty?
      puts 'No rentals found for this person'
      return
    end
    p_obj.rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
  end

  private

  def valid_indices?(p_i, b_i)
    p_i >= 0 && p_i < @people.length && b_i >= 0 && b_i < @books.size
  end
end

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
    super[0..9]
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    name = super
    return '' if name.nil? || name.empty?

    name[0].upcase + name[1..-1]
  end
end

class Rental
  attr_reader :date, :book, :person

  def initialize(date, book, person)
    @date   = date
    @book   = book
    @person = person
    @book.rentals << self
    @person.rentals << self
  end
end

class Book
  attr_reader :title, :author, :rentals

  def initialize(title, author)
    @title    = title
    @author   = author
    @rentals  = []
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

  def add_student(stud)
    unless students.include?(stud)
      students << stud
      stud.classroom = self
    end
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals

  def initialize(age = 0, name = 'Unknown', parent_permission: true)
    @id = rand(1..1000)
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
    @classroom = classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    @classroom = room
    room.add_student(self) unless room.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(name, specialization, age = 0)
    super(age, name, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end