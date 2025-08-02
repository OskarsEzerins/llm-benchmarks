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
    print 'Student(3) or Teacher(1)? [Enter the number]: '
    choice = gets.chomp
    case choice
    when '1'
      create_teacher
    when '3'
      create_student
    else
      puts 'Invalid choice. Please enter 1 for Teacher or 3 for Student.'
    end
  end

  def create_student
    print 'Name: '
    nm = gets.chomp
    while nm.strip.empty?
      print 'Name cannot be empty. Please enter a valid name: '
      nm = gets.chomp
    end

    print 'Age: '
    ag = gets.chomp.to_i
    while ag <= 0
      print 'Age must be a positive number. Please enter a valid age: '
      ag = gets.chomp.to_i
    end

    print 'Parent permission? [Y/N]: '
    perm = gets.chomp.upcase
    until ['Y', 'N'].include?(perm)
      print 'Please enter Y or N: '
      perm = gets.chomp.upcase
    end

    stu = Student.new(ag, nil, nm, parent_permission: perm == 'Y')
    @people << stu
    puts 'Student created successfully.'
  end

  def create_teacher
    print 'Name: '
    nm = gets.chomp
    while nm.strip.empty?
      print 'Name cannot be empty. Please enter a valid name: '
      nm = gets.chomp
    end

    print 'Age: '
    ag = gets.chomp.to_i
    while ag <= 0
      print 'Age must be a positive number. Please enter a valid age: '
      ag = gets.chomp.to_i
    end

    print 'Specialization: '
    spec = gets.chomp
    while spec.strip.empty?
      print 'Specialization cannot be empty. Please enter a valid specialization: '
      spec = gets.chomp
    end

    t = Teacher.new(nm, spec, ag)
    @people << t
    puts 'Teacher created successfully.'
  end

  def create_book
    print 'Title: '
    t = gets.chomp
    while t.strip.empty?
      print 'Title cannot be empty. Please enter a valid title: '
      t = gets.chomp
    end

    print 'Author: '
    a = gets.chomp
    while a.strip.empty?
      print 'Author cannot be empty. Please enter a valid author: '
      a = gets.chomp
    end

    @books << Book.new(t, a)
    puts 'Book created successfully.'
  end

  def create_rental
    if @books.empty?
      puts 'No books available to rent. Please add books first.'
      return
    end

    if @people.empty?
      puts 'No people available to rent books. Please add people first.'
      return
    end

    puts 'Select a book by number'
    @books.each_with_index { |b, i| puts "#{i}) Title: #{b.title}, Author: #{b.author}" }
    bi = gets.chomp.to_i
    until bi.between?(0, @books.length - 1)
      print 'Invalid book number. Please select a valid book: '
      bi = gets.chomp.to_i
    end

    puts 'Select a person by number'
    @people.each_with_index do |p, i|
      puts "#{i}) [#{p.class}] Name: #{p.name}, ID: #{p.id}, Age: #{p.age}"
    end
    pi = gets.chomp.to_i
    until pi.between?(0, @people.length - 1)
      print 'Invalid person number. Please select a valid person: '
      pi = gets.chomp.to_i
    end

    print 'Date (YYYY-MM-DD): '
    date = gets.chomp
    while date.strip.empty?
      print 'Date cannot be empty. Please enter a valid date: '
      date = gets.chomp
    end

    Rental.new(date, @books[bi], @people[pi])
    puts 'Rental created successfully.'
  end

  def list_rentals
    print 'ID of person: '
    pid = gets.chomp.to_i
    p_obj = @people.detect { |pr| pr.id == pid }
    if p_obj
      if p_obj.rentals.empty?
        puts 'No rentals found for this person.'
      else
        p_obj.rentals.each { |r| puts "#{r.date} - #{r.book.title} by #{r.book.author}" }
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
    raise NotImplementedError, 'Subclasses must implement the correct_name method'
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

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id                 = rand(1000)
    @name               = name
    @age                = age
    @parent_permission  = parent_permission
    @rentals            = []
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
    @classroom = classroom
    classroom.add_student(self) if classroom
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
    super(name, age, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end