import logging
from fastapi import FastAPI, HTTPException
from sqlalchemy import create_engine, Column, Integer, String, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from datetime import datetime

# --- 로깅 설정 ---
# /app/logs/app.log 경로에 로그를 기록합니다. 이 경로는 docker-compose.yml의 backend_logs 볼륨과 연결됩니다.
LOG_FILE = "/app/logs/app.log"
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler() # 콘솔에도 로그 출력
    ]
)
logger = logging.getLogger(__name__)

app = FastAPI()

# --- 데이터베이스 설정 ---
# docker-compose.yml의 db 서비스 이름과 환경 변수를 사용합니다.
DATABASE_URL = "mariadb+pymysql://user:password@db/mydatabase"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# --- 데이터베이스 모델 정의 ---
class User(Base):
    __tablename__ = "users" # 테이블 이름

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), index=True)
    email = Column(String(255), unique=True, index=True)
    created_at = Column(DateTime, default=datetime.now)

# 데이터베이스 테이블 생성 (없을 경우)
# 애플리케이션 시작 시 테이블이 자동으로 생성됩니다.
Base.metadata.create_all(bind=engine)

# DB 세션 의존성 주입
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# --- FastAPI 엔드포인트 ---
@app.get("/")
async def read_root():
    logger.info("루트 엔드포인트 접근됨.")
    return {"message": "FastAPI backend is running!"}

@app.post("/users/")
async def create_user(name: str, email: str):
    db = next(get_db())
    try:
        new_user = User(name=name, email=email)
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        logger.info(f"사용자 생성됨: {new_user.name} ({new_user.email})")
        return new_user
    except Exception as e:
        logger.error(f"사용자 생성 중 오류 발생: {e}")
        raise HTTPException(status_code=500, detail=f"사용자 생성 중 오류 발생: {e}")
    finally:
        db.close()

@app.get("/users/")
async def read_users():
    db = next(get_db())
    try:
        users = db.query(User).all()
        logger.info(f"총 {len(users)}명의 사용자 조회됨.")
        return users
    finally:
        db.close()
