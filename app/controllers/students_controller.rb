class StudentsController < ApplicationController
  before_action :set_student, only: [:show, :edit, :update, :destroy]
  before_action :require_admin, except: [:show]
  before_action :sync_tags, only: [:show, :edit]
  before_action :sync_all_tags!, only: [:index]

  # GET /students
  # GET /students.json
  def index
    @students = Student.all.order(:last_name)
  end

  # GET /stats.json
  # Student progress
  def stats
    colors = ["#fdae61","#fee090","#e0f3f8","#abd9e9","#74add1","#4575b4"]
    stats = Assignment.all.order(:title).map.with_index do |assignment, index|
      c = colors[index % colors.size]
      {
        value: assignment.students_whose_latest_assignment_is_this.length,
        label: assignment.title,
        color: c
      }
    end

    stats.unshift({
      value: Student.count - stats.inject(0){|sum, stat| sum + stat[:value]},
      label: "None",
      color: "#eee"
      })
    count = {count: stats.inject(0){|sum, stat| sum + stat[:value]}}
    render json: stats
  end

  # GET /students/1
  # GET /students/1.json
  def show
  end

  # GET /students/new
  def new
    @student = Student.new
  end

  # GET /students/1/edit
  def edit
  end

  # POST /students
  # POST /students.json
  def create
    @student = Student.new(student_params)

    respond_to do |format|
      if @student.save
        format.html { redirect_to @student, notice: 'Student was successfully created.' }
        format.json { render :show, status: :created, location: @student }
      else
        format.html { render :new }
        format.json { render json: @student.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /students/1
  # PATCH/PUT /students/1.json
  def update
    respond_to do |format|
      if @student.update(student_params)
        format.html { redirect_to @student, notice: 'Profile was successfully updated.' }
        format.json { render :show, status: :ok, location: @student }
      else
        format.html { render :edit }
        format.json { render json: @student.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /students/1
  # DELETE /students/1.json
  def destroy
    @student.destroy
    respond_to do |format|
      format.html { redirect_to students_url, notice: 'Student was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_student
      @student = Student.find_by!(slug: params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def student_params
      params.require(:student).permit(:first_name, :last_name, :github_username, :github_repo, :email)
    end

    def sync_tags
      @student.sync_tags(force_update: true) unless Assignment.submission_deadline_past?
    end

    def sync_all_tags!
      Student.sync_all_tags! unless Assignment.submission_deadline_past?
    end
end
