require 'date'

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
    puts 'No one has registered' unless @people.any?
    @people.each do |human|
      puts "[#{human.class}] id: #{human.id}, Name: #{human.name}, Age: #{human.age}"
    end
  end

  def create_person
    print 'Student(3) or Teacher(1)? '
    choice = gets.chomp
    case choice
    when '3'
      create_student
    when '1'
      create_teacher
    else
      puts 'Invalid selection'
    end
  end

  def create_student
    print 'Name: '
    nm = gets.chomp
    nm = 'Unknown' if nm.nil? || nm.strip.empty?
    print 'Age: '
    ag = gets.chomp
    ag = 0 if ag.nil? || ag.strip.empty?
    age = ag.to_i
    age = 0 if age < 0
    print 'Parent permission? (Y/N): '
    perm = gets.chomp
    parent_permission = case perm.upcase
                         when 'Y' then true
                         when 'N' then false
                         else
                           false
                         end
    stu = Student.new(age, nil, nm, parent_permission: parent_permission)
    @people.push(stu)
  end

  def create_teacher
    print 'Name: '
    nm = gets.chomp
    nm = 'Unknown' if nm.nil? || nm.strip.empty?
    print 'Age: '
    ag = gets.chomp
    ag = 0 if ag.nil? || ag.strip.empty?
    age = ag.to_i
    age = 0 if age < 0
    print 'Specialization: '
    spec = gets.chomp
    t = Teacher.new(age, spec, nm)
    @people.push(t)
  end

  def create_book
    print 'Title: '
    t = gets.chomp
    t = 'Unknown' if t.nil? || t.strip.empty?
    print 'Author: '
    a = gets.chomp
    a = 'Unknown' if a.nil? || a.strip.empty?
    @books.push(Book.new(t, a))
  end

  def create_rental
    puts 'Select a book'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title}" }
    bi = gets.chomp.to_i
    puts 'Select person'
    @people.each_with_index { |p, i| puts "#{i}: #{p.name}" }
    pi = gets.chomp.to_i
    
    unless valid_indices?(pi, bi)
      puts 'Invalid selection'
      return
    end
    
    print 'Date (YYYY-MM-DD): '
    date_str = gets.chomp
    date = Date.today
    begin
      date = Date.parse(date_str) unless date_str.empty?
    rescue
      date = Date.today
    end
    
    Rental.new(date, @books[bi], @people[pi])
  end

  def list_rentals
    print 'ID of person: '
    pid = gets.chomp.to_i
    p_obj = @people.find { |pr| pr.id == pid }
    if p_obj.nil?
      puts 'Person not found'
      return
    end
    p_obj.rentals.each { |r| puts "#{r.date} - #{r.book.title} by #{r.book.author}" }
  end

  private

  def valid_indices?(p_i, b_i)
    p_i >= 0 && p_i < @people.length && b_i >= 0 && b_i < @books.length
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, "#{self.class} has not implemented method 'correct_name'"
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
  attr_reader :date, :book, :person

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
    @students << stud
    stud.classroom = self unless stud.classroom == self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals, :parent_permission

  def initialize(age = 0, name = 'Unknown', parent_permission: true)
    @id = rand(1_000_000)
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
    super(age, name, parent_permission: parent_permission)
    @classroom = classroom
    classroom.add_student(self) unless classroom.nil?
  end

  def play_hooky
    '╰(°)╯'
  end

  def classroom=(room)
    @classroom = room
    room.students << self unless room.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name)
    super(age, name, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end