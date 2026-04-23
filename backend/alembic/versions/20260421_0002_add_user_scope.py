"""add user scope to app data

Revision ID: 20260421_0002
Revises: 20260421_0001
Create Date: 2026-04-21 00:30:00
"""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa


revision = "20260421_0002"
down_revision = "20260421_0001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("objetivos", sa.Column("user_id", sa.String(), nullable=True))
    op.create_index("ix_objetivos_user_id", "objetivos", ["user_id"])

    op.add_column("eventos_fijos", sa.Column("user_id", sa.String(), nullable=True))
    op.create_index("ix_eventos_fijos_user_id", "eventos_fijos", ["user_id"])

    op.add_column("disponibilidad", sa.Column("user_id", sa.String(), nullable=True))
    op.create_index("ix_disponibilidad_user_id", "disponibilidad", ["user_id"])

    op.add_column("bloques_plan", sa.Column("user_id", sa.String(), nullable=True))
    op.create_index("ix_bloques_plan_user_id", "bloques_plan", ["user_id"])

    op.add_column("habitos_progreso", sa.Column("user_id", sa.String(), nullable=True))
    op.create_index("ix_habitos_progreso_user_id", "habitos_progreso", ["user_id"])
    op.create_unique_constraint(
        "uq_habitos_progreso_user_objetivo_semana",
        "habitos_progreso",
        ["user_id", "objetivo_id", "semana_inicio"],
    )

    op.add_column("eventos_fijos_notas", sa.Column("user_id", sa.String(), nullable=True))
    op.create_index("ix_eventos_fijos_notas_user_id", "eventos_fijos_notas", ["user_id"])

    op.add_column("notas_dia", sa.Column("user_id", sa.String(), nullable=True))
    op.create_index("ix_notas_dia_user_id", "notas_dia", ["user_id"])
    op.drop_index("ix_notas_dia_fecha", table_name="notas_dia")
    op.create_index("ix_notas_dia_fecha", "notas_dia", ["fecha"], unique=False)
    op.create_unique_constraint("uq_notas_dia_user_fecha", "notas_dia", ["user_id", "fecha"])


def downgrade() -> None:
    op.drop_constraint("uq_notas_dia_user_fecha", "notas_dia", type_="unique")
    op.drop_index("ix_notas_dia_fecha", table_name="notas_dia")
    op.create_index("ix_notas_dia_fecha", "notas_dia", ["fecha"], unique=True)
    op.drop_index("ix_notas_dia_user_id", table_name="notas_dia")
    op.drop_column("notas_dia", "user_id")

    op.drop_index("ix_eventos_fijos_notas_user_id", table_name="eventos_fijos_notas")
    op.drop_column("eventos_fijos_notas", "user_id")

    op.drop_constraint(
        "uq_habitos_progreso_user_objetivo_semana",
        "habitos_progreso",
        type_="unique",
    )
    op.drop_index("ix_habitos_progreso_user_id", table_name="habitos_progreso")
    op.drop_column("habitos_progreso", "user_id")

    op.drop_index("ix_bloques_plan_user_id", table_name="bloques_plan")
    op.drop_column("bloques_plan", "user_id")

    op.drop_index("ix_disponibilidad_user_id", table_name="disponibilidad")
    op.drop_column("disponibilidad", "user_id")

    op.drop_index("ix_eventos_fijos_user_id", table_name="eventos_fijos")
    op.drop_column("eventos_fijos", "user_id")

    op.drop_index("ix_objetivos_user_id", table_name="objetivos")
    op.drop_column("objetivos", "user_id")
