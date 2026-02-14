#!/bin/bash
set -e

echo "Running migrations..."
/app/bin/recruitment_test eval "RecruitmentTest.Release.migrate()"
echo "Migrations complete!"

echo "Starting application..."
exec /app/bin/recruitment_test start
