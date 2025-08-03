class App
  def initialize
    @books = []
    @people = []
    @rentals = []
  end

  def list_books
    if @books.empty?
      puts 'No books available'
      return
    end
    @books.each do |bk|
      puts "title: #{bk.title}, author: #{bk.author}"
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
      return
    end
    @people.each do |human|
      puts "[#{human.class}] id: #{human.id}, Name: #{human.name}, Age: #{human.age}"
    end
  end

  def create_person
    print 'Student(1) or Teacher(2)? '
    choice = (gets || '').chomp
    case choice
    when '1'
      create_student
    when '2'
      create_teacher
    else
      puts 'Invalid selection'
    end
  end

  def create_student
    print 'Name: '
    nm = (gets || '').chomp
    nm = 'Unknown' if nm.nil? || nm.strip.empty?
    print 'Age: '
    ag_input = (gets || '').chomp
    ag = ag_input.to_i
    ag = 0 if ag.negative?
    parent_permission = nil
    until [true, false].include?(parent_permission)
      print 'Parent permission? [Y/N]: '
      perm = (gets || '').chomp.upcase
      parent_permission = true if perm == 'Y'
      parent_permission = false if perm == 'N'
      puts 'Please enter Y or N' if parent_permission.nil?
    end
    stu = Student.new(ag, nil, nm, parent_permission: parent_permission)
    @people << stu
    puts 'Student created'
  end

  def create_teacher
    print 'Name: '
    nm = (gets || '').chomp
    nm = 'Unknown' if nm.nil? || nm.strip.empty?
    print 'Age: '
    ag_input = (gets || '').chomp
    ag = ag_input.to_i
    ag = 0 if ag.negative?
    print 'Specialization: '
    spec = (gets || '').chomp
    t = Teacher.new(ag, spec, nm)
    @people << t
    puts 'Teacher created'
  end

  def create_book
    print 'Title: '
    t = (gets || '').chomp
    t = 'Untitled' if t.nil? || t.strip.empty?
    print 'Author: '
    a = (gets || '').chomp
    a = 'Unknown' if a.nil? || a.strip.empty?
    @books << Book.new(t, a)
    puts 'Book created'
  end

  def create_rental
    if @books.empty?
      puts 'No books available'
      return
    end
    if @people.empty?
      puts 'No people available'
      return
    end
    puts 'Select a book by number'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title} by #{b.author}" }
    bi = (gets || '').chomp.to_i
    unless bi.between?(0, @books.length - 1)
      puts 'Invalid book selection'
      return
    end
    puts 'Select a person by number'
    @people.each_with_index { |p, i| puts "#{i}: [#{p.class}] Name: #{p.name}, ID: #{p.id}, Age: #{p.age}" }
    pi = (gets || '').chomp.to_i
    unless pi.between?(0, @people.length - 1)
      puts 'Invalid person selection'
      return
    end
    print 'Date (YYYY-MM-DD): '
    date = (gets || '').chomp
    date = Date.today.to_s if date.nil? || date.strip.empty?
    rental = Rental.new(date, @books[bi], @people[pi])
    @rentals << rental
    puts 'Rental created'
  end

  def list_rentals
    print 'ID of person: '
    pid_input = (gets || '').chomp
    pid = pid_input.to_i
    person = @people.find { |pr| pr.id == pid }
    if person.nil?
      puts 'Person not found'
      return
    end
    if person.rentals.empty?
      puts 'No rentals for this person'
      return
    end
    person.rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
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
    name = super
    name.length > 10 ? name[0, 10] : name
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
  attr_reader :title, :author, :rentals

  def initialize(t, a)
    @title = t
    @author = a
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
    stud.classroom = self
  end
end

class Person < Nameable
  attr_reader :id, :age
  attr_accessor :name, :rentals

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id = rand(1..1000)
    @name = name.nil? || name.strip.empty? ? 'Unknown' : name
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

  def initialize(age, classroom, name, parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    self.classroom = classroom if classroom
  end

  def play_hooky
    '¯(ツ)/¯'
  end

  def classroom=(room)
    @classroom = room
    return if room.nil?

    room.students << self unless room.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name = 'Unknown')
    super(name, age, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end