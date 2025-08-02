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
        puts "[#{human.class}] id: #{human.id}, Name: #{human.full_name}, Age: #{human.age}"
      end
    end
  end

  def create_person
    print 'Student(3) or Teacher(2)? '
    choice = gets.chomp
    case choice
    when '2'
      create_teacher
    when '3'
      create_student
    else
      puts 'Invalid choice'
    end
  end

  def create_student
    print 'Name: '
    nm = gets.chomp
    print 'Age: '
    ag_input = gets.chomp
    ag = ag_input.to_i
    parent_perm_input = nil
    parent_perm = false
    loop do
      print 'Parent permission? (Y/N): '
      perm_response = gets.chomp.upcase
      if perm_response == 'Y'
        parent_perm = true
        break
      elsif perm_response == 'N'
        parent_perm = false
        break
      else
        puts 'Please enter Y or N'
      end
    end
    stu = Student.new(ag, nil, nm, parent_permission: parent_perm)
    @people << stu
  end

  def create_teacher
    print 'Name: '
    nm = gets.chomp
    print 'Age: '
    ag_input = gets.chomp
    ag = ag_input.to_i
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
    book = Book.new(t, a)
    @books << book
  end

  def create_rental
    puts 'Select a book by number:'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title}" }
    bi_input = gets.chomp
    bi = bi_input.to_i
    puts 'Select person by number:'
    @people.each_with_index { |p, i| puts "#{i}: #{p.full_name}" }
    pi_input = gets.chomp
    pi = pi_input.to_i
    if bi >= 0 && bi < @books.size && pi >= 0 && pi < @people.size
      Rental.new(Date.today, @books[bi], @people[pi])
    else
      puts 'Invalid indices'
    end
  end

  def list_rentals
    print 'ID of person: '
    pid_input = gets.chomp
    pid = pid_input.to_i
    p_obj = @people.detect { |pr| pr.id == pid }
    if p_obj
      p_obj.rentals.each do |r|
        puts "#{r.date} - #{r.book.title}"
      end
    else
      puts 'Person not found'
    end
  end

  private

  def valid_indices?(p_i, b_i)
    p_i >= 0 && p_i < @people.length && b_i >= 0 && b_i < @books.size
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
    name = @nameable.correct_name
    return name unless name.is_a?(String)
    name.length > 10 ? name[0..9] : name
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    name = @nameable.correct_name
    return name unless name.is_a?(String)
    name.capitalize
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
    unless @students.include?(stud)
      @students << stud
      stud.assign_classroom(self)
    end
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id = rand(1000)
    @name = name
    @age = age
    @parent_permission = parent_permission
    @rentals = []
  end

  def can_use_services?
    age >= 18 || @parent_permission
  end

  def correct_name
    @name
  end

  def add_rental(book, date)
    Rental.new(date, book, self)
  end
end

class Student < Person
  attr_reader :classroom

  def initialize(age, classroom, name, parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom if classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    @classroom = room
    unless room.students.include?(self)
      room.students << self
    end
  end

  def assign_classroom(room)
    self.classroom = room
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