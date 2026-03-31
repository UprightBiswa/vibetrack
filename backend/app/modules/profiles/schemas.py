from pydantic import BaseModel, ConfigDict, Field


class ProfileResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    email: str | None
    username: str
    avatar_url: str
    home_city: str
    aura_points: int


class ProfileRankResponse(BaseModel):
    profile_id: str
    aura_points: int
    global_rank: int


class ProfileStreakResponse(BaseModel):
    profile_id: str
    current_streak_days: int
    longest_streak_days: int
    active_today: bool


class LeaderboardEntryResponse(BaseModel):
    profile_id: str
    username: str
    aura_points: int
    global_rank: int


class UpdateProfileRequest(BaseModel):
    username: str | None = Field(default=None, max_length=64)
    avatar_url: str | None = Field(default=None, max_length=512)
    home_city: str | None = Field(default=None, max_length=128)


class AddAuraRequest(BaseModel):
    delta: int = 0
