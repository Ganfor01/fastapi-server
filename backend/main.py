from datetime import date, timedelta
from typing import Annotated

from fastapi import Depends, FastAPI, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import or_, text
from sqlalchemy.orm import Session, joinedload

from database import SessionLocal, engine
from models import BloquePlanDB, DisponibilidadDB, EventoFijoDB, ObjetivoDB

app = FastAPI(title="Organizador Automatico de Vida")

ObjetivoDB.metadata.create_all(bind=engine)


def asegurar_columna_fecha_fin() -> None:
    with engine.begin() as connection:
        columnas = connection.execute(text("PRAGMA table_info(eventos_fijos)")).fetchall()
        nombres = {columna[1] for columna in columnas}
        if "fecha_fin" not in nombres:
            connection.execute(text("ALTER TABLE eventos_fijos ADD COLUMN fecha_fin VARCHAR"))


asegurar_columna_fecha_fin()


def asegurar_columna_semana_inicio() -> None:
    with engine.begin() as connection:
        columnas = connection.execute(text("PRAGMA table_info(bloques_plan)")).fetchall()
        nombres = {columna[1] for columna in columnas}
        if "semana_inicio" not in nombres:
            connection.execute(text("ALTER TABLE bloques_plan ADD COLUMN semana_inicio VARCHAR"))


asegurar_columna_semana_inicio()

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


def inicio_semana_para_offset(week_offset: int = 0) -> date:
    hoy = date.today()
    inicio_semana = hoy - timedelta(days=hoy.weekday())
    return inicio_semana + timedelta(days=week_offset * 7)


def week_offset_desde_semana_inicio(semana_inicio: str | None) -> int:
    if not semana_inicio:
        return 0
    try:
        inicio = date.fromisoformat(semana_inicio)
    except ValueError:
        return 0
    inicio_actual = inicio_semana_para_offset(0)
    return (inicio - inicio_actual).days // 7

def fecha_iso_desde_dia_semana(dia_semana: int, week_offset: int = 0) -> str:
    inicio_semana = inicio_semana_para_offset(week_offset)
    return (inicio_semana + timedelta(days=dia_semana)).isoformat()


def inicio_y_fin_semana(week_offset: int = 0) -> tuple[date, date]:
    inicio_semana = inicio_semana_para_offset(week_offset)
    fin_semana = inicio_semana + timedelta(days=6)
    return (inicio_semana, fin_semana)


def fecha_en_semana(fecha_iso: str, week_offset: int = 0) -> bool:
    try:
        fecha = date.fromisoformat(fecha_iso)
    except ValueError:
        return False
    inicio_semana, fin_semana = inicio_y_fin_semana(week_offset)
    return inicio_semana <= fecha <= fin_semana


def fecha_final_evento(evento: EventoFijoDB) -> str:
    return evento.fecha_fin or evento.fecha


def evento_ocupa_varios_dias(evento: EventoFijoDB) -> bool:
    return fecha_final_evento(evento) != evento.fecha


def fechas_evento_en_semana(evento: EventoFijoDB, week_offset: int = 0) -> list[date]:
    try:
        fecha_inicio = date.fromisoformat(evento.fecha)
        fecha_fin = date.fromisoformat(fecha_final_evento(evento))
    except ValueError:
        return []

    if fecha_fin < fecha_inicio:
        fecha_fin = fecha_inicio

    inicio_semana, fin_semana = inicio_y_fin_semana(week_offset)
    inicio = max(fecha_inicio, inicio_semana)
    fin = min(fecha_fin, fin_semana)
    if fin < inicio:
        return []

    total = (fin - inicio).days + 1
    return [inicio + timedelta(days=indice) for indice in range(total)]


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
        "fecha_fin": fecha_final_evento(evento),
        "nombre_dia": nombre_dia,
        "inicio_minutos": evento.inicio_minutos,
        "fin_minutos": evento.fin_minutos,
        "inicio_hora": minutos_a_hora(evento.inicio_minutos),
        "fin_hora": minutos_a_hora(evento.fin_minutos),
        "duracion_minutos": evento.fin_minutos - evento.inicio_minutos,
        "es_todo_el_dia": evento.inicio_minutos == 0 and evento.fin_minutos == 1440,
        "es_varios_dias": evento_ocupa_varios_dias(evento),
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
    fecha_base = bloque.semana_inicio or fecha_iso_desde_dia_semana(0)
    try:
        fecha = (date.fromisoformat(fecha_base) + timedelta(days=bloque.dia_semana)).isoformat()
    except ValueError:
        fecha = fecha_iso_desde_dia_semana(bloque.dia_semana)

    return {
        "id": bloque.id,
        "objetivo_id": bloque.objetivo_id,
        "es_fijo": False,
        "titulo_objetivo": bloque.objetivo.titulo if bloque.objetivo else "",
        "tipo_objetivo": bloque.objetivo.tipo if bloque.objetivo else "",
        "detalle_objetivo": bloque.objetivo.detalle if bloque.objetivo else None,
        "dia_semana": bloque.dia_semana,
        "nombre_dia": NOMBRES_DIAS[bloque.dia_semana],
        "fecha": fecha,
        "inicio_minutos": bloque.inicio_minutos,
        "fin_minutos": bloque.fin_minutos,
        "inicio_hora": minutos_a_hora(bloque.inicio_minutos),
        "fin_hora": minutos_a_hora(bloque.fin_minutos),
        "duracion_minutos": bloque.fin_minutos - bloque.inicio_minutos,
        "estado": bloque.estado,
        "replanificado": bloque.replanificado,
    }


def serializar_evento_como_bloque(evento: EventoFijoDB, fecha_bloque: date) -> dict:
    try:
        dia_semana = fecha_bloque.weekday()
        nombre_dia = NOMBRES_DIAS[dia_semana]
    except ValueError:
        dia_semana = 0
        nombre_dia = "Dia"

    inicio_minutos = evento.inicio_minutos
    fin_minutos = evento.fin_minutos
    if evento_ocupa_varios_dias(evento):
        inicio_minutos = 0
        fin_minutos = 1440

    return {
        "id": evento.id,
        "objetivo_id": 0,
        "es_fijo": True,
        "titulo_objetivo": evento.titulo,
        "tipo_objetivo": "evento_fijo",
        "detalle_objetivo": evento.detalle,
        "dia_semana": dia_semana,
        "nombre_dia": nombre_dia,
        "fecha": fecha_bloque.isoformat(),
        "inicio_minutos": inicio_minutos,
        "fin_minutos": fin_minutos,
        "inicio_hora": minutos_a_hora(inicio_minutos),
        "fin_hora": minutos_a_hora(fin_minutos),
        "duracion_minutos": fin_minutos - inicio_minutos,
        "estado": "fijo",
        "replanificado": False,
    }


def evento_es_todo_el_dia(evento: EventoFijoDB) -> bool:
    return (
        evento.inicio_minutos == 0 and evento.fin_minutos == 1440
    ) or evento_ocupa_varios_dias(evento)


def construir_ocupacion(
    bloques_ocupados: list[BloquePlanDB],
    eventos_fijos: list[EventoFijoDB],
    week_offset: int = 0,
) -> dict[int, list[tuple[int, int]]]:
    bloques_por_dia: dict[int, list[tuple[int, int]]] = {}
    for bloque in bloques_ocupados:
        if bloque.estado != "fallado":
            bloques_por_dia.setdefault(bloque.dia_semana, []).append(
                (bloque.inicio_minutos, bloque.fin_minutos)
            )

    for evento in eventos_fijos:
        for fecha_evento in fechas_evento_en_semana(evento, week_offset):
            dia_semana = fecha_evento.weekday()
            if evento_ocupa_varios_dias(evento):
                bloques_por_dia.setdefault(dia_semana, []).append((0, 1440))
            else:
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
    week_offset: int = 0,
) -> list[tuple[int, int]]:
    bloques_por_dia = construir_ocupacion(
        bloques_ocupados,
        eventos_fijos,
        week_offset,
    )
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
    week_offset: int = 0,
) -> tuple[int, int] | None:
    candidatos = obtener_huecos_candidatos(
        disponibilidad,
        bloques_ocupados,
        eventos_fijos,
        duracion,
        dia_minimo=dia_minimo,
        week_offset=week_offset,
    )
    if candidatos:
        return candidatos[0]

    return None


def dias_con_bloques_objetivo(
    bloques_creados: list[BloquePlanDB],
    objetivo_id: int,
) -> list[int]:
    return [
        bloque.dia_semana
        for bloque in bloques_creados
        if bloque.objetivo_id == objetivo_id and bloque.estado != "fallado"
    ]


def elegir_hueco_habito(
    objetivo: ObjetivoDB,
    disponibilidad: list[DisponibilidadDB],
    bloques_creados: list[BloquePlanDB],
    eventos_fijos: list[EventoFijoDB],
    dia_minimo: int = 0,
    dia_maximo: int = 6,
    week_offset: int = 0,
) -> tuple[int, int] | None:
    candidatos = obtener_huecos_candidatos(
        disponibilidad,
        bloques_creados,
        eventos_fijos,
        objetivo.duracion_minutos,
        dia_minimo=dia_minimo,
        dia_maximo=dia_maximo,
        week_offset=week_offset,
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


def existe_bloque_habito_en_dia(
    bloques: list[BloquePlanDB],
    objetivo_id: int,
    dia_semana: int,
) -> bool:
    return any(
        bloque.objetivo_id == objetivo_id
        and bloque.dia_semana == dia_semana
        and bloque.estado != "fallado"
        for bloque in bloques
    )


def crear_bloque(
    db: Session,
    objetivo: ObjetivoDB,
    semana_inicio: str,
    dia_semana: int,
    inicio_minutos: int,
    replanificado: bool = False,
) -> BloquePlanDB:
    bloque = BloquePlanDB(
        objetivo_id=objetivo.id,
        semana_inicio=semana_inicio,
        dia_semana=dia_semana,
        inicio_minutos=inicio_minutos,
        fin_minutos=inicio_minutos + objetivo.duracion_minutos,
        estado="pendiente",
        replanificado=replanificado,
    )
    db.add(bloque)
    db.flush()
    return bloque


def obtener_plan_semanal(db: Session, week_offset: int = 0) -> dict:
    semana_inicio = inicio_semana_para_offset(week_offset).isoformat()
    objetivos = (
        db.query(ObjetivoDB)
        .filter(ObjetivoDB.tipo == "habito")
        .order_by(ObjetivoDB.fecha_creacion.desc())
        .all()
    )
    habitos = objetivos
    eventos_fijos = (
        db.query(EventoFijoDB)
        .order_by(EventoFijoDB.fecha, EventoFijoDB.fecha_fin, EventoFijoDB.inicio_minutos)
        .all()
    )
    disponibilidad = (
        db.query(DisponibilidadDB)
        .order_by(DisponibilidadDB.dia_semana, DisponibilidadDB.inicio_minutos)
        .all()
    )
    bloques_query = (
        db.query(BloquePlanDB)
        .options(joinedload(BloquePlanDB.objetivo))
        .order_by(BloquePlanDB.dia_semana, BloquePlanDB.inicio_minutos)
    )
    if week_offset == 0:
        bloques_query = bloques_query.filter(
            or_(
                BloquePlanDB.semana_inicio == semana_inicio,
                BloquePlanDB.semana_inicio.is_(None),
            )
        )
    else:
        bloques_query = bloques_query.filter(BloquePlanDB.semana_inicio == semana_inicio)
    bloques = bloques_query.all()
    dias = []
    for indice, nombre in enumerate(NOMBRES_DIAS):
        fecha_dia = fecha_iso_desde_dia_semana(indice, week_offset)
        fecha_actual = date.fromisoformat(fecha_dia)
        eventos_dia = [
            serializar_evento_como_bloque(evento, fecha_actual)
            for evento in eventos_fijos
            if fecha_actual in fechas_evento_en_semana(evento, week_offset)
        ]
        hay_evento_todo_el_dia = any(
            fecha_actual in fechas_evento_en_semana(evento, week_offset)
            and evento_es_todo_el_dia(evento)
            for evento in eventos_fijos
        )
        bloques_dia = [] if hay_evento_todo_el_dia else [
            serializar_bloque(bloque) for bloque in bloques if bloque.dia_semana == indice
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
        "habitos": [serializar_habito(item) for item in habitos],
        "eventos_fijos": [serializar_evento_fijo(evento) for evento in eventos_fijos],
        "disponibilidad": [serializar_disponibilidad(slot) for slot in disponibilidad],
        "dias": dias,
        "week_offset": week_offset,
        "semana_inicio": semana_inicio,
        "estadisticas": {
            "objetivos_activos": len([item for item in objetivos if not item.completado]),
            "bloques_pendientes": len([item for item in bloques if item.estado == "pendiente"]),
            "bloques_hechos": len([item for item in bloques if item.estado == "hecho"]),
        },
    }


def planificar_semana(db: Session, week_offset: int = 0) -> dict:
    semana_inicio = inicio_semana_para_offset(week_offset).isoformat()
    disponibilidad = (
        db.query(DisponibilidadDB)
        .order_by(DisponibilidadDB.dia_semana, DisponibilidadDB.inicio_minutos)
        .all()
    )
    if not disponibilidad:
        raise HTTPException(status_code=400, detail="Primero configura tu disponibilidad")

    eventos_fijos = (
        db.query(EventoFijoDB)
        .order_by(EventoFijoDB.fecha, EventoFijoDB.fecha_fin, EventoFijoDB.inicio_minutos)
        .all()
    )

    if week_offset == 0:
        db.query(BloquePlanDB).filter(
            or_(
                BloquePlanDB.semana_inicio == semana_inicio,
                BloquePlanDB.semana_inicio.is_(None),
            )
        ).delete()
    else:
        db.query(BloquePlanDB).filter(BloquePlanDB.semana_inicio == semana_inicio).delete()
    db.commit()

    objetivos = (
        db.query(ObjetivoDB)
        .filter(ObjetivoDB.completado.is_(False))
        .order_by(ObjetivoDB.fecha_creacion.desc())
        .all()
    )
    habitos = sorted(
        [item for item in objetivos if item.tipo == "habito"],
        key=lambda item: (-item.prioridad, item.fecha_creacion),
    )

    bloques_creados: list[BloquePlanDB] = []
    for objetivo in habitos:
        sesiones = max(1, objetivo.sesiones_por_semana)
        for _ in range(sesiones):
            hueco = elegir_hueco_habito(
                objetivo,
                disponibilidad,
                bloques_creados,
                eventos_fijos,
                week_offset=week_offset,
            )
            if hueco is None:
                break
            dia_semana, inicio_minutos = hueco
            bloque = crear_bloque(
                db,
                objetivo,
                semana_inicio,
                dia_semana,
                inicio_minutos,
            )
            bloques_creados.append(bloque)

    db.commit()
    return obtener_plan_semanal(db, week_offset)


class ObjetivoCrear(BaseModel):
    titulo: Annotated[str, Field(min_length=3, max_length=80)]
    detalle: Annotated[str | None, Field(max_length=200)] = None
    tipo: str = Field(pattern="^habito$")
    prioridad: Annotated[int, Field(ge=1, le=5)] = 3
    duracion_minutos: Annotated[int, Field(ge=30, le=180)] = 60
    sesiones_por_semana: Annotated[int, Field(ge=1, le=7)] = 1


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
    fecha_fin: str | None = None
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
def ver_plan_semanal(week_offset: int = 0, db: Session = Depends(get_db)):
    return obtener_plan_semanal(db, week_offset)


@app.post("/objetivos")
def crear_objetivo(payload: ObjetivoCrear, db: Session = Depends(get_db)):
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
    return {"mensaje": "Objetivo creado", "objetivo": serializar_objetivo(objetivo)}


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
    return {"mensaje": "Hábito creado", "habito": serializar_habito(objetivo)}


@app.post("/eventos-fijos")
def crear_evento_fijo(payload: EventoFijoCrear, db: Session = Depends(get_db)):
    try:
        fecha_inicio = date.fromisoformat(payload.fecha)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Fecha del evento invalida") from exc

    fecha_fin = payload.fecha_fin or payload.fecha
    try:
        fecha_fin_date = date.fromisoformat(fecha_fin)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Fecha de vuelta invalida") from exc

    if fecha_fin_date < fecha_inicio:
        raise HTTPException(status_code=400, detail="La fecha de vuelta no puede ser anterior")

    if payload.fin_minutos <= payload.inicio_minutos:
        raise HTTPException(status_code=400, detail="La hora de fin debe ser posterior")

    evento = EventoFijoDB(
        titulo=payload.titulo,
        detalle=payload.detalle,
        fecha=payload.fecha,
        fecha_fin=fecha_fin,
        inicio_minutos=0 if fecha_fin != payload.fecha else payload.inicio_minutos,
        fin_minutos=1440 if fecha_fin != payload.fecha else payload.fin_minutos,
        prioridad=payload.prioridad,
    )
    db.add(evento)
    db.commit()
    db.refresh(evento)
    return {"mensaje": "Evento creado", "evento_fijo": serializar_evento_fijo(evento)}


@app.put("/eventos-fijos/{evento_id}")
def actualizar_evento_fijo(
    evento_id: int,
    payload: EventoFijoCrear,
    db: Session = Depends(get_db),
):
    evento = db.query(EventoFijoDB).filter(EventoFijoDB.id == evento_id).first()
    if not evento:
        raise HTTPException(status_code=404, detail="Evento no encontrado")

    try:
        fecha_inicio = date.fromisoformat(payload.fecha)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Fecha del evento invalida") from exc

    fecha_fin = payload.fecha_fin or payload.fecha
    try:
        fecha_fin_date = date.fromisoformat(fecha_fin)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Fecha de vuelta invalida") from exc

    if fecha_fin_date < fecha_inicio:
        raise HTTPException(status_code=400, detail="La fecha de vuelta no puede ser anterior")

    if payload.fin_minutos <= payload.inicio_minutos:
        raise HTTPException(status_code=400, detail="La hora de fin debe ser posterior")

    evento.titulo = payload.titulo
    evento.detalle = payload.detalle
    evento.fecha = payload.fecha
    evento.fecha_fin = fecha_fin
    evento.inicio_minutos = 0 if fecha_fin != payload.fecha else payload.inicio_minutos
    evento.fin_minutos = 1440 if fecha_fin != payload.fecha else payload.fin_minutos
    evento.prioridad = payload.prioridad
    db.commit()
    db.refresh(evento)
    return {
        "mensaje": "Evento actualizado",
        "evento_fijo": serializar_evento_fijo(evento),
    }


@app.delete("/eventos-fijos/{evento_id}")
def eliminar_evento_fijo(evento_id: int, db: Session = Depends(get_db)):
    evento = db.query(EventoFijoDB).filter(EventoFijoDB.id == evento_id).first()
    if not evento:
        raise HTTPException(status_code=404, detail="Evento no encontrado")

    db.delete(evento)
    db.commit()
    return {"mensaje": "Evento eliminado"}


@app.get("/objetivos")
def listar_objetivos(db: Session = Depends(get_db)):
    objetivos = (
        db.query(ObjetivoDB)
        .filter(ObjetivoDB.tipo == "habito")
        .order_by(ObjetivoDB.fecha_creacion.desc())
        .all()
    )
    return [serializar_objetivo(objetivo) for objetivo in objetivos]


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
def ejecutar_planificacion(week_offset: int = 0, db: Session = Depends(get_db)):
    return planificar_semana(db, week_offset)


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
    otros_bloques_query = (
        db.query(BloquePlanDB)
        .filter(BloquePlanDB.id != bloque.id)
        .order_by(BloquePlanDB.dia_semana, BloquePlanDB.inicio_minutos)
    )
    if bloque.semana_inicio is None:
        otros_bloques_query = otros_bloques_query.filter(BloquePlanDB.semana_inicio.is_(None))
    else:
        otros_bloques_query = otros_bloques_query.filter(BloquePlanDB.semana_inicio == bloque.semana_inicio)
    otros_bloques = otros_bloques_query.all()
    eventos_fijos = (
        db.query(EventoFijoDB)
        .order_by(EventoFijoDB.fecha, EventoFijoDB.inicio_minutos)
        .all()
    )
    week_offset = week_offset_desde_semana_inicio(bloque.semana_inicio)
    dia_minimo_replanificacion = min(bloque.dia_semana + 1, 6)
    if bloque.objetivo and bloque.objetivo.tipo == "habito":
        hueco = elegir_hueco_habito(
            bloque.objetivo,
            disponibilidad,
            otros_bloques,
            eventos_fijos,
            dia_minimo=dia_minimo_replanificacion,
            week_offset=week_offset,
        )
    else:
        hueco = primer_hueco(
            disponibilidad,
            otros_bloques,
            eventos_fijos,
            bloque.fin_minutos - bloque.inicio_minutos,
            dia_minimo=dia_minimo_replanificacion,
            week_offset=week_offset,
        )

    nuevo_bloque = None
    if hueco is not None:
        dia_semana, inicio_minutos = hueco
        if bloque.objetivo and bloque.objetivo.tipo == "habito":
            if existe_bloque_habito_en_dia(otros_bloques, bloque.objetivo_id, dia_semana):
                hueco = None

        if hueco is not None:
            nuevo_bloque = crear_bloque(
                db,
                bloque.objetivo,
                bloque.semana_inicio or inicio_semana_para_offset().isoformat(),
                dia_semana,
                inicio_minutos,
                replanificado=True,
            )

    db.commit()
    if nuevo_bloque is not None:
        db.refresh(nuevo_bloque)

    if bloque.objetivo and bloque.objetivo.tipo == "habito" and nuevo_bloque is None:
        return {
            "mensaje": "No hay más huecos esta semana para cumplir este hábito",
            "nuevo_bloque": None,
        }

    return {
        "mensaje": "Bloque replanificado" if nuevo_bloque else "No habia hueco para replanificar",
        "nuevo_bloque": serializar_bloque(nuevo_bloque) if nuevo_bloque else None,
    }
