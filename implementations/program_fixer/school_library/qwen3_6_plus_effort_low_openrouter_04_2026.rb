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
        puts "title: #{bk.title}, author: #{bk.author}"
      end
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
    else
      @people.each do |human|
        puts "[#{human.class.name}] id: #{human.id}, Name: #{human.correct_name}, Age: #{human.age}"
      end
    end
  end

  def create_person
    print 'Type of person? (1) Teacher, (2) Student: '
    choice = gets.chomp
    case choice
    when '1'
      create_teacher
    when '2'
      create_student
    else
      puts 'Invalid selection.'
    end
  end

  def create_student
    print 'Name: '
    nm = gets.chomp
    print 'Age: '
    ag = gets.chomp.to_i
    print 'Parent permission? [Y/N]: '
    perm_input = gets.chomp
    perm = perm_input.upcase == 'Y'
    stu = Student.new(nm, ag, parent_permission: perm)
    @people << stu
  end

  def create_teacher
    print 'Name: '
    nm = gets.chomp
    print 'Age: '
    ag = gets.chomp.to_i
    print 'Specialization: '
    spec = gets.chomp
    t = Teacher.new(nm, spec, ag)
    @people << t
  end

  def create_book
    print 'Title: '
    t = gets.chomp
    print 'Author: '
    a = gets.chomp
    @books << Book.new(t, a)
  end

  def create_rental
    puts 'Select a book:'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title}" }
    bi = gets.chomp.to_i

    puts 'Select a person:'
    @people.each_with_index { |p, i| puts "#{i}: #{p.correct_name}" }
    pi = gets.chomp.to_i

    if valid_indices?(pi, bi)
      Rental.new(Date.today.to_s, @books[bi], @people[pi])
      puts 'Rental created successfully.'
    else
      puts 'Invalid index.'
    end
  end

  def list_rentals
    print 'ID of person: '
    pid = gets.chomp.to_i
    p_obj = @people.find { |pr| pr.id == pid }
    if p_obj.nil? || p_obj.rentals.empty?
      puts 'No rentals found for this person.'
    else
      p_obj.rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
    end
  end

  private

  def valid_indices?(pi, bi)
    pi >= 0 && pi < @people.length && bi >= 0 && bi < @books.length
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, "Method not implemented"
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
    super.capitalize
  end
end

class Rental
  attr_accessor :date, :book, :person

  def initialize(date, book, person)
    @date = date
    @book = book
    @person = person
    @book.rentals << self
    @person.rentals << self
  end
end

class Book
  attr_accessor :title, :author, :rentals

  def initialize(title, author)
    @title = title
    @author = author
    @rentals = []
  end

  def add_rental(date, person)
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
    @students << stud unless @students.include?(stud)
    stud.assign_classroom(self)
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals

  @@next_id = 1

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id = @@next_id
    @@next_id += 1
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

  private

  def of_age?
    @age >= 18
  end
end

class Student < Person
  attr_reader :classroom

  def initialize(name, age, parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @classroom = nil
  end

  def assign_classroom(room)
    @classroom = room
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