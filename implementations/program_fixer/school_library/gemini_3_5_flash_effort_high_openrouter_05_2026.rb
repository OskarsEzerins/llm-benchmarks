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
    name = @nameable.correct_name
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

  def add_student(student)
    @students << student unless @students.include?(student)
    student.classroom = self if student.classroom != self
  end
end

class Person < Nameable
  attr_accessor :name, :age, :rentals
  attr_reader :id

  def initialize(age, name = 'Unknown', parent_permission: true)
    super()
    @id = rand(1..1000)
    @name = (name.nil? || name.empty?) ? 'Unknown' : name
    @age = age.to_i
    @parent_permission = parent_permission.nil? ? true : parent_permission
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
    classroom.add_student(self) if classroom
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
    super(age, name)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end

class App
  attr_accessor :books, :people

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
    print 'Do you want to create a student (1) or a teacher (2)? [Input the number]: '
    choice = gets.chomp.strip
    case choice
    when '1'
      create_student
    when '2'
      create_teacher
    else
      puts 'Invalid option!'
    end
  end

  def create_student
    print 'Age: '
    age_input = gets.chomp
    age = age_input.to_i
    if age <= 0 && age_input != '0'
      puts 'Invalid age'
      return
    end

    print 'Name: '
    name = gets.chomp.strip
    name = 'Unknown' if name.empty?

    print 'Has parent permission? [Y/N]: '
    perm_input = gets.chomp.strip.upcase
    until %w[Y N].include?(perm_input)
      print 'Has parent permission? [Y/N]: '
      perm_input = gets.chomp.strip.upcase
    end
    parent_permission = (perm_input == 'Y')

    stu = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << stu
    puts 'Person created successfully'
  end

  def create_teacher
    print 'Age: '
    age_input = gets.chomp
    age = age_input.to_i
    if age <= 0 && age_input != '0'
      puts 'Invalid age'
      return
    end

    print 'Name: '
    name = gets.chomp.strip
    name = 'Unknown' if name.empty?

    print 'Specialization: '
    spec = gets.chomp.strip
    spec = 'General' if spec.empty?

    t = Teacher.new(age, spec, name)
    @people << t
    puts 'Person created successfully'
  end

  def create_book
    print 'Title: '
    t = gets.chomp.strip
    print 'Author: '
    a = gets.chomp.strip
    if t.empty? || a.empty?
      puts 'Title and author cannot be empty.'
      return
    end
    book = Book.new(t, a)
    @books << book
    puts 'Book created successfully'
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'No books or people available to rent.'
      return
    end

    puts 'Select a book from the following list by number'
    @books.each_with_index { |b, i| puts "#{i}) Title: \"#{b.title}\", Author: #{b.author}" }
    bi = gets.chomp.to_i

    puts 'Select a person from the following list by number (not id)'
    @people.each_with_index { |p, i| puts "#{i}) [#{p.class}] Name: #{p.name}, ID: #{p.id}, Age: #{p.age}" }
    pi = gets.chomp.to_i

    unless valid_indices?(pi, bi)
      puts 'Invalid index selection!'
      return
    end

    print 'Date: '
    d = gets.chomp.strip
    d = Time.now.strftime('%Y/%m/%d') if d.empty?

    Rental.new(d, @books[bi], @people[pi])
    puts 'Rental created successfully'
  end

  def list_rentals
    if @people.empty?
      puts 'No registered people.'
      return
    end

    print 'ID of person: '
    pid = gets.chomp.to_i
    p_obj = @people.find { |pr| pr.id == pid }

    if p_obj.nil?
      puts 'Person not found'
      return
    end

    puts 'Rentals:'
    p_obj.rentals.each do |r|
      puts "Date: #{r.date}, Book \"#{r.book.title}\" by #{r.book.author}"
    end
  end

  private

  def valid_indices?(p_i, b_i)
    p_i >= 0 && p_i < @people.length && b_i >= 0 && b_i < @books.length
  end
end