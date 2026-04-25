class App
  def initialize
    @books = []
    @people = []
  end

  def list_books
    puts 'No books available' if @books.empty?
    @books.each do |bk|
      puts "Title: #{bk.title}, Author: #{bk.author}"
    end
  end

  def list_people
    puts 'No one has registered' unless @people.any?
    @people.each do |human|
      puts "[#{human.class}] ID: #{human.id}, Name: #{human.name}, Age: #{human.age}"
    end
  end

  def create_person
    print 'Student(1) or Teacher(2)? '
    choice = gets.chomp
    create_student if choice == '1'
    create_teacher if choice == '2'
  end

  def create_student
    print 'Name: '
    nm = gets.chomp
    nm = 'Unknown' if nm.nil? || nm.empty?
    print 'Age: '
    ag = gets.chomp.to_i
    ag = 0 if ag.negative?
    print 'Parent permission? [Y/N]: '
    perm = gets.chomp.upcase
    parent_perm = perm == 'Y'
    stu = Student.new(ag, nil, nm, parent_permission: parent_perm)
    @people << stu
  end

  def create_teacher
    print 'Name: '
    nm = gets.chomp
    nm = 'Unknown' if nm.nil? || nm.empty?
    print 'Age: '
    ag = gets.chomp.to_i
    ag = 0 if ag.negative?
    print 'Specialization: '
    spec = gets.chomp
    spec = 'Unknown' if spec.nil? || spec.empty?
    t = Teacher.new(ag, spec, nm)
    @people << t
  end

  def create_book
    print 'Title: '
    t = gets.chomp
    t = 'Unknown' if t.nil? || t.empty?
    print 'Author: '
    a = gets.chomp
    a = 'Unknown' if a.nil? || a.empty?
    @books << Book.new(t, a)
  end

  def create_rental
    puts 'Select a book'
    @books.each_with_index { |b, i| puts "#{i}) #{b.title}" }
    bi = gets.chomp.to_i
    return puts 'Invalid book selection' unless bi.between?(0, @books.length - 1)
    puts 'Select a person'
    @people.each_with_index { |p, i| puts "#{i}) [#{p.class}] Name: #{p.name}, ID: #{p.id}, Age: #{p.age}" }
    pi = gets.chomp.to_i
    return puts 'Invalid person selection' unless pi.between?(0, @people.length - 1)
    print 'Date: '
    date = gets.chomp
    date = Date.today.to_s if date.nil? || date.empty?
    Rental.new(date, @books[bi], @people[pi])
  end

  def list_rentals
    print 'ID of person: '
    pid = gets.chomp.to_i
    p_obj = @people.detect { |pr| pr.id == pid }
    return puts 'Person not found' unless p_obj
    puts 'Rentals:'
    p_obj.rentals.each { |r| puts "Date: #{r.date}, Book: #{r.book.title} by #{r.book.author}" }
  end

  private

  def valid_indices?(p_i, b_i)
    p_i < @people.length && b_i < @books.length && p_i >= 0 && b_i >= 0
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, 'Subclasses must implement correct_name'
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
    name = super
    name.length > 10 ? name[0..9] : name
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
    return if students.include?(student)
    students << student
    student.classroom = self
  end
end

class Person < Nameable
  attr_accessor :name, :age, :rentals
  attr_reader :id

  def initialize(age, name = 'Unknown', parent_permission: true)
    super()
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

  def initialize(age, classroom, name = 'Unknown', parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    @classroom = classroom
    classroom&.add_student(self)
  end

  def play_hooky
    '¯\(ツ)/¯'
  end

  def classroom=(room)
    return if @classroom == room
    @classroom&.students&.delete(self)
    @classroom = room
    room&.students&.push(self) unless room&.students&.include?(self)
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