"""initial schema

Revision ID: 20260421_0001
Revises:
Create Date: 2026-04-21 00:00:00
"""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa


revision = "20260421_0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "disponibilidad",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("dia_semana", sa.Integer(), nullable=False),
        sa.Column("inicio_minutos", sa.Integer(), nullable=False),
        sa.Column("fin_minutos", sa.Integer(), nullable=False),
    )

    op.create_table(
        "eventos_fijos",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("titulo", sa.String(), nullable=False),
        sa.Column("detalle", sa.String(), nullable=True),
        sa.Column("fecha", sa.String(), nullable=False),
        sa.Column("fecha_fin", sa.String(), nullable=True),
        sa.Column("inicio_minutos", sa.Integer(), nullable=False),
        sa.Column("fin_minutos", sa.Integer(), nullable=False),
        sa.Column("prioridad", sa.Integer(), nullable=False, server_default="3"),
        sa.Column("completado", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("fecha_creacion", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_eventos_fijos_id", "eventos_fijos", ["id"])
    op.create_index("ix_eventos_fijos_titulo", "eventos_fijos", ["titulo"])

    op.create_table(
        "notas_dia",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("fecha", sa.String(), nullable=False),
        sa.Column("nota", sa.String(), nullable=False),
        sa.Column("fecha_actualizacion", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_notas_dia_id", "notas_dia", ["id"])
    op.create_index("ix_notas_dia_fecha", "notas_dia", ["fecha"], unique=True)

    op.create_table(
        "objetivos",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("titulo", sa.String(), nullable=False),
        sa.Column("detalle", sa.String(), nullable=True),
        sa.Column("tipo", sa.String(), nullable=False),
        sa.Column("prioridad", sa.Integer(), nullable=False, server_default="3"),
        sa.Column("duracion_minutos", sa.Integer(), nullable=False, server_default="60"),
        sa.Column("sesiones_por_semana", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("fecha_limite", sa.String(), nullable=True),
        sa.Column("completado", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("fecha_creacion", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_objetivos_id", "objetivos", ["id"])
    op.create_index("ix_objetivos_titulo", "objetivos", ["titulo"])

    op.create_table(
        "bloques_plan",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("objetivo_id", sa.Integer(), sa.ForeignKey("objetivos.id"), nullable=False),
        sa.Column("semana_inicio", sa.String(), nullable=True),
        sa.Column("dia_semana", sa.Integer(), nullable=False),
        sa.Column("inicio_minutos", sa.Integer(), nullable=False),
        sa.Column("fin_minutos", sa.Integer(), nullable=False),
        sa.Column("estado", sa.String(), nullable=False, server_default="pendiente"),
        sa.Column("replanificado", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("fecha_creacion", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_bloques_plan_id", "bloques_plan", ["id"])

    op.create_table(
        "eventos_fijos_notas",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("evento_id", sa.Integer(), sa.ForeignKey("eventos_fijos.id"), nullable=False),
        sa.Column("fecha", sa.String(), nullable=False),
        sa.Column("nota", sa.String(), nullable=False),
    )
    op.create_index("ix_eventos_fijos_notas_id", "eventos_fijos_notas", ["id"])
    op.create_index("ix_eventos_fijos_notas_fecha", "eventos_fijos_notas", ["fecha"])

    op.create_table(
        "habitos_progreso",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("objetivo_id", sa.Integer(), sa.ForeignKey("objetivos.id"), nullable=False),
        sa.Column("semana_inicio", sa.String(), nullable=False),
        sa.Column("sesiones_completadas", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("fecha_actualizacion", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_habitos_progreso_id", "habitos_progreso", ["id"])
    op.create_index("ix_habitos_progreso_semana_inicio", "habitos_progreso", ["semana_inicio"])


def downgrade() -> None:
    op.drop_index("ix_habitos_progreso_semana_inicio", table_name="habitos_progreso")
    op.drop_index("ix_habitos_progreso_id", table_name="habitos_progreso")
    op.drop_table("habitos_progreso")

    op.drop_index("ix_eventos_fijos_notas_fecha", table_name="eventos_fijos_notas")
    op.drop_index("ix_eventos_fijos_notas_id", table_name="eventos_fijos_notas")
    op.drop_table("eventos_fijos_notas")

    op.drop_index("ix_bloques_plan_id", table_name="bloques_plan")
    op.drop_table("bloques_plan")

    op.drop_index("ix_objetivos_titulo", table_name="objetivos")
    op.drop_index("ix_objetivos_id", table_name="objetivos")
    op.drop_table("objetivos")

    op.drop_index("ix_notas_dia_fecha", table_name="notas_dia")
    op.drop_index("ix_notas_dia_id", table_name="notas_dia")
    op.drop_table("notas_dia")

    op.drop_index("ix_eventos_fijos_titulo", table_name="eventos_fijos")
    op.drop_index("ix_eventos_fijos_id", table_name="eventos_fijos")
    op.drop_table("eventos_fijos")

    op.drop_table("disponibilidad")
