#!/usr/bin/env python3
"""Generate bcrypt password hash for demo users"""

from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

password = "demo123"
hashed_password = pwd_context.hash(password)

print(f"Password: {password}")
print(f"Hashed: {hashed_password}")

# Verify it works
print(f"Verification test: {pwd_context.verify(password, hashed_password)}")
