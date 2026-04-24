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
    print 'Student(3) or Teacher(1)? '
    choice = gets.chomp.strip
    if choice == '1'
      create_teacher
    elsif choice == '3'
      create_student
    else
      puts 'Invalid choice. Please enter 1 for Teacher or 3 for Student.'
    end
  end

  def create_student
    print 'Name: '
    nm = gets.chomp.strip
    nm = 'Unknown' if nm.nil? || nm.empty?

    print 'Age: '
    ag_input = gets.chomp.strip
    ag = ag_input.to_i
    ag = 0 if ag < 0

    perm = nil
    loop do
      print 'Parent permission? [Y/N]: '
      perm_input = gets.chomp.strip.upcase
      if perm_input == 'Y'
        perm = true
        break
      elsif perm_input == 'N'
        perm = false
        break
      else
        puts "Invalid input. Please enter Y or N."
      end
    end

    stu = Student.new(ag, nil, nm, parent_permission: perm)
    @people << stu
  end

  def create_teacher
    print 'Name: '
    nm = gets.chomp.strip
    nm = 'Unknown' if nm.nil? || nm.empty?

    print 'Age: '
    ag_input = gets.chomp.strip
    ag = ag_input.to_i
    ag = 0 if ag < 0

    print 'Specialization: '
    spec = gets.chomp.strip

    t = Teacher.new(ag, spec, nm)
    @people << t
  end

  def create_book
    print 'Title: '
    t = gets.chomp.strip

    print 'Author: '
    a = gets.chomp.strip

    @books << Book.new(t, a)
  end

  def create_rental
    if @books.empty?
      puts 'No books available.'
      return
    end

    if @people.empty?
      puts 'No people available.'
      return
    end

    puts 'Select a book'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title}" }
    bi = gets.chomp.to_i

    unless bi >= 0 && bi < @books.length
      puts 'Invalid book index.'
      return
    end

    puts 'Select person'
    @people.each_with_index { |p, i| puts "#{i}: #{p.name}" }
    pi = gets.chomp.to_i

    unless pi >= 0 && pi < @people.length
      puts 'Invalid person index.'
      return
    end

    print 'Date (YYYY-MM-DD): '
    date = gets.chomp.strip
    date = Date.today.to_s if date.nil? || date.empty?

    Rental.new(date, @books[bi], @people[pi])
    puts 'Rental created successfully.'
  end

  def list_rentals
    print 'ID of person: '
    pid = gets.chomp.to_i
    p_obj = @people.detect { |pr| pr.id == pid }

    if p_obj.nil?
      puts 'Person not found.'
      return
    end

    if p_obj.rentals.empty?
      puts 'No rentals for this person.'
      return
    end

    p_obj.rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
  end

  private

  def valid_indices?(p_i, b_i)
    p_i < @people.length && b_i < @books.size
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, 'Subclasses must implement correct_name'
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

  def add_student(stud)
    @students << stud unless @students.include?(stud)
    stud.classroom = self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id                = rand(1000)
    @name              = name.to_s
    @age               = age.to_i
    @parent_permission = parent_permission
    @rentals           = []
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
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    @classroom = room
    room.students << self unless room.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name = 'Unknown')
    super(name, age)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end