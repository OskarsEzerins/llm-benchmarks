class App
  def initialize
    @books = []
    @people = []
  end

  def list_books
    if @books.empty?
      puts 'No books available'
      return
    end

    @books.each do |bk|
      puts "Title: #{bk.title}, Author: #{bk.author}"
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
      return
    end

    @people.each do |human|
      puts "[#{human.class}] ID: #{human.id}, Name: #{human.name}, Age: #{human.age}"
    end
  end

  def create_person
    print 'Do you want to create a student (1) or a teacher (2)? [Input the number]: '
    choice = gets&.chomp

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
    nm = gets&.chomp
    nm = 'Unknown' if nm.nil? || nm.strip.empty?

    print 'Age: '
    ag = parse_age(gets)

    print 'Has parent permission? [Y/N]: '
    perm = parse_permission(gets)

    stu = Student.new(ag, nil, nm, parent_permission: perm)
    @people << stu
    stu
  end

  def create_teacher
    print 'Name: '
    nm = gets&.chomp
    nm = 'Unknown' if nm.nil? || nm.strip.empty?

    print 'Age: '
    ag = parse_age(gets)

    print 'Specialization: '
    spec = gets&.chomp
    spec = '' if spec.nil?

    t = Teacher.new(ag, spec, nm)
    @people << t
    t
  end

  def create_book
    print 'Title: '
    t = gets&.chomp
    t = '' if t.nil?

    print 'Author: '
    a = gets&.chomp
    a = '' if a.nil?

    book = Book.new(t, a)
    @books << book
    book
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'Books and people must exist to create a rental'
      return
    end

    puts 'Select a book from the following list by number'
    @books.each_with_index { |b, i| puts "#{i}) Title: #{b.title}, Author: #{b.author}" }
    bi = gets&.chomp.to_i

    puts 'Select a person from the following list by number (not id)'
    @people.each_with_index { |p, i| puts "#{i}) [#{p.class}] Name: #{p.name}, ID: #{p.id}, Age: #{p.age}" }
    pi = gets&.chomp.to_i

    unless valid_indices?(pi, bi)
      puts 'Invalid selection'
      return
    end

    print 'Date: '
    date = gets&.chomp
    date = Date.today.to_s if date.nil? || date.strip.empty?

    Rental.new(date, @books[bi], @people[pi])
  end

  def list_rentals
    print 'ID of person: '
    pid = gets&.chomp.to_i
    p_obj = @people.detect { |pr| pr.id == pid }

    return puts 'Person not found' unless p_obj

    if p_obj.rentals.empty?
      puts 'No rentals found for this person'
      return
    end

    p_obj.rentals.each { |r| puts "Date: #{r.date}, Book: #{r.book.title} by #{r.book.author}" }
  end

  private

  def valid_indices?(p_i, b_i)
    p_i >= 0 && p_i < @people.length && b_i >= 0 && b_i < @books.length
  end

  def parse_age(input)
    age = input&.chomp.to_i
    age.negative? ? 0 : age
  end

  def parse_permission(input)
    answer = input&.chomp&.strip&.upcase
    answer == 'Y'
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, 'Implement correct_name in subclass'
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
  attr_accessor :date, :book, :person

  def initialize(date, book, person)
    @date = date
    @book = book
    @person = person
    book.rentals << self unless book.rentals.include?(self)
    person.rentals << self unless person.rentals.include?(self)
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
    @students << stud unless @students.include?(stud)
    stud.classroom = self unless stud.classroom == self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals
  attr_reader :parent_permission

  def initialize(age, name = 'Unknown', parent_permission: true)
    @id = rand(1..1000)
    @name = (name.nil? || name.strip.empty? ? 'Unknown' : name)
    @age = age.to_i
    @parent_permission = !!parent_permission
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

  def initialize(age, classroom = nil, name = 'Unknown', parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom unless classroom.nil?
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

  def initialize(age, specialization, name = 'Unknown')
    super(age, name, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end