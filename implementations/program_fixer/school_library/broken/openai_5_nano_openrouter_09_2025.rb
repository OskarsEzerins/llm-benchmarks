require 'date'

class Nameable
  def correct_name
    raise NotImplementedError, 'You must implement correct_name'
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
    name.is_a?(String) && name.length > 10 ? name[0, 10] : name
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    name = @nameable.correct_name
    if name.is_a?(String)
      name.split.map(&:capitalize).join(' ')
    else
      name
    end
  end
end

class Person < Nameable
  attr_reader :id, :name, :age, :rentals

  @@next_id = 1

  def initialize(age = 0, name = 'Unknown', parent_permission: true)
    @id = @@next_id
    @@next_id += 1
    @age = age.to_i
    @name = name
    @parent_permission = !!parent_permission
    @rentals = []
  end

  def correct_name
    @name
  end

  def can_use_services?
    @age >= 18 || @parent_permission
  end

  def add_rental(rental)
    @rentals << rental
  end
end

class Student < Person
  attr_reader :classroom

  def initialize(age, classroom, name, parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    @classroom = nil
    classroom.add_student(self) if classroom
  end

  def classroom=(room)
    @classroom = room
  end

  def play_hooky
    '╰(°▽°)╯'
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name)
    super(age, name, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end

class Book
  attr_accessor :title, :author, :rentals

  def initialize(title, author)
    @title = title.nil? || title.strip.empty? ? 'Untitled' : title
    @author = author.nil? || author.strip.empty? ? 'Unknown' : author
    @rentals = []
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

class App
  def initialize
    @books = []
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
        puts "[#{human.class}] id: #{human.id}, Name: #{human.correct_name}, Age: #{human.age}"
      end
    end
  end

  def create_person
    puts 'Student(1) or Teacher(2)? '
    print 'Please choose (1 or 2): '
    choice = STDIN.gets
    case choice.to_i
    when 1
      create_student
    when 2
      create_teacher
    else
      puts 'Invalid choice'
    end
  end

  def create_student
    print 'Name: '
    nm = STDIN.gets&.chomp
    nm = 'Unknown' if nm.nil? || nm.strip.empty?

    print 'Age: '
    ag_in = STDIN.gets
    ag = ag_in ? ag_in.to_i : 0
    ag = 0 if ag.negative?

    resp = nil
    loop do
      print 'Parent permission? (Y/N): '
      resp = STDIN.gets&.strip
      break if resp == 'Y' || resp == 'N'
      puts 'Invalid input. Please enter Y or N.'
    end
    parent_permission = (resp == 'Y')
    stu = Student.new(ag, nil, nm, parent_permission: parent_permission)
    @people << stu
    puts 'Student created successfully'
  end

  def create_teacher
    print 'Name: '
    nm = STDIN.gets&.chomp
    nm = 'Unknown' if nm.nil? || nm.strip.empty?

    print 'Age: '
    ag_in = STDIN.gets
    ag = ag_in ? ag_in.to_i : 0
    ag = 0 if ag.negative?

    print 'Specialization: '
    spec = STDIN.gets&.chomp
    spec = 'General' if spec.nil? || spec.strip.empty?

    t = Teacher.new(ag, spec, nm)
    @people << t
    puts 'Teacher created successfully'
  end

  def create_book
    print 'Title: '
    t = STDIN.gets&.chomp
    t = 'Untitled' if t.nil? || t.strip.empty?

    print 'Author: '
    a = STDIN.gets&.chomp
    a = 'Unknown' if a.nil? || a.strip.empty?

    book = Book.new(t, a)
    @books << book
    puts 'Book created successfully'
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'Need at least one book and one person to create a rental.'
      return
    end

    puts 'Select a book by number:'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title} by #{b.author}" }
    bi_input = STDIN.gets
    bi = bi_input ? bi_input.to_i : -1
    unless bi.between?(0, @books.length - 1)
      puts 'Invalid book index'
      return
    end

    puts 'Select a person by number:'
    @people.each_with_index { |p, i| puts "#{i}: #{p.name} (#{p.class})" }
    pi_input = STDIN.gets
    pi = pi_input ? pi_input.to_i : -1
    unless pi.between?(0, @people.length - 1)
      puts 'Invalid person index'
      return
    end

    print 'Date (YYYY-MM-DD) [today]: '
    date_input = STDIN.gets&.strip
    date = if date_input.nil? || date_input.empty?
             Date.today.to_s
           else
             begin
               Date.parse(date_input).to_s
             rescue
               puts 'Invalid date format. Using today.'
               Date.today.to_s
             end
           end

    Rental.new(date, @books[bi], @people[pi])
  end

  def list_rentals
    print 'ID of person: '
    pid_input = STDIN.gets
    pid = pid_input ? pid_input.to_i : -1
    p_obj = @people.find { |pr| pr.id == pid }
    if p_obj && p_obj.rentals.any?
      p_obj.rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
    else
      puts 'No rentals found for this person'
    end
  end
end