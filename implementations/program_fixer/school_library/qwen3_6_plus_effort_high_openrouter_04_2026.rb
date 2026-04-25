require 'date'

class Nameable
  def correct_name
    raise NotImplementedError, "#{self.class} must implement correct_name"
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
    super.capitalize
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

class Book
  attr_reader :title, :author, :rentals

  def initialize(title, author)
    @title = title&.strip || 'Unknown'
    @title = 'Unknown' if @title.empty?
    @author = author&.strip || 'Unknown'
    @author = 'Unknown' if @author.empty?
    @rentals = []
  end

  def add_rental(date, person)
    Rental.new(date, self, person)
  end
end

class Classroom
  attr_accessor :label, :students

  def initialize(label)
    @label = label&.strip || 'Unknown'
    @students = []
  end

  def add_student(student)
    @students << student unless @students.include?(student)
    student.classroom = self
  end
end

class Person < Nameable
  @@id_counter = 0

  attr_accessor :name, :age, :rentals
  attr_reader :id

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @@id_counter += 1
    @id = @@id_counter
    @name = name&.strip || 'Unknown'
    @name = 'Unknown' if @name.empty?
    @age = age.to_i.abs
    @parent_permission = !!parent_permission
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

  def initialize(age, classroom = nil, name = 'Unknown', parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @classroom = classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    return if room.nil?
    @classroom = room
    room.students << self unless room.students.include?(self)
  end

  def assign_classroom(classroom)
    self.classroom = classroom
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization = nil, name = 'Unknown')
    super(name, age)
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
    puts 'No books available' && return if @books.empty?
    @books.each do |bk|
      puts "Title: #{bk.title}, Author: #{bk.author}"
    end
  end

  def list_people
    puts 'No one has registered' && return if @people.empty?
    @people.each do |human|
      puts "[#{human.class}] ID: #{human.id}, Name: #{human.name}, Age: #{human.age}"
    end
  end

  def create_person
    print 'Student(2) or Teacher(1)? '
    choice = gets&.chomp&.strip
    case choice
    when '1' then create_teacher
    when '2', '3' then create_student
    else puts 'Invalid selection.'
    end
  end

  def create_student
    print 'Name: '
    nm = gets&.chomp&.strip
    nm = 'Unknown' if nm.nil? || nm.empty?

    print 'Age: '
    ag = gets&.to_i || 0
    ag = 0 if ag.negative?

    print 'Parent permission? [Y/N]: '
    perm = gets&.chomp&.upcase == 'Y'

    stu = Student.new(ag, nil, nm, parent_permission: perm)
    @people << stu
  end

  def create_teacher
    print 'Name: '
    nm = gets&.chomp&.strip
    nm = 'Unknown' if nm.nil? || nm.empty?

    print 'Age: '
    ag = gets&.to_i || 0
    ag = 0 if ag.negative?

    t = Teacher.new(ag, nil, nm)
    @people << t
  end

  def create_book
    print 'Title: '
    t = gets&.chomp&.strip || 'Unknown'
    print 'Author: '
    a = gets&.chomp&.strip || 'Unknown'
    @books << Book.new(t, a)
  end

  def create_rental
    puts 'Select a book by number:'
    return puts 'No books available.' if @books.empty?
    @books.each_with_index { |b, i| puts "#{i}: #{b.title}" }
    bi = gets&.to_i || -1

    puts 'Select a person by number:'
    return puts 'No people available.' if @people.empty?
    @people.each_with_index { |p, i| puts "#{i}: #{p.name}" }
    pi = gets&.to_i || -1

    unless valid_index?(bi, @books) && valid_index?(pi, @people)
      puts 'Invalid selection.'
      return
    end

    Rental.new(Date.today.to_s, @books[bi], @people[pi])
    puts 'Rental created.'
  end

  def list_rentals
    print 'ID of person: '
    pid = gets&.to_i
    p_obj = @people.find { |pr| pr.id == pid }
    return puts 'Person not found.' unless p_obj
    p_obj.rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
  end

  private

  def valid_index?(idx, collection)
    idx.is_a?(Integer) && idx >= 0 && idx < collection.length
  end
end