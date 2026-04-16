from datetime import datetime

from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from database import Base


class ObjetivoDB(Base):
    __tablename__ = "objetivos"

    id = Column(Integer, primary_key=True, index=True)
    titulo = Column(String, index=True, nullable=False)
    detalle = Column(String, nullable=True)
    tipo = Column(String, nullable=False)
    prioridad = Column(Integer, default=3, nullable=False)
    duracion_minutos = Column(Integer, default=60, nullable=False)
    sesiones_por_semana = Column(Integer, default=1, nullable=False)
    fecha_limite = Column(String, nullable=True)
    completado = Column(Boolean, default=False, nullable=False)
    fecha_creacion = Column(DateTime, default=datetime.utcnow, nullable=False)

    bloques = relationship("BloquePlanDB", back_populates="objetivo")


class EventoFijoDB(Base):
    __tablename__ = "eventos_fijos"

    id = Column(Integer, primary_key=True, index=True)
    titulo = Column(String, index=True, nullable=False)
    detalle = Column(String, nullable=True)
    fecha = Column(String, nullable=False)
    fecha_fin = Column(String, nullable=True)
    inicio_minutos = Column(Integer, nullable=False)
    fin_minutos = Column(Integer, nullable=False)
    prioridad = Column(Integer, default=3, nullable=False)
    fecha_creacion = Column(DateTime, default=datetime.utcnow, nullable=False)


class DisponibilidadDB(Base):
    __tablename__ = "disponibilidad"

    id = Column(Integer, primary_key=True, index=True)
    dia_semana = Column(Integer, nullable=False)
    inicio_minutos = Column(Integer, nullable=False)
    fin_minutos = Column(Integer, nullable=False)


class BloquePlanDB(Base):
    __tablename__ = "bloques_plan"

    id = Column(Integer, primary_key=True, index=True)
    objetivo_id = Column(Integer, ForeignKey("objetivos.id"), nullable=False)
    semana_inicio = Column(String, nullable=True)
    dia_semana = Column(Integer, nullable=False)
    inicio_minutos = Column(Integer, nullable=False)
    fin_minutos = Column(Integer, nullable=False)
    estado = Column(String, default="pendiente", nullable=False)
    replanificado = Column(Boolean, default=False, nullable=False)
    fecha_creacion = Column(DateTime, default=datetime.utcnow, nullable=False)

    objetivo = relationship("ObjetivoDB", back_populates="bloques")
