from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from google.oauth2 import id_token
from google.auth.transport import requests
from pydantic import BaseModel

from app.core.database import get_db
from app.core.config import settings
from app.core.security import create_access_token, decode_access_token
from app.models.user import User

router = APIRouter()

oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_STR}/auth/google")

class GoogleAuthRequest(BaseModel):
    id_token: str

async def get_current_user(
    db: Session = Depends(get_db),
    token: str = Depends(oauth2_scheme)
) -> User:
    """
    Dependency to get the current authenticated user by decoding the JWT token.
    """
    user_id = decode_access_token(token)
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return user

@router.post("/google")
async def google_auth(payload: GoogleAuthRequest, db: Session = Depends(get_db)):
    """
    Endpoint to authenticate via Google ID token.
    Verifies the token, creates/updates the user, and returns a local JWT.
    """
    try:
        # Define valid audiences (Web and Android Client IDs)
        valid_audiences = []
        if settings.GOOGLE_WEB_CLIENT_ID:
            valid_audiences.append(settings.GOOGLE_WEB_CLIENT_ID)
        if settings.GOOGLE_ANDROID_CLIENT_ID:
            valid_audiences.append(settings.GOOGLE_ANDROID_CLIENT_ID)

        if not valid_audiences:
            raise ValueError("No Google Client IDs configured in backend settings.")

        # Verify the ID token from Google
        id_info = id_token.verify_oauth2_token(
            payload.id_token, requests.Request(), valid_audiences
        )

        # Extract user info
        google_id = id_info['sub']
        email = id_info['email']
        name = id_info.get('name', '')
        picture = id_info.get('picture', '')

        # Check if user exists
        user = db.query(User).filter(User.google_id == google_id).first()
        
        if not user:
            # Create new user
            user = User(
                google_id=google_id,
                email=email,
                name=name,
                profile_picture=picture
            )
            db.add(user)
            db.commit()
            db.refresh(user)
        else:
            # Update user info if changed
            user.name = name
            user.profile_picture = picture
            db.commit()

        # Create local access token
        access_token = create_access_token(subject=user.user_id)
        
        return {
            "access_token": access_token,
            "token_type": "bearer",
            "user": {
                "user_id": str(user.user_id),
                "email": user.email,
                "name": user.name,
                "profile_picture": user.profile_picture
            }
        }

    except ValueError:
        # Invalid token
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Google ID token"
        )

@router.get("/me")
async def get_me(current_user: User = Depends(get_current_user)):
    """
    Endpoint to get current user info.
    """
    if not current_user:
        raise HTTPException(status_code=401, detail="Not authenticated")
    return {
        "user_id": str(current_user.user_id),
        "email": current_user.email,
        "name": current_user.name,
        "profile_picture": current_user.profile_picture,
    }

@router.post("/logout")
async def logout():
    """
    Endpoint to logout.
    """
    return {"message": "Logged out"}
