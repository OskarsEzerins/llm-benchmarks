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
    choice = nil
    loop do
      print 'Choose option: Student(1) or Teacher(2): '
      choice = gets.chomp
      break if %w[1 2].include?(choice)

      puts 'Invalid option. Please enter 1 for Student or 2 for Teacher.'
    end

    create_student if choice == '1'
    create_teacher if choice == '2'
  end

  def create_student
    name = nil
    loop do
      print 'Name: '
      name = gets.chomp
      break unless name.nil? || name.strip.empty?

      puts 'Name cannot be empty.'
    end

    age = nil
    loop do
      print 'Age: '
      input = gets.chomp
      if input =~ /\A\d+\z/
        age = input.to_i
        break if age >= 0

        puts 'Age cannot be negative.'
      else
        puts 'Please enter a valid integer for age.'
      end
    end

    perm = nil
    loop do
      print 'Parent permission? [Y/N]: '
      resp = gets.chomp.upcase
      if %w[Y N].include?(resp)
        perm = resp == 'Y'
        break
      end

      puts 'Please enter Y or N.'
    end

    student = Student.new(age, nil, name, parent_permission: perm)
    @people << student
    puts 'Student created successfully'
  end

  def create_teacher
    name = nil
    loop do
      print 'Name: '
      name = gets.chomp
      break unless name.nil? || name.strip.empty?

      puts 'Name cannot be empty.'
    end

    age = nil
    loop do
      print 'Age: '
      input = gets.chomp
      if input =~ /\A\d+\z/
        age = input.to_i
        break if age >= 0

        puts 'Age cannot be negative.'
      else
        puts 'Please enter a valid integer for age.'
      end
    end

    spec = nil
    loop do
      print 'Specialization: '
      spec = gets.chomp
      break unless spec.nil? || spec.strip.empty?

      puts 'Specialization cannot be empty.'
    end

    teacher = Teacher.new(age, spec, name)
    @people << teacher
    puts 'Teacher created successfully'
  end

  def create_book
    title = nil
    loop do
      print 'Title: '
      title = gets.chomp
      break unless title.nil? || title.strip.empty?

      puts 'Title cannot be empty.'
    end

    author = nil
    loop do
      print 'Author: '
      author = gets.chomp
      break unless author.nil? || author.strip.empty?

      puts 'Author cannot be empty.'
    end

    book = Book.new(title, author)
    @books << book
    puts 'Book created successfully'
  end

  def create_rental
    if @books.empty?
      puts 'No books available to rent.'
      return
    end

    if @people.empty?
      puts 'No people available to rent books.'
      return
    end

    puts 'Select a book from the following list by number'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title} by #{b.author}" }

    bi = nil
    loop do
      print 'Book number: '
      input = gets.chomp
      if input =~ /\A\d+\z/
        bi = input.to_i
        break if valid_book_index?(bi)

        puts 'Book number out of range.'
      else
        puts 'Please enter a valid number.'
      end
    end

    puts 'Select a person from the following list by number (not ID)'
    @people.each_with_index { |p, i| puts "#{i}: [#{p.class}] Name: #{p.name}, ID: #{p.id}" }

    pi = nil
    loop do
      print 'Person number: '
      input = gets.chomp
      if input =~ /\A\d+\z/
        pi = input.to_i
        break if valid_person_index?(pi)

        puts 'Person number out of range.'
      else
        puts 'Please enter a valid number.'
      end
    end

    print 'Date (YYYY-MM-DD): '
    date = gets.chomp
    date = Date.today.to_s if date.nil? || date.strip.empty?

    Rental.new(date, @books[bi], @people[pi])
    puts 'Rental created successfully'
  end

  def list_rentals
    print 'ID of person: '
    input = gets.chomp
    unless input =~ /\A\d+\z/
      puts 'Invalid ID format.'
      return
    end

    pid = input.to_i
    p_obj = @people.detect { |pr| pr.id == pid }
    if p_obj.nil?
      puts 'Person not found.'
      return
    end

    if p_obj.rentals.empty?
      puts 'No rentals for this person.'
      return
    end

    p_obj.rentals.each { |r| puts "#{r.date} - #{r.book.title} by #{r.book.author}" }
  end

  private

  def valid_person_index?(i)
    i.is_a?(Integer) && i >= 0 && i < @people.length
  end

  def valid_book_index?(i)
    i.is_a?(Integer) && i >= 0 && i < @books.length
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, 'Subclasses must implement the correct_name method'
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
    name = super()
    return '' if name.nil?

    name.length > 10 ? name[0, 10] : name
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    name = super()
    return '' if name.nil?

    name.capitalize
  end
end

class Rental
  attr_reader :date, :book, :person

  def initialize(date, book, person)
    @date = date
    @book = book
    @person = person
    @book.rentals << self
    @person.rentals << self
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
    return if stud.nil?

    @students << stud unless @students.include?(stud)
    stud.classroom = self unless stud.classroom == self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id = rand(1..1000)
    @name = name
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

  def initialize(age, classroom, name, parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom if classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    return if room.nil?

    @classroom = room
    room.students << self unless room.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name)
    super(name, age, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end

require 'date'