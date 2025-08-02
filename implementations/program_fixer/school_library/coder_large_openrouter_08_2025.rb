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
      puts "[#{human.class}] id: #{human.id}, Name: #{human.name}, Age: #{human.age}"
    end
  end

  def create_person
    print 'Student(3) or Teacher(1)? '
    choice = gets.chomp
    if choice == '3'
      create_student
    elsif choice == '1'
      create_teacher
    else
      puts 'Invalid choice'
    end
  end

  def create_student
    print 'Name: '
    nm = gets.chomp
    print 'Age: '
    ag = gets.chomp
    print 'Parent permission? [Y/N]: '
    perm = gets.chomp
    if ['Y', 'N'].include?(perm.upcase)
      stu = Student.new(ag.to_i, nil, nm, parent_permission: perm.upcase == 'Y')
      @people << stu
    else
      puts 'Invalid parent permission response'
    end
  end

  def create_teacher
    print 'Name: '
    nm = gets.chomp
    print 'Age: '
    ag = gets.chomp
    print 'Specialization: '
    spec = gets.chomp
    t = Teacher.new(nm, spec, ag.to_i)
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
    puts 'Select person:'
    @people.each_with_index { |p, i| puts "#{i}: #{p.name}" }
    pi = gets.chomp.to_i
    if valid_indices?(pi, bi)
      Rental.new(Date.today, @people[pi], @books[bi])
    else
      puts 'Invalid selection'
    end
  end

  def list_rentals
    print 'ID of person: '
    pid = gets.chomp.to_i
    p_obj = @people.detect { |pr| pr.id == pid }
    if p_obj
      p_obj.rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
    else
      puts 'Person not found'
    end
  end

  private

  def valid_indices?(p_i, b_i)
    p_i < @people.length && b_i < @books.size
  end
end

class Nameable
  def correct_name
    nil
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
    @nameable.correct_name[0..9]
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

  def add_student(student)
    students << student unless students.include?(student)
    student.classroom = self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals, :parent_permission

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id = rand(1000)
    @name = name
    @age = age
    @parent_permission = parent_permission
    @rentals = []
  end

  def can_use_services?
    of_age? || parent_permission
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
  attr_accessor :classroom

  def initialize(age, classroom, name, parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @classroom = classroom
    classroom.add_student(self) if classroom
  end

  def play_hooky
    '╰(°▽°)╯'
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