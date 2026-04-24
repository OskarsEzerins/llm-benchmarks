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
    name = super
    name.length > 10 ? name[0..9] : name
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    @nameable.correct_name.capitalize
  end
end

class Rental
  attr_accessor :date, :book, :person

  def initialize(date, book, person)
    @date   = date
    @book   = book
    @person = person
    book.rentals   << self
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

  def add_student(stud)
    @students << stud unless @students.include?(stud)
    stud.classroom = self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id                = rand(1000)
    @name              = name.to_s
    @age               = age.to_i
    @parent_permission = parent_permission
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
    @age > 17
  end
end

class Student < Person
  attr_reader :classroom

  def initialize(age, classroom, name, parent_permission: true)
    super(name.to_s, age.to_i, parent_permission: parent_permission)
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

  def initialize(age, specialization, name)
    super(name.to_s, age.to_i)
    @specialization = specialization
  end

  def can_use_services?
    true
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
    else
      @books.each do |bk|
        puts "title: #{bk.title}, author: #{bk.author}"
      end
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
    else
      @people.each do |human|
        puts "[#{human.class}] id: #{human.id}, Name: #{human.name}, Age: #{human.age}"
      end
    end
  end

  def create_person
    print 'Student(1) or Teacher(2)? '
    choice = gets.chomp.strip
    case choice
    when '1'
      create_student
    when '2'
      create_teacher
    else
      puts 'Invalid choice. Please enter 1 for Student or 2 for Teacher.'
    end
  end

  def create_student
    print 'Name: '
    nm = gets.chomp.strip
    nm = 'Unknown' if nm.empty?

    print 'Age: '
    ag = gets.chomp.to_i
    ag = 0 if ag.negative?

    perm = nil
    until %w[Y N].include?(perm)
      print 'Parent permission? [Y/N]: '
      perm = gets.chomp.upcase.strip
      puts 'Invalid input. Please enter Y or N.' unless %w[Y N].include?(perm)
    end

    stu = Student.new(ag, nil, nm, parent_permission: perm == 'Y')
    @people << stu
    puts "Student #{stu.name} created with id: #{stu.id}"
  end

  def create_teacher
    print 'Name: '
    nm = gets.chomp.strip
    nm = 'Unknown' if nm.empty?

    print 'Age: '
    ag = gets.chomp.to_i
    ag = 0 if ag.negative?

    print 'Specialization: '
    spec = gets.chomp.strip

    t = Teacher.new(ag, spec, nm)
    @people << t
    puts "Teacher #{t.name} created with id: #{t.id}"
  end

  def create_book
    print 'Title: '
    t = gets.chomp.strip

    print 'Author: '
    a = gets.chomp.strip

    book = Book.new(t, a)
    @books << book
    puts "Book '#{book.title}' by #{book.author} created."
  end

  def create_rental
    if @books.empty?
      puts 'No books available. Please create a book first.'
      return
    end

    if @people.empty?
      puts 'No people registered. Please create a person first.'
      return
    end

    puts 'Select a book by index:'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title}" }
    bi = gets.chomp.to_i

    puts 'Select a person by index:'
    @people.each_with_index { |p, i| puts "#{i}: #{p.name}" }
    pi = gets.chomp.to_i

    unless valid_indices?(pi, bi)
      puts 'Invalid selection. Please choose valid indices.'
      return
    end

    Rental.new(Date.today.to_s, @books[bi], @people[pi])
    puts 'Rental created successfully.'
  end

  def list_rentals
    print 'ID of person: '
    pid = gets.chomp.to_i

    p_obj = @people.detect { |pr| pr.id == pid }

    if p_obj.nil?
      puts "No person found with id: #{pid}"
      return
    end

    if p_obj.rentals.empty?
      puts "#{p_obj.name} has no rentals."
    else
      p_obj.rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
    end
  end

  private

  def valid_indices?(p_i, b_i)
    p_i >= 0 && p_i < @people.length && b_i >= 0 && b_i < @books.size
  end
end