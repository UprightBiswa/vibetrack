from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class StartRideRequest(BaseModel):
    activity_type: str = Field(default='ride', max_length=32)


class StartRideResponse(BaseModel):
    session_id: str
    started_at: datetime
    status: str


class FinishRideRequest(BaseModel):
    session_id: str
    ended_at: datetime | None = None
    distance_m: float = 0
    duration_s: int = 0
    avg_speed_mps: float = 0
    avg_pace: float = 0
    calories: int = 0
    route_geojson: dict = Field(default_factory=dict)


class RideSummary(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    activity_type: str
    status: str
    started_at: datetime
    ended_at: datetime | None
    distance_m: float
    duration_s: int
    avg_speed_mps: float
    avg_pace: float
    calories: int
    route_geojson: dict
