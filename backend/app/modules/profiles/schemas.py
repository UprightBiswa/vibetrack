from pydantic import BaseModel, ConfigDict, Field


class ProfileResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    email: str | None
    username: str
    avatar_url: str
    home_city: str
    aura_points: int


class UpdateProfileRequest(BaseModel):
    username: str | None = Field(default=None, max_length=64)
    avatar_url: str | None = Field(default=None, max_length=512)
    home_city: str | None = Field(default=None, max_length=128)


class AddAuraRequest(BaseModel):
    delta: int = 0
