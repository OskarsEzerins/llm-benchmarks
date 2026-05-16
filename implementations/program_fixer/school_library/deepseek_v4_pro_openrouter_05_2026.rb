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
      @books.each do |bk|
        puts "Title: #{bk.title}, Author: #{bk.author}"
      end
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
    else
      @people.each do |human|
        puts "[#{human.class}] ID: #{human.id}, Name: #{human.name}, Age: #{human.age}"
      end
    end
  end

  def create_person
    print 'Do you want to create a student (1) or a teacher (2)? [Input the number]: '
    choice = gets.chomp
    case choice
    when '1'
      create_student
    when '2'
      create_teacher
    else
      puts 'Invalid option'
    end
  end

  def create_student
    print 'Name: '
    nm = gets.chomp
    nm = 'Unknown' if nm.empty?
    print 'Age: '
    ag = gets.chomp.to_i
    ag = 18 if ag <= 0
    print 'Parent permission? [Y/N]: '
    perm = gets.chomp.upcase
    parent_permission = perm == 'Y'
    stu = Student.new(ag, nil, nm, parent_permission: parent_permission)
    @people << stu
    puts 'Student created successfully.'
  end

  def create_teacher
    print 'Name: '
    nm = gets.chomp
    nm = 'Unknown' if nm.empty?
    print 'Age: '
    ag = gets.chomp.to_i
    ag = 18 if ag <= 0
    print 'Specialization: '
    spec = gets.chomp
    spec = 'Unknown' if spec.empty?
    t = Teacher.new(ag, spec, nm)
    @people << t
    puts 'Teacher created successfully.'
  end

  def create_book
    print 'Title: '
    t = gets.chomp
    print 'Author: '
    a = gets.chomp
    book = Book.new(t, a)
    @books << book
    puts 'Book created successfully.'
  end

  def create_rental
    if @books.empty?
      puts 'No books available to rent.'
      return
    end
    if @people.empty?
      puts 'No people registered.'
      return
    end

    puts 'Select a book from the following list by number:'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title}" }
    bi = gets.chomp.to_i

    puts 'Select a person from the following list by number:'
    @people.each_with_index { |p, i| puts "#{i}: #{p.name}" }
    pi = gets.chomp.to_i

    unless valid_indices?(pi, bi)
      puts 'Invalid selection. Rental not created.'
      return
    end

    rental = Rental.new(Date.today.to_s, @books[bi], @people[pi])
    puts 'Rental created successfully.'
  end

  def list_rentals
    print 'ID of person: '
    pid = gets.chomp.to_i
    person = @people.find { |pr| pr.id == pid }
    if person
      if person.rentals.empty?
        puts 'No rentals found for this person.'
      else
        person.rentals.each do |r|
          puts "#{r.date} - #{r.book.title}"
        end
      end
    else
      puts 'Person not found.'
    end
  end

  private

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
    @nameable.correct_name.capitalize
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

  def add_student(stud)
    stud.classroom = self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id = rand(1000..9999)
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

  def initialize(age, classroom, name, parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom if classroom
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

  def initialize(age, specialization, name = 'Unknown', parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end