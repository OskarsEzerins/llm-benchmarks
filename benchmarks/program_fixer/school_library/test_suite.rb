# frozen_string_literal: true

require 'minitest/autorun'
require 'stringio'

# Load the working app for testing during development
require_relative 'working_app'

class SchoolLibraryTest < Minitest::Test
  def setup
    @app = App.new
    @old_stdout = $stdout
    @old_stdin = $stdin
  end

  def teardown
    $stdout = @old_stdout
    $stdin = @old_stdin
  end

  # Test App initialization
  def test_app_initialization
    assert_instance_of App, @app
    assert_empty @app.instance_variable_get(:@books)
    assert_empty @app.instance_variable_get(:@people)
  end

  # Test Book class
  def test_book_creation
    book = Book.new("The Ruby Way", "Hal Fulton")
    assert_equal "The Ruby Way", book.title
    assert_equal "Hal Fulton", book.author
    assert_empty book.rentals
  end

  def test_book_add_rental
    book = Book.new("Test Book", "Test Author")
    person = Person.new("John Doe", 25)
    rental = book.add_rental("2023-01-01", person)

    assert_instance_of Rental, rental
    assert_includes book.rentals, rental
    assert_includes person.rentals, rental
  end

  # Test Person class
  def test_person_creation
    person = Person.new("Alice", 20)
    assert_equal "Alice", person.name
    assert_equal 20, person.age
    assert person.can_use_services?
    assert_empty person.rentals
    refute_nil person.id
  end

  def test_person_id_generation
    person1 = Person.new("Person1", 25)
    person2 = Person.new("Person2", 30)
    refute_equal person1.id, person2.id
  end

  def test_person_under_age_with_permission
    person = Person.new("Minor", 16, parent_permission: true)
    assert person.can_use_services?
  end

  def test_person_under_age_without_permission
    person = Person.new("Minor", 16, parent_permission: false)
    refute person.can_use_services?
  end

  def test_person_of_age
    person = Person.new("Adult", 18, parent_permission: false)
    assert person.can_use_services?
  end

  def test_person_correct_name
    person = Person.new("Test Name", 25)
    assert_equal "Test Name", person.correct_name
  end

  # Test Student class
  def test_student_creation
    classroom = Classroom.new("Math 101")
    student = Student.new(20, classroom, "Bob", parent_permission: true)
    assert_equal "Bob", student.name
    assert_equal 20, student.age
    assert_equal classroom, student.classroom
  end

  def test_student_play_hooky
    student = Student.new(18, nil, "Student")
    assert_equal '¯\(ツ)/¯', student.play_hooky
  end

  def test_student_classroom_assignment
    classroom = Classroom.new("Science 101")
    student = Student.new(19, nil, "Alice")

    student.classroom = classroom
    assert_equal classroom, student.classroom
    assert_includes classroom.students, student
  end

  # Test Teacher class
  def test_teacher_creation
    teacher = Teacher.new(35, "Mathematics", "Dr. Smith")
    assert_equal "Dr. Smith", teacher.name
    assert_equal 35, teacher.age
    assert_equal "Mathematics", teacher.specialization
  end

  def test_teacher_can_always_use_services
    teacher = Teacher.new(25, "Physics")
    assert teacher.can_use_services?
  end

  # Test Classroom class
  def test_classroom_creation
    classroom = Classroom.new("History 101")
    assert_equal "History 101", classroom.label
    assert_empty classroom.students
  end

  def test_classroom_add_student
    classroom = Classroom.new("English 101")
    student = Student.new(20, nil, "Charlie")

    classroom.add_student(student)
    assert_includes classroom.students, student
    assert_equal classroom, student.classroom
  end

  # Test Rental class
  def test_rental_creation
    book = Book.new("Test Book", "Test Author")
    person = Person.new("Test Person", 25)
    rental = Rental.new("2023-01-01", book, person)

    assert_equal "2023-01-01", rental.date
    assert_equal book, rental.book
    assert_equal person, rental.person
    assert_includes book.rentals, rental
    assert_includes person.rentals, rental
  end

  # Test Decorator classes
  def test_trimmer_decorator
    person = Person.new("Very Long Name Here", 25)
    decorator = TrimmerDecorator.new(person)
    assert_equal "Very Long ", decorator.correct_name
  end

  def test_capitalize_decorator
    person = Person.new("lowercase name", 25)
    decorator = CapitalizeDecorator.new(person)
    assert_equal "Lowercase name", decorator.correct_name
  end

  def test_chained_decorators
    person = Person.new("very long lowercase name", 25)
    trimmed = TrimmerDecorator.new(person)
    capitalized = CapitalizeDecorator.new(trimmed)
    assert_equal "Very long ", capitalized.correct_name
  end

  # Test Nameable abstract class
  def test_nameable_raises_not_implemented
    nameable = Nameable.new
    assert_raises(NotImplementedError) { nameable.correct_name }
  end

  # Test App methods with mocked input/output
  def test_app_create_book
    mock_input("Test Title\nTest Author\n")
    mock_output

    @app.create_book
    books = @app.instance_variable_get(:@books)
    assert_equal 1, books.length
    assert_equal "Test Title", books.first.title
    assert_equal "Test Author", books.first.author
  end

  def test_app_create_teacher
    mock_input("Dr. Johnson\n40\nPhysics\n")
    mock_output

    @app.create_teacher
    people = @app.instance_variable_get(:@people)
    assert_equal 1, people.length
    teacher = people.values.first
    assert_instance_of Teacher, teacher
    assert_equal "Dr. Johnson", teacher.name
    assert_equal 40, teacher.age
    assert_equal "Physics", teacher.specialization
  end

  def test_app_create_student
    mock_input("Jane Doe\n19\nY\n")
    mock_output

    @app.create_student
    people = @app.instance_variable_get(:@people)
    assert_equal 1, people.length
    student = people.values.first
    assert_instance_of Student, student
    assert_equal "Jane Doe", student.name
    assert_equal 19, student.age
    assert student.can_use_services?
  end

  def test_app_create_student_without_permission
    mock_input("Minor Student\n16\nN\n")
    mock_output

    @app.create_student
    people = @app.instance_variable_get(:@people)
    student = people.values.first
    refute student.can_use_services?
  end

  def test_app_list_empty_books
    output = capture_output { @app.list_books }
    assert_includes output, "No books available"
  end

  def test_app_list_empty_people
    output = capture_output { @app.list_people }
    assert_includes output, "No one has registered"
  end

  def test_app_valid_indices
    # Add some test data
    @app.instance_variable_get(:@books) << Book.new("Test", "Author")
    @app.instance_variable_get(:@people)[1] = Person.new("Test Person", 25)

    assert @app.send(:valid_indices?, 0, 0)
    refute @app.send(:valid_indices?, -1, 0)
    refute @app.send(:valid_indices?, 0, -1)
    refute @app.send(:valid_indices?, 1, 0)
    refute @app.send(:valid_indices?, 0, 1)
  end

  private

  def mock_input(input_string)
    $stdin = StringIO.new(input_string)
  end

  def mock_output
    $stdout = StringIO.new
  end

  def capture_output
    old_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = old_stdout
  end
end
