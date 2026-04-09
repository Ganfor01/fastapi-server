from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel, Field
from typing import Annotated
from sqlalchemy.orm import Session
from database import engine, SessionLocal
from models import UsuarioDB

app = FastAPI()

# 🔹 Crear tablas
UsuarioDB.metadata.create_all(bind=engine)

# 🔹 Dependencia DB
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# 🔹 Modelo Pydantic (API)
class Usuario(BaseModel):
    nombre: Annotated[str, Field(min_length=2, max_length=15)]
    edad: Annotated[int, Field(ge=1, le=99)]

# 🔹 CREATE usuario
@app.post("/usuarios")
def crear_usuario(usuario: Usuario, db: Session = Depends(get_db)):
    nuevo_usuario = UsuarioDB(
        nombre=usuario.nombre,
        edad=usuario.edad
    )

    db.add(nuevo_usuario)
    db.commit()
    db.refresh(nuevo_usuario)

    return {
        "mensaje": "Usuario creado en DB",
        "usuario": {
            "id": nuevo_usuario.id,
            "nombre": nuevo_usuario.nombre,
            "edad": nuevo_usuario.edad
        }
    }

# 🔹 READ usuarios
@app.get("/usuarios")
def obtener_usuarios(db: Session = Depends(get_db)):
    return db.query(UsuarioDB).all()

# 🔹 READ usuario por ID
@app.get("/usuarios/{usuario_id}")
def obtener_usuario(usuario_id: int, db: Session = Depends(get_db)):
    usuario = db.query(UsuarioDB).filter(UsuarioDB.id == usuario_id).first()

    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    return usuario

# 🔹 UPDATE usuario
@app.put("/usuarios/{usuario_id}")
def actualizar_usuario(usuario_id: int, usuario: Usuario, db: Session = Depends(get_db)):
    usuario_db = db.query(UsuarioDB).filter(UsuarioDB.id == usuario_id).first()

    if not usuario_db:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    usuario_db.nombre = usuario.nombre
    usuario_db.edad = usuario.edad

    db.commit()
    db.refresh(usuario_db)

    return {
        "mensaje": "Usuario actualizado correctamente",
        "usuario": {
            "id": usuario_db.id,
            "nombre": usuario_db.nombre,
            "edad": usuario_db.edad
        }
    }

# 🔹 DELETE usuario
@app.delete("/usuarios/{usuario_id}")
def eliminar_usuario(usuario_id: int, db: Session = Depends(get_db)):
    usuario = db.query(UsuarioDB).filter(UsuarioDB.id == usuario_id).first()

    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    db.delete(usuario)
    db.commit()

    return {"mensaje": "Usuario eliminado correctamente"}

