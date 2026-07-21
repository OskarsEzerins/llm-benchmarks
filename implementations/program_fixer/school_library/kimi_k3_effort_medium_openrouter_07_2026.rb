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
    puts 'No one has registered' unless @people.any?
    @people.each do |human|
      puts "[#{human.class}] id: #{human.id}, Name: #{human.name}, Age: #{human.age}"
    end
  end

  def create_person
    print 'Student(3) or Teacher(1)? '
    choice = gets.to_s.chomp
    if choice == '1'
      create_teacher
    elsif choice == '3'
      create_student
    else
      puts 'Invalid option'
    end
  end

  def create_student
    print 'Name: '
    nm = gets.to_s.chomp
    nm = 'Unknown' if nm.empty?
    print 'Age: '
    ag = valid_age(gets.to_s.chomp)
    print 'Parent permission? [Y/N]: '
    perm = gets.to_s.chomp.upcase
    perm = 'N' unless %w[Y N].include?(perm)
    stu = Student.new(ag, nil, nm, parent_permission: perm == 'Y')
    @people << stu
    stu
  end

  def create_teacher
    print 'Name: '
    nm = gets.to_s.chomp
    nm = 'Unknown' if nm.empty?
    print 'Age: '
    ag = valid_age(gets.to_s.chomp)
    print 'Specialization: '
    spec = gets.to_s.chomp
    t = Teacher.new(ag, spec, nm)
    @people << t
    t
  end

  def create_book
    print 'Title: '
    t = gets.to_s.chomp
    print 'Author: '
    a = gets.to_s.chomp
    book = Book.new(t, a)
    @books << book
    book
  end

  def create_rental
    puts 'Select a book'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title}" }
    bi = gets.to_i
    puts 'Select person'
    @people.each_with_index { |p, i| puts "#{i}: #{p.name}" }
    pi = gets.to_i
    return puts 'Invalid selection' unless valid_indices?(pi, bi)

    Rental.new(Time.now.strftime('%Y-%m-%d'), @books[bi], @people[pi])
  end

  def list_rentals
    print 'ID of person: '
    pid = gets.to_i
    p_obj = @people.detect { |pr| pr.id == pid }
    return puts 'Person not found' unless p_obj

    p_obj.rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
  end

  private

  def valid_age(input)
    age = Integer(input, exception: false)
    return 0 if age.nil? || age.negative?

    age
  end

  def valid_indices?(p_i, b_i)
    p_i >= 0 && b_i >= 0 && p_i < @people.length && b_i < @books.length
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
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
    @nameable.correct_name.capitalize
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
  attr_accessor :id, :name, :age, :rentals, :parent_permission

  def initialize(age, name = 'Unknown', parent_permission: true)
    super()
    @id = rand(1..1000)
    @name = name.to_s.empty? ? 'Unknown' : name
    @age = age.to_i
    @parent_permission = parent_permission == true
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
    self.classroom = classroom if classroom
  end

  def play_hooky
    '¯\\_(ツ)_/¯'
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