class App
  def initialize
    @books = []
    @people = []
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
      puts "[#{human.class}] id: #{human.id}, Name: #{human.correct_name}, Age: #{human.age}"
    end
  end

  def create_person
    print 'Student(3) or Teacher(1)? '
    choice = gets.chomp
    create_teacher if choice == '1'
    create_student if choice == '3'
  end

  def create_student
    print 'Name: '
    nm = gets.chomp
    raise 'Name cannot be empty' if nm.empty?
    print 'Age: '
    ag = gets.to_i
    raise 'Invalid age' if ag < 0
    print 'Parent permission? (Y/N) '
    perm = gets.chomp.upcase
    raise 'Invalid input, must be Y or N' unless ['Y', 'N'].include?(perm)
    stu = Student.new(ag, nil, nm, parent_permission: perm == 'Y')
    @people << stu
  end

  def create_teacher
    print 'Name: '
    nm = gets.chomp
    raise 'Name cannot be empty' if nm.empty?
    print 'Age: '
    ag = gets.to_i
    raise 'Invalid age' if ag < 0
    print 'Specialization: '
    spec = gets.chomp
    t = Teacher.new(nm, spec, ag)
    @people << t
  end

  def create_book
    print 'Title: '
    t = gets.chomp
    raise 'Title cannot be empty' if t.empty?
    print 'Author: '
    a = gets.chomp
    raise 'Author cannot be empty' if a.empty?
    @books << Book.new(t, a)
  end

  def create_rental
    puts 'Select a book'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title}" }
    bi = gets.to_i
    raise 'Invalid book selection' if bi < 0 || bi >= @books.size
    puts 'Select person'
    @people.each_with_index { |p, i| puts "#{i}: #{p.correct_name}" }
    pi = gets.to_i
    raise 'Invalid person selection' if pi < 0 || pi >= @people.size
    Rental.new(Date.today.to_s, @people[pi], @books[bi])
  end

  def list_rentals
    print 'ID of person: '
    pid = gets.to_i
    p_obj = @people.detect { |pr| pr.id == pid }
    raise 'Person not found' if p_obj.nil?
    p_obj.rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
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

  def initialize(date, person, book)
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
    Rental.new(date, person, self)
  end
end

class Classroom
  attr_accessor :label, :students

  def initialize(label)
    @label = label
    @students = []
  end

  def add_student(stud)
    students << stud
    stud.classroom = self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id = rand(1000)
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
    Rental.new(date, self, book)
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
    @classroom = classroom
    classroom.students << self if classroom
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

  def initialize(name, specialization, age = 0)
    super(name, age)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end