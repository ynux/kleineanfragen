class PaperController < ApplicationController
  before_filter :find_body
  before_filter :find_legislative_term
  before_filter :find_paper

  def show
  end


  def find_body
    @body = Body.friendly.find params[:body]
  end

  def find_legislative_term
    @legislative_term = params[:legislative_term].to_i
  end

  def find_paper
    @paper = Paper.where(body: @body, legislative_term: @legislative_term).friendly.find params[:paper]
  end
end
