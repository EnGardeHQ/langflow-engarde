"""add engarde template synchronization fields

Revision ID: engarde_template_001
Revises: 182e5471b900
Create Date: 2026-01-19 18:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = 'engarde_template_001'
down_revision: Union[str, None] = '182e5471b900'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add EnGarde template synchronization fields to flow table"""

    # Check if columns already exist before adding
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    columns = [col['name'] for col in inspector.get_columns('flow')]

    # Add is_admin_template column
    if 'is_admin_template' not in columns:
        op.add_column('flow', sa.Column('is_admin_template', sa.Boolean(), nullable=False, server_default='false'))
        op.create_index('idx_flow_is_admin_template', 'flow', ['is_admin_template'], postgresql_where=sa.text('is_admin_template = true'))
        print("✓ Added is_admin_template column with index")
    else:
        print("✓ is_admin_template column already exists")

    # Add template_source_id column
    if 'template_source_id' not in columns:
        op.add_column('flow', sa.Column('template_source_id', postgresql.UUID(as_uuid=True), nullable=True))
        op.create_index('idx_flow_template_source', 'flow', ['template_source_id'], postgresql_where=sa.text('template_source_id IS NOT NULL'))
        print("✓ Added template_source_id column with index")
    else:
        print("✓ template_source_id column already exists")

    # Add template_version column
    if 'template_version' not in columns:
        op.add_column('flow', sa.Column('template_version', sa.String(), nullable=True))
        print("✓ Added template_version column")
    else:
        print("✓ template_version column already exists")

    # Add custom_settings column
    if 'custom_settings' not in columns:
        op.add_column('flow', sa.Column('custom_settings', postgresql.JSON(astext_type=sa.Text()), nullable=True))
        print("✓ Added custom_settings column")
    else:
        print("✓ custom_settings column already exists")

    # Add last_synced_at column
    if 'last_synced_at' not in columns:
        op.add_column('flow', sa.Column('last_synced_at', sa.DateTime(timezone=True), nullable=True))
        print("✓ Added last_synced_at column")
    else:
        print("✓ last_synced_at column already exists")


def downgrade() -> None:
    """Remove EnGarde template synchronization fields"""

    # Check if columns exist before dropping
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    columns = [col['name'] for col in inspector.get_columns('flow')]

    # Drop columns in reverse order
    if 'last_synced_at' in columns:
        op.drop_column('flow', 'last_synced_at')

    if 'custom_settings' in columns:
        op.drop_column('flow', 'custom_settings')

    if 'template_version' in columns:
        op.drop_column('flow', 'template_version')

    if 'template_source_id' in columns:
        op.drop_index('idx_flow_template_source', table_name='flow')
        op.drop_column('flow', 'template_source_id')

    if 'is_admin_template' in columns:
        op.drop_index('idx_flow_is_admin_template', table_name='flow')
        op.drop_column('flow', 'is_admin_template')
