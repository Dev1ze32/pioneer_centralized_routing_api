#!/usr/bin/env python3
"""
Bootstrap script: create the first admin user from the command line.

Usage
-----
    python create_admin.py <username> <password>

Example
-------
    python create_admin.py admin AdminPass123!

This is useful for the very first deployment when no users exist yet.
After creating the first admin, you can use /api/auth/register with
an admin JWT to create additional privileged accounts.
"""

import sys

from routes.auth_utils import hash_password
from routes.models import User, managed_db_session


def create_admin(username: str, password: str):
    """Create an admin user, or update existing user to admin."""
    with managed_db_session() as session:
        user = session.query(User).filter_by(username=username).first()
        if user:
            user.role = "admin"
            user.is_active = True
            if password:
                user.password_hash = hash_password(password)
            print(f"Updated existing user '{username}' to admin.")
        else:
            new_user = User(
                username=username,
                password_hash=hash_password(password),
                role="admin",
                is_active=True,
            )
            session.add(new_user)
            print(f"Created new admin user '{username}'.")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python create_admin.py <username> <password>")
        sys.exit(1)

    username_arg = sys.argv[1]
    password_arg = sys.argv[2]

    if len(password_arg) < 8:
        print("Error: Password must be at least 8 characters.")
        sys.exit(1)

    create_admin(username_arg, password_arg)