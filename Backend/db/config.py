"""
Owner: ArelyXl
Description: Configura la conexión asíncrona a PostgreSQL usando SQLAlchemy, definiendo el engine, la sesión asíncrona y la función para obtener la sesión de base de datos.
"""
import os
from pathlib import Path
from urllib.parse import urlparse, urlunparse, parse_qs, urlencode
from dotenv import load_dotenv
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker

load_dotenv(dotenv_path=Path(__file__).parent / ".env")

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql+asyncpg://user:pass@localhost:5432/dbname")

if DATABASE_URL and not DATABASE_URL.startswith("postgresql+asyncpg://"):
    DATABASE_URL = DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://", 1)

parsed = urlparse(DATABASE_URL)
params = parse_qs(parsed.query)
params.pop("sslmode", None)
new_query = urlencode(params, doseq=True)
DATABASE_URL = urlunparse(parsed._replace(query=new_query))

engine = create_async_engine(DATABASE_URL, echo=False)
AsyncSessionLocal = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

async def get_db():
    async with AsyncSessionLocal() as session:
        yield session
