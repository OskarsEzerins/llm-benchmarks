class App
  def initialize
    @books  = []
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
      puts "[#{human.class}] id: #{human.id}, Name: #{human.name}, Age: #{human.age}"
    end
  end

  def create_person
    print 'Student(1) or Teacher(2)? '
    choice = gets.chomp
    if choice == '1'
      create_student
    elsif choice == '2'
      create_teacher
    else
      puts 'Invalid choice'
    end
  end

  def create_student
    print 'Name: '
    nm = gets.chomp
    print 'Age: '
    ag = gets.chomp.to_i
    print 'Parent permission? (Y/N) '
    perm = gets.chomp
    stu = Student.new(ag, nil, nm, parent_permission: perm == 'Y')
    @people << stu
  end

  def create_teacher
    print 'Name: '
    nm = gets.chomp
    print 'Age: '
    ag = gets.chomp.to_i
    print 'Specialization: '
    spec = gets.chomp
    t = Teacher.new(ag, spec, nm)
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
    return puts 'No books available' if @books.empty?
    return puts 'No people available' if @people.empty?
    
    puts 'Select a book'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title}" }
    bi = gets.chomp.to_i
    
    puts 'Select person'
    @people.each_with_index { |p, i| puts "#{i}: #{p.name}" }
    pi = gets.chomp.to_i
    
    return puts 'Invalid selection' unless valid_indices?(pi, bi)
    
    print 'Date: '
    date = gets.chomp
    Rental.new(date, @books[bi], @people[pi])
  end

  def list_rentals
    print 'ID of person: '
    pid = gets.chomp.to_i
    p_obj = @people.detect { |pr| pr.id == pid }
    return puts 'Person not found' unless p_obj
    
    if p_obj.rentals.empty?
      puts 'No rentals for this person'
    else
      p_obj.rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
    end
  end

  private

  def valid_indices?(p_i, b_i)
    p_i >= 0 && p_i < @people.length && b_i >= 0 && b_i < @books.length
  end
end

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
    super.capitalize
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

class Book
  attr_accessor :title, :author, :rentals

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
    @students << stud unless @students.include?(stud)
    stud.classroom = self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals

  def initialize(age, name = 'Unknown', parent_permission: true)
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
  attr_accessor :classroom

  def initialize(age, classroom, name = 'Unknown', parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    @classroom = classroom
    classroom.students << self if classroom
  end

  def play_hooky
    '¯\(°_o)/¯'
  end

  def classroom=(room)
    @classroom = room
    room.students << self unless room.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name = 'Unknown')
    super(age, name, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end