"""
Owner: ArelyXl
Description: Configura el servidor ASGI de Strawberry GraphQL usando el esquema unificado definido en graphql/schema/index.py.
"""
from strawberry.asgi import GraphQL
from graphql.schema.index import schema
from starlette.middleware.cors import CORSMiddleware

app = GraphQL(schema)

app = CORSMiddleware(
    app=app,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("graphql.server:app", host="0.0.0.0", port=8000, reload=True)
