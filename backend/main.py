from datetime import date, timedelta
from typing import Annotated

from fastapi import Depends, FastAPI, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session, joinedload

from database import SessionLocal, engine
from models import BloquePlanDB, DisponibilidadDB, EventoFijoDB, ObjetivoDB

app = FastAPI(title="Organizador Automatico de Vida")

ObjetivoDB.metadata.create_all(bind=engine)

NOMBRES_DIAS = [
    "Lunes",
    "Martes",
    "Miercoles",
    "Jueves",
    "Viernes",
    "Sabado",
    "Domingo",
]


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def minutos_a_hora(minutos: int) -> str:
    hora = minutos // 60
    minuto = minutos % 60
    return f"{hora:02d}:{minuto:02d}"


def fecha_iso_desde_dia_semana(dia_semana: int) -> str:
    hoy = date.today()
    inicio_semana = hoy - timedelta(days=hoy.weekday())
    return (inicio_semana + timedelta(days=dia_semana)).isoformat()


def inicio_y_fin_semana_actual() -> tuple[date, date]:
    hoy = date.today()
    inicio_semana = hoy - timedelta(days=hoy.weekday())
    fin_semana = inicio_semana + timedelta(days=6)
    return (inicio_semana, fin_semana)


def fecha_en_semana_actual(fecha_iso: str) -> bool:
    try:
        fecha = date.fromisoformat(fecha_iso)
    except ValueError:
        return False
    inicio_semana, fin_semana = inicio_y_fin_semana_actual()
    return inicio_semana <= fecha <= fin_semana


def serializar_objetivo(objetivo: ObjetivoDB) -> dict:
    return {
        "id": objetivo.id,
        "titulo": objetivo.titulo,
        "detalle": objetivo.detalle,
        "tipo": objetivo.tipo,
        "prioridad": objetivo.prioridad,
        "duracion_minutos": objetivo.duracion_minutos,
        "sesiones_por_semana": objetivo.sesiones_por_semana,
        "fecha_limite": objetivo.fecha_limite,
        "completado": objetivo.completado,
        "fecha_creacion": objetivo.fecha_creacion,
    }


def serializar_tarea_flexible(objetivo: ObjetivoDB) -> dict:
    return serializar_objetivo(objetivo)


def serializar_habito(objetivo: ObjetivoDB) -> dict:
    return serializar_objetivo(objetivo)


def serializar_evento_fijo(evento: EventoFijoDB) -> dict:
    try:
        fecha_evento = date.fromisoformat(evento.fecha)
        nombre_dia = NOMBRES_DIAS[fecha_evento.weekday()]
    except ValueError:
        nombre_dia = "Dia"

    return {
        "id": evento.id,
        "titulo": evento.titulo,
        "detalle": evento.detalle,
        "fecha": evento.fecha,
        "nombre_dia": nombre_dia,
        "inicio_minutos": evento.inicio_minutos,
        "fin_minutos": evento.fin_minutos,
        "inicio_hora": minutos_a_hora(evento.inicio_minutos),
        "fin_hora": minutos_a_hora(evento.fin_minutos),
        "duracion_minutos": evento.fin_minutos - evento.inicio_minutos,
        "prioridad": evento.prioridad,
    }


def serializar_disponibilidad(slot: DisponibilidadDB) -> dict:
    return {
        "id": slot.id,
        "dia_semana": slot.dia_semana,
        "nombre_dia": NOMBRES_DIAS[slot.dia_semana],
        "inicio_minutos": slot.inicio_minutos,
        "fin_minutos": slot.fin_minutos,
        "inicio_hora": minutos_a_hora(slot.inicio_minutos),
        "fin_hora": minutos_a_hora(slot.fin_minutos),
    }


def serializar_bloque(bloque: BloquePlanDB) -> dict:
    return {
        "id": bloque.id,
        "objetivo_id": bloque.objetivo_id,
        "es_fijo": False,
        "titulo_objetivo": bloque.objetivo.titulo if bloque.objetivo else "",
        "tipo_objetivo": bloque.objetivo.tipo if bloque.objetivo else "",
        "detalle_objetivo": bloque.objetivo.detalle if bloque.objetivo else None,
        "dia_semana": bloque.dia_semana,
        "nombre_dia": NOMBRES_DIAS[bloque.dia_semana],
        "fecha": fecha_iso_desde_dia_semana(bloque.dia_semana),
        "inicio_minutos": bloque.inicio_minutos,
        "fin_minutos": bloque.fin_minutos,
        "inicio_hora": minutos_a_hora(bloque.inicio_minutos),
        "fin_hora": minutos_a_hora(bloque.fin_minutos),
        "duracion_minutos": bloque.fin_minutos - bloque.inicio_minutos,
        "estado": bloque.estado,
        "replanificado": bloque.replanificado,
    }


def serializar_evento_como_bloque(evento: EventoFijoDB) -> dict:
    try:
        fecha_evento = date.fromisoformat(evento.fecha)
        dia_semana = fecha_evento.weekday()
        nombre_dia = NOMBRES_DIAS[dia_semana]
    except ValueError:
        dia_semana = 0
        nombre_dia = "Dia"

    return {
        "id": evento.id,
        "objetivo_id": 0,
        "es_fijo": True,
        "titulo_objetivo": evento.titulo,
        "tipo_objetivo": "evento_fijo",
        "detalle_objetivo": evento.detalle,
        "dia_semana": dia_semana,
        "nombre_dia": nombre_dia,
        "fecha": evento.fecha,
        "inicio_minutos": evento.inicio_minutos,
        "fin_minutos": evento.fin_minutos,
        "inicio_hora": minutos_a_hora(evento.inicio_minutos),
        "fin_hora": minutos_a_hora(evento.fin_minutos),
        "duracion_minutos": evento.fin_minutos - evento.inicio_minutos,
        "estado": "fijo",
        "replanificado": False,
    }


def objetivo_orden(objetivo: ObjetivoDB) -> tuple[int, int]:
    urgencia = 99
    if objetivo.fecha_limite:
        try:
            urgencia = max(0, (date.fromisoformat(objetivo.fecha_limite) - date.today()).days)
        except ValueError:
            urgencia = 99
    return (urgencia, -objetivo.prioridad)


def construir_ocupacion(
    bloques_ocupados: list[BloquePlanDB],
    eventos_fijos: list[EventoFijoDB],
) -> dict[int, list[tuple[int, int]]]:
    bloques_por_dia: dict[int, list[tuple[int, int]]] = {}
    for bloque in bloques_ocupados:
        if bloque.estado == "pendiente":
            bloques_por_dia.setdefault(bloque.dia_semana, []).append(
                (bloque.inicio_minutos, bloque.fin_minutos)
            )

    for evento in eventos_fijos:
        if not fecha_en_semana_actual(evento.fecha):
            continue
        try:
            dia_semana = date.fromisoformat(evento.fecha).weekday()
        except ValueError:
            continue
        bloques_por_dia.setdefault(dia_semana, []).append(
            (evento.inicio_minutos, evento.fin_minutos)
        )

    for bloques_dia in bloques_por_dia.values():
        bloques_dia.sort(key=lambda item: item[0])

    return bloques_por_dia


def obtener_huecos_candidatos(
    disponibilidad: list[DisponibilidadDB],
    bloques_ocupados: list[BloquePlanDB],
    eventos_fijos: list[EventoFijoDB],
    duracion: int,
    dia_minimo: int = 0,
    dia_maximo: int = 6,
) -> list[tuple[int, int]]:
    bloques_por_dia = construir_ocupacion(bloques_ocupados, eventos_fijos)
    candidatos: list[tuple[int, int]] = []

    for slot in sorted(disponibilidad, key=lambda item: (item.dia_semana, item.inicio_minutos)):
        if slot.dia_semana < dia_minimo or slot.dia_semana > dia_maximo:
            continue

        cursor = slot.inicio_minutos
        for bloque in bloques_por_dia.get(slot.dia_semana, []):
            inicio_bloque, fin_bloque = bloque
            if cursor + duracion <= inicio_bloque:
                candidatos.append((slot.dia_semana, cursor))
            cursor = max(cursor, fin_bloque)

        if cursor + duracion <= slot.fin_minutos:
            candidatos.append((slot.dia_semana, cursor))

    return candidatos


def primer_hueco(
    disponibilidad: list[DisponibilidadDB],
    bloques_ocupados: list[BloquePlanDB],
    eventos_fijos: list[EventoFijoDB],
    duracion: int,
    dia_minimo: int = 0,
) -> tuple[int, int] | None:
    candidatos = obtener_huecos_candidatos(
        disponibilidad,
        bloques_ocupados,
        eventos_fijos,
        duracion,
        dia_minimo=dia_minimo,
    )
    if candidatos:
        return candidatos[0]

    return None


def dia_maximo_para_tarea_flexible(objetivo: ObjetivoDB) -> int:
    if not objetivo.fecha_limite:
        return 6

    try:
        fecha_limite = date.fromisoformat(objetivo.fecha_limite)
    except ValueError:
        return 6

    inicio_semana, fin_semana = inicio_y_fin_semana_actual()
    if fecha_limite < inicio_semana:
        return 0
    if fecha_limite > fin_semana:
        return 6

    return fecha_limite.weekday()


def dias_con_bloques_objetivo(
    bloques_creados: list[BloquePlanDB],
    objetivo_id: int,
) -> list[int]:
    return [bloque.dia_semana for bloque in bloques_creados if bloque.objetivo_id == objetivo_id]


def elegir_hueco_tarea_flexible(
    objetivo: ObjetivoDB,
    disponibilidad: list[DisponibilidadDB],
    bloques_creados: list[BloquePlanDB],
    eventos_fijos: list[EventoFijoDB],
) -> tuple[int, int] | None:
    dia_maximo = dia_maximo_para_tarea_flexible(objetivo)
    candidatos = obtener_huecos_candidatos(
        disponibilidad,
        bloques_creados,
        eventos_fijos,
        objetivo.duracion_minutos,
        dia_maximo=dia_maximo,
    )
    if not candidatos:
        return None

    dias_usados = dias_con_bloques_objetivo(bloques_creados, objetivo.id)

    def clave(candidato: tuple[int, int]) -> tuple[int, int, int]:
        dia, inicio = candidato
        repite_dia = 1 if dia in dias_usados else 0
        return (repite_dia, dia, inicio)

    return min(candidatos, key=clave)


def elegir_hueco_habito(
    objetivo: ObjetivoDB,
    disponibilidad: list[DisponibilidadDB],
    bloques_creados: list[BloquePlanDB],
    eventos_fijos: list[EventoFijoDB],
    dia_minimo: int = 0,
    dia_maximo: int = 6,
) -> tuple[int, int] | None:
    candidatos = obtener_huecos_candidatos(
        disponibilidad,
        bloques_creados,
        eventos_fijos,
        objetivo.duracion_minutos,
        dia_minimo=dia_minimo,
        dia_maximo=dia_maximo,
    )
    if not candidatos:
        return None

    dias_usados = dias_con_bloques_objetivo(bloques_creados, objetivo.id)
    candidatos = [candidato for candidato in candidatos if candidato[0] not in dias_usados]
    if not candidatos:
        return None

    carga_por_dia: dict[int, int] = {}
    for bloque in bloques_creados:
        if bloque.estado == "pendiente":
            carga_por_dia[bloque.dia_semana] = carga_por_dia.get(bloque.dia_semana, 0) + 1

    def clave(candidato: tuple[int, int]) -> tuple[int, int, int, int, int]:
        dia, inicio = candidato
        consecutivo = 1 if any(abs(dia - usado) <= 1 for usado in dias_usados) else 0
        separacion = 0 if not dias_usados else min(abs(dia - usado) for usado in dias_usados)
        return (
            consecutivo,
            -separacion,
            carga_por_dia.get(dia, 0),
            dia,
            inicio,
        )

    return min(candidatos, key=clave)


def crear_bloque(
    db: Session,
    objetivo: ObjetivoDB,
    dia_semana: int,
    inicio_minutos: int,
    replanificado: bool = False,
) -> BloquePlanDB:
    bloque = BloquePlanDB(
        objetivo_id=objetivo.id,
        dia_semana=dia_semana,
        inicio_minutos=inicio_minutos,
        fin_minutos=inicio_minutos + objetivo.duracion_minutos,
        estado="pendiente",
        replanificado=replanificado,
    )
    db.add(bloque)
    db.flush()
    return bloque


def obtener_plan_semanal(db: Session) -> dict:
    objetivos = db.query(ObjetivoDB).order_by(ObjetivoDB.fecha_creacion.desc()).all()
    tareas_flexibles = [item for item in objetivos if item.tipo == "fecha_limite"]
    habitos = [item for item in objetivos if item.tipo == "habito"]
    eventos_fijos = (
        db.query(EventoFijoDB)
        .order_by(EventoFijoDB.fecha, EventoFijoDB.inicio_minutos)
        .all()
    )
    disponibilidad = (
        db.query(DisponibilidadDB)
        .order_by(DisponibilidadDB.dia_semana, DisponibilidadDB.inicio_minutos)
        .all()
    )
    bloques = (
        db.query(BloquePlanDB)
        .options(joinedload(BloquePlanDB.objetivo))
        .order_by(BloquePlanDB.dia_semana, BloquePlanDB.inicio_minutos)
        .all()
    )

    dias = []
    for indice, nombre in enumerate(NOMBRES_DIAS):
        fecha_dia = fecha_iso_desde_dia_semana(indice)
        bloques_dia = [serializar_bloque(bloque) for bloque in bloques if bloque.dia_semana == indice]
        eventos_dia = [
            serializar_evento_como_bloque(evento)
            for evento in eventos_fijos
            if evento.fecha == fecha_dia
        ]
        agenda_dia = sorted(
            [*bloques_dia, *eventos_dia],
            key=lambda item: item["inicio_minutos"],
        )
        dias.append(
            {
                "dia_semana": indice,
                "nombre_dia": nombre,
                "fecha": fecha_dia,
                "bloques": agenda_dia,
            }
        )

    return {
        "objetivos": [serializar_objetivo(objetivo) for objetivo in objetivos],
        "tareas_flexibles": [serializar_tarea_flexible(item) for item in tareas_flexibles],
        "habitos": [serializar_habito(item) for item in habitos],
        "eventos_fijos": [serializar_evento_fijo(evento) for evento in eventos_fijos],
        "disponibilidad": [serializar_disponibilidad(slot) for slot in disponibilidad],
        "dias": dias,
        "estadisticas": {
            "objetivos_activos": len([item for item in objetivos if not item.completado]),
            "bloques_pendientes": len([item for item in bloques if item.estado == "pendiente"]),
            "bloques_hechos": len([item for item in bloques if item.estado == "hecho"]),
        },
    }


def planificar_semana(db: Session) -> dict:
    disponibilidad = (
        db.query(DisponibilidadDB)
        .order_by(DisponibilidadDB.dia_semana, DisponibilidadDB.inicio_minutos)
        .all()
    )
    if not disponibilidad:
        raise HTTPException(status_code=400, detail="Primero configura tu disponibilidad")

    eventos_fijos = (
        db.query(EventoFijoDB)
        .order_by(EventoFijoDB.fecha, EventoFijoDB.inicio_minutos)
        .all()
    )

    db.query(BloquePlanDB).delete()
    db.commit()

    objetivos = (
        db.query(ObjetivoDB)
        .filter(ObjetivoDB.completado.is_(False))
        .order_by(ObjetivoDB.fecha_creacion.desc())
        .all()
    )
    tareas_flexibles = sorted(
        [item for item in objetivos if item.tipo == "fecha_limite"],
        key=objetivo_orden,
    )
    habitos = sorted(
        [item for item in objetivos if item.tipo == "habito"],
        key=lambda item: (-item.prioridad, item.fecha_creacion),
    )

    bloques_creados: list[BloquePlanDB] = []
    for objetivo in tareas_flexibles:
        sesiones = max(1, objetivo.sesiones_por_semana)
        for _ in range(sesiones):
            hueco = elegir_hueco_tarea_flexible(
                objetivo,
                disponibilidad,
                bloques_creados,
                eventos_fijos,
            )
            if hueco is None:
                break
            dia_semana, inicio_minutos = hueco
            bloque = crear_bloque(db, objetivo, dia_semana, inicio_minutos)
            bloques_creados.append(bloque)

    for objetivo in habitos:
        sesiones = max(1, objetivo.sesiones_por_semana)
        for _ in range(sesiones):
            hueco = elegir_hueco_habito(
                objetivo,
                disponibilidad,
                bloques_creados,
                eventos_fijos,
            )
            if hueco is None:
                break
            dia_semana, inicio_minutos = hueco
            bloque = crear_bloque(db, objetivo, dia_semana, inicio_minutos)
            bloques_creados.append(bloque)

    db.commit()
    return obtener_plan_semanal(db)


class ObjetivoCrear(BaseModel):
    titulo: Annotated[str, Field(min_length=3, max_length=80)]
    detalle: Annotated[str | None, Field(max_length=200)] = None
    tipo: str = Field(pattern="^(fecha_limite|habito)$")
    prioridad: Annotated[int, Field(ge=1, le=5)] = 3
    duracion_minutos: Annotated[int, Field(ge=30, le=180)] = 60
    sesiones_por_semana: Annotated[int, Field(ge=1, le=7)] = 1
    fecha_limite: str | None = None


class TareaFlexibleCrear(BaseModel):
    titulo: Annotated[str, Field(min_length=3, max_length=80)]
    detalle: Annotated[str | None, Field(max_length=200)] = None
    prioridad: Annotated[int, Field(ge=1, le=5)] = 3
    duracion_minutos: Annotated[int, Field(ge=30, le=180)] = 60
    sesiones_por_semana: Annotated[int, Field(ge=1, le=7)] = 1
    fecha_limite: str


class HabitoCrear(BaseModel):
    titulo: Annotated[str, Field(min_length=3, max_length=80)]
    detalle: Annotated[str | None, Field(max_length=200)] = None
    prioridad: Annotated[int, Field(ge=1, le=5)] = 3
    duracion_minutos: Annotated[int, Field(ge=30, le=180)] = 60
    sesiones_por_semana: Annotated[int, Field(ge=1, le=7)] = 1


class EventoFijoCrear(BaseModel):
    titulo: Annotated[str, Field(min_length=3, max_length=80)]
    detalle: Annotated[str | None, Field(max_length=200)] = None
    fecha: str
    inicio_minutos: Annotated[int, Field(ge=0, le=1439)]
    fin_minutos: Annotated[int, Field(ge=1, le=1440)]
    prioridad: Annotated[int, Field(ge=1, le=5)] = 3


class DisponibilidadItem(BaseModel):
    dia_semana: Annotated[int, Field(ge=0, le=6)]
    inicio_minutos: Annotated[int, Field(ge=0, le=1439)]
    fin_minutos: Annotated[int, Field(ge=1, le=1440)]


class DisponibilidadPayload(BaseModel):
    slots: list[DisponibilidadItem]


@app.get("/")
def inicio():
    return {"mensaje": "Organizador semanal funcionando"}


@app.get("/plan-semanal")
def ver_plan_semanal(db: Session = Depends(get_db)):
    return obtener_plan_semanal(db)


@app.post("/objetivos")
def crear_objetivo(payload: ObjetivoCrear, db: Session = Depends(get_db)):
    if payload.fecha_limite:
        try:
            date.fromisoformat(payload.fecha_limite)
        except ValueError as exc:
            raise HTTPException(status_code=400, detail="Fecha limite invalida") from exc

    objetivo = ObjetivoDB(
        titulo=payload.titulo,
        detalle=payload.detalle,
        tipo=payload.tipo,
        prioridad=payload.prioridad,
        duracion_minutos=payload.duracion_minutos,
        sesiones_por_semana=payload.sesiones_por_semana,
        fecha_limite=payload.fecha_limite,
    )
    db.add(objetivo)
    db.commit()
    db.refresh(objetivo)
    return {"mensaje": "Objetivo creado", "objetivo": serializar_objetivo(objetivo)}


@app.post("/tareas-flexibles")
def crear_tarea_flexible(payload: TareaFlexibleCrear, db: Session = Depends(get_db)):
    try:
        date.fromisoformat(payload.fecha_limite)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Fecha limite invalida") from exc

    objetivo = ObjetivoDB(
        titulo=payload.titulo,
        detalle=payload.detalle,
        tipo="fecha_limite",
        prioridad=payload.prioridad,
        duracion_minutos=payload.duracion_minutos,
        sesiones_por_semana=payload.sesiones_por_semana,
        fecha_limite=payload.fecha_limite,
    )
    db.add(objetivo)
    db.commit()
    db.refresh(objetivo)
    return {
        "mensaje": "Tarea flexible creada",
        "tarea_flexible": serializar_tarea_flexible(objetivo),
    }


@app.post("/habitos")
def crear_habito(payload: HabitoCrear, db: Session = Depends(get_db)):
    objetivo = ObjetivoDB(
        titulo=payload.titulo,
        detalle=payload.detalle,
        tipo="habito",
        prioridad=payload.prioridad,
        duracion_minutos=payload.duracion_minutos,
        sesiones_por_semana=payload.sesiones_por_semana,
        fecha_limite=None,
    )
    db.add(objetivo)
    db.commit()
    db.refresh(objetivo)
    return {"mensaje": "Habito creado", "habito": serializar_habito(objetivo)}


@app.post("/eventos-fijos")
def crear_evento_fijo(payload: EventoFijoCrear, db: Session = Depends(get_db)):
    try:
        date.fromisoformat(payload.fecha)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Fecha del evento invalida") from exc

    if payload.fin_minutos <= payload.inicio_minutos:
        raise HTTPException(status_code=400, detail="La hora de fin debe ser posterior")

    evento = EventoFijoDB(
        titulo=payload.titulo,
        detalle=payload.detalle,
        fecha=payload.fecha,
        inicio_minutos=payload.inicio_minutos,
        fin_minutos=payload.fin_minutos,
        prioridad=payload.prioridad,
    )
    db.add(evento)
    db.commit()
    db.refresh(evento)
    return {"mensaje": "Evento fijo creado", "evento_fijo": serializar_evento_fijo(evento)}


@app.put("/eventos-fijos/{evento_id}")
def actualizar_evento_fijo(
    evento_id: int,
    payload: EventoFijoCrear,
    db: Session = Depends(get_db),
):
    evento = db.query(EventoFijoDB).filter(EventoFijoDB.id == evento_id).first()
    if not evento:
        raise HTTPException(status_code=404, detail="Evento fijo no encontrado")

    try:
        date.fromisoformat(payload.fecha)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Fecha del evento invalida") from exc

    if payload.fin_minutos <= payload.inicio_minutos:
        raise HTTPException(status_code=400, detail="La hora de fin debe ser posterior")

    evento.titulo = payload.titulo
    evento.detalle = payload.detalle
    evento.fecha = payload.fecha
    evento.inicio_minutos = payload.inicio_minutos
    evento.fin_minutos = payload.fin_minutos
    evento.prioridad = payload.prioridad
    db.commit()
    db.refresh(evento)
    return {
        "mensaje": "Evento fijo actualizado",
        "evento_fijo": serializar_evento_fijo(evento),
    }


@app.delete("/eventos-fijos/{evento_id}")
def eliminar_evento_fijo(evento_id: int, db: Session = Depends(get_db)):
    evento = db.query(EventoFijoDB).filter(EventoFijoDB.id == evento_id).first()
    if not evento:
        raise HTTPException(status_code=404, detail="Evento fijo no encontrado")

    db.delete(evento)
    db.commit()
    return {"mensaje": "Evento fijo eliminado"}


@app.get("/objetivos")
def listar_objetivos(db: Session = Depends(get_db)):
    objetivos = db.query(ObjetivoDB).order_by(ObjetivoDB.fecha_creacion.desc()).all()
    return [serializar_objetivo(objetivo) for objetivo in objetivos]


@app.get("/tareas-flexibles")
def listar_tareas_flexibles(db: Session = Depends(get_db)):
    tareas = (
        db.query(ObjetivoDB)
        .filter(ObjetivoDB.tipo == "fecha_limite")
        .order_by(ObjetivoDB.fecha_creacion.desc())
        .all()
    )
    return [serializar_tarea_flexible(item) for item in tareas]


@app.get("/habitos")
def listar_habitos(db: Session = Depends(get_db)):
    habitos = (
        db.query(ObjetivoDB)
        .filter(ObjetivoDB.tipo == "habito")
        .order_by(ObjetivoDB.fecha_creacion.desc())
        .all()
    )
    return [serializar_habito(item) for item in habitos]


@app.patch("/objetivos/{objetivo_id}/completar")
def completar_objetivo(objetivo_id: int, db: Session = Depends(get_db)):
    objetivo = db.query(ObjetivoDB).filter(ObjetivoDB.id == objetivo_id).first()
    if not objetivo:
        raise HTTPException(status_code=404, detail="Objetivo no encontrado")

    objetivo.completado = True
    db.query(BloquePlanDB).filter(BloquePlanDB.objetivo_id == objetivo_id).delete()
    db.commit()
    return {"mensaje": "Objetivo completado"}


@app.delete("/objetivos/{objetivo_id}")
def eliminar_objetivo(objetivo_id: int, db: Session = Depends(get_db)):
    objetivo = db.query(ObjetivoDB).filter(ObjetivoDB.id == objetivo_id).first()
    if not objetivo:
        raise HTTPException(status_code=404, detail="Objetivo no encontrado")
    if not objetivo.completado:
        raise HTTPException(
            status_code=400,
            detail="Solo puedes eliminar objetivos que ya esten completados",
        )

    db.query(BloquePlanDB).filter(BloquePlanDB.objetivo_id == objetivo_id).delete()
    db.delete(objetivo)
    db.commit()
    return {"mensaje": "Objetivo eliminado"}


@app.post("/disponibilidad")
def guardar_disponibilidad(payload: DisponibilidadPayload, db: Session = Depends(get_db)):
    for slot in payload.slots:
        if slot.fin_minutos <= slot.inicio_minutos:
            raise HTTPException(status_code=400, detail="Cada bloque debe terminar despues de empezar")

    db.query(DisponibilidadDB).delete()
    db.commit()

    for slot in payload.slots:
        db.add(
            DisponibilidadDB(
                dia_semana=slot.dia_semana,
                inicio_minutos=slot.inicio_minutos,
                fin_minutos=slot.fin_minutos,
            )
        )

    db.commit()
    return {"mensaje": "Disponibilidad guardada"}


@app.get("/disponibilidad")
def ver_disponibilidad(db: Session = Depends(get_db)):
    slots = (
        db.query(DisponibilidadDB)
        .order_by(DisponibilidadDB.dia_semana, DisponibilidadDB.inicio_minutos)
        .all()
    )
    return [serializar_disponibilidad(slot) for slot in slots]


@app.post("/planificar-semana")
def ejecutar_planificacion(db: Session = Depends(get_db)):
    return planificar_semana(db)


@app.patch("/bloques/{bloque_id}/hecho")
def marcar_bloque_hecho(bloque_id: int, db: Session = Depends(get_db)):
    bloque = (
        db.query(BloquePlanDB)
        .options(joinedload(BloquePlanDB.objetivo))
        .filter(BloquePlanDB.id == bloque_id)
        .first()
    )
    if not bloque:
        raise HTTPException(status_code=404, detail="Bloque no encontrado")

    bloque.estado = "hecho"
    db.commit()
    db.refresh(bloque)
    return {"mensaje": "Bloque completado", "bloque": serializar_bloque(bloque)}


@app.patch("/bloques/{bloque_id}/fallado")
def marcar_bloque_fallado(bloque_id: int, db: Session = Depends(get_db)):
    bloque = (
        db.query(BloquePlanDB)
        .options(joinedload(BloquePlanDB.objetivo))
        .filter(BloquePlanDB.id == bloque_id)
        .first()
    )
    if not bloque:
        raise HTTPException(status_code=404, detail="Bloque no encontrado")

    bloque.estado = "fallado"
    disponibilidad = (
        db.query(DisponibilidadDB)
        .order_by(DisponibilidadDB.dia_semana, DisponibilidadDB.inicio_minutos)
        .all()
    )
    otros_bloques = (
        db.query(BloquePlanDB)
        .filter(BloquePlanDB.id != bloque.id)
        .order_by(BloquePlanDB.dia_semana, BloquePlanDB.inicio_minutos)
        .all()
    )
    eventos_fijos = (
        db.query(EventoFijoDB)
        .order_by(EventoFijoDB.fecha, EventoFijoDB.inicio_minutos)
        .all()
    )
    dia_minimo_replanificacion = min(bloque.dia_semana + 1, 6)
    if bloque.objetivo and bloque.objetivo.tipo == "habito":
        hueco = elegir_hueco_habito(
            bloque.objetivo,
            disponibilidad,
            otros_bloques,
            eventos_fijos,
            dia_minimo=dia_minimo_replanificacion,
        )
    else:
        hueco = primer_hueco(
            disponibilidad,
            otros_bloques,
            eventos_fijos,
            bloque.fin_minutos - bloque.inicio_minutos,
            dia_minimo=dia_minimo_replanificacion,
        )

    nuevo_bloque = None
    if hueco is not None:
        dia_semana, inicio_minutos = hueco
        nuevo_bloque = crear_bloque(
            db,
            bloque.objetivo,
            dia_semana,
            inicio_minutos,
            replanificado=True,
        )

    db.commit()
    if nuevo_bloque is not None:
        db.refresh(nuevo_bloque)

    return {
        "mensaje": "Bloque replanificado" if nuevo_bloque else "No habia hueco para replanificar",
        "nuevo_bloque": serializar_bloque(nuevo_bloque) if nuevo_bloque else None,
    }
