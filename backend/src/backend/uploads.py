from fastapi import APIRouter, HTTPException, status
from fastapi.responses import FileResponse

from . import config

router = APIRouter(tags=["uploads"])


@router.get("/uploads/{filename}")
def serve_upload(filename: str) -> FileResponse:
    base = config.UPLOADS_DIR.resolve()
    path = (base / filename).resolve()
    if not path.is_relative_to(base) or not path.is_file():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="File not found"
        )
    return FileResponse(path)
