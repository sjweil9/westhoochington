class NicknamesController < ApplicationController
  def create
    nickname = Nickname.create(new_nickname_params)
    process_errors(nickname) unless nickname.save
    redirect_back(fallback_location: home_path)
  end

  def upvote
    if existing_vote.present?
      existing_vote.update(value: 1)
    else
      NicknameVote.create(vote_params.merge(value: 1))
    end
    redirect_back(fallback_location: home_path)
  end

  def downvote
    if existing_vote.present?
      existing_vote.update(value: -1)
    else
      NicknameVote.create(vote_params.merge(value: -1))
    end
    redirect_back(fallback_location: home_path)
  end

  private

  def new_nickname_params
    params.permit(:name, :user_id)
  end

  def vote_params
    {
      user_id: current_user[:id],
      nickname_id: params[:nickname_id],
    }
  end

  def existing_vote
    @existing_vote ||= NicknameVote.find_by(user_id: current_user[:id], nickname_id: params[:nickname_id])
  end
end
