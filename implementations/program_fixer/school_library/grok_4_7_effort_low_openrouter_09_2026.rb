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
    print 'Student(1) or Teacher(2)? '
    choice = safe_gets
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
    nm = safe_gets
    if nm.empty?
      puts 'Invalid name'
      return
    end

    print 'Age: '
    ag = parse_age(safe_gets)
    if ag.nil?
      puts 'Invalid age'
      return
    end

    print 'Parent permission? [Y/N]: '
    perm = safe_gets.upcase
    unless %w[Y N].include?(perm)
      puts 'Invalid permission'
      return
    end

    stu = Student.new(ag, nil, nm, parent_permission: perm == 'Y')
    @people << stu
  end

  def create_teacher
    print 'Name: '
    nm = safe_gets
    if nm.empty?
      puts 'Invalid name'
      return
    end

    print 'Age: '
    ag = parse_age(safe_gets)
    if ag.nil?
      puts 'Invalid age'
      return
    end

    print 'Specialization: '
    spec = safe_gets
    spec = 'Unknown' if spec.empty?
    t = Teacher.new(ag, spec, nm)
    @people << t
  end

  def create_book
    print 'Title: '
    t = safe_gets
    print 'Author: '
    a = safe_gets
    t = 'Unknown' if t.empty?
    a = 'Unknown' if a.empty?
    @books << Book.new(t, a)
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'No books or people available'
      return
    end

    puts 'Select a book'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title}" }
    bi = safe_gets.to_i

    puts 'Select person'
    @people.each_with_index { |p, i| puts "#{i}: #{p.name}" }
    pi = safe_gets.to_i

    unless valid_indices?(pi, bi)
      puts 'Invalid selection'
      return
    end

    print 'Date: '
    date = safe_gets
    date = 'Unknown' if date.empty?
    Rental.new(date, @books[bi], @people[pi])
  end

  def list_rentals
    print 'ID of person: '
    pid = safe_gets.to_i
    p_obj = @people.detect { |pr| pr.id == pid }
    if p_obj.nil?
      puts 'Person not found'
      return
    end
    p_obj.rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
  end

  private

  def safe_gets
    input = gets
    input.nil? ? '' : input.chomp.strip
  end

  def parse_age(value)
    return nil unless value.match?(/\A\d+\z/)

    age = value.to_i
    return nil if age.negative?

    age
  end

  def valid_indices?(p_i, b_i)
    p_i.is_a?(Integer) && b_i.is_a?(Integer) &&
      p_i >= 0 && p_i < @people.length &&
      b_i >= 0 && b_i < @books.length
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end
end

class Decorator < Nameable
  attr_accessor :nameable

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
    name.length > 10 ? name[0, 10] : name
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

  def add_student(stud)
    @students << stud unless @students.include?(stud)
    stud.classroom = self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals
  attr_reader :parent_permission

  def initialize(age, name = 'Unknown', parent_permission: true)
    super()
    @id = Random.rand(1..1000)
    @name = name.nil? || name.to_s.empty? ? 'Unknown' : name.to_s
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
    @classroom = classroom
    return if classroom.nil?

    classroom.students << self unless classroom.students.include?(self)
  end

  def play_hooky
    '¯\(ツ)/¯'
  end

  def classroom=(room)
    @classroom = room
    return if room.nil?

    room.students << self unless room.students.include?(self)
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