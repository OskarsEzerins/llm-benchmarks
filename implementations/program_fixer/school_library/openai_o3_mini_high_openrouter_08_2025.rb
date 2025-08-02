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
    print 'Do you want to create a Teacher (1) or a Student (2)? '
    choice = gets.chomp
    case choice
    when '1'
      create_teacher
    when '2'
      create_student
    else
      puts 'Invalid selection'
    end
  end

  def create_student
    print 'Name: '
    nm = gets.chomp
    nm = 'Unknown' if nm.strip.empty?
    print 'Age: '
    ag = gets.chomp.to_i
    print 'Parent permission? (Y/N): '
    perm = gets.chomp.upcase
    until %w[Y N].include?(perm)
      print 'Please type Y or N: '
      perm = gets.chomp.upcase
    end
    stu = Student.new(ag, nil, nm, parent_permission: (perm == 'Y'))
    @people << stu
    puts "Student created with ID: #{stu.id}"
  end

  def create_teacher
    print 'Name: '
    nm = gets.chomp
    nm = 'Unknown' if nm.strip.empty?
    print 'Age: '
    ag = gets.chomp.to_i
    print 'Specialization: '
    spec = gets.chomp
    spec = 'Unknown' if spec.strip.empty?
    t = Teacher.new(ag, spec, nm)
    @people << t
    puts "Teacher created with ID: #{t.id}"
  end

  def create_book
    print 'Title: '
    t = gets.chomp
    t = 'Untitled' if t.strip.empty?
    print 'Author: '
    a = gets.chomp
    a = 'Unknown' if a.strip.empty?
    book = Book.new(t, a)
    @books << book
    puts "Book created: #{book.title} by #{book.author}"
  end

  def create_rental
    if @books.empty?
      puts 'No books available to rent.'
      return
    end
    if @people.empty?
      puts 'No people available.'
      return
    end
    puts 'Select a book:'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title}" }
    bi = gets.chomp.to_i
    if bi < 0 || bi >= @books.length
      puts 'Invalid book selection.'
      return
    end

    puts 'Select a person:'
    @people.each_with_index { |p, i| puts "#{i}: #{p.name} (ID: #{p.id})" }
    pi = gets.chomp.to_i
    if pi < 0 || pi >= @people.length
      puts 'Invalid person selection.'
      return
    end

    print 'Date (YYYY-MM-DD): '
    date = gets.chomp
    rental = Rental.new(date, @books[bi], @people[pi])
    puts 'Rental created successfully.'
  end

  def list_rentals
    print 'ID of person: '
    pid = gets.chomp.to_i
    p_obj = @people.find { |pr| pr.id == pid }
    if p_obj.nil?
      puts 'Person not found.'
    elsif p_obj.rentals.empty?
      puts 'No rentals for this person.'
    else
      p_obj.rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
    end
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, 'Subclass must implement correct_name method'
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
    super[0, 10]
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
    @date   = date
    @book   = book
    @person = person
    book.rentals << self
    person.rentals << self
  end
end

class Book
  attr_reader :title, :author
  attr_accessor :rentals

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

  def add_student(student)
    @students << student unless @students.include?(student)
    student.classroom = self
  end
end

class Person < Nameable
  attr_reader :id, :rentals
  attr_accessor :name, :age

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
    assign_classroom(classroom) if classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    @classroom = room
    room.students << self unless room.students.include?(self)
  end

  def assign_classroom(room)
    self.classroom = room
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name)
    super(name, age)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end