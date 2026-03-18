-- Migration 012: Add city column to gyms table

ALTER TABLE gyms 
ADD COLUMN IF NOT EXISTS city TEXT;

CREATE INDEX IF NOT EXISTS idx_gyms_city ON gyms(city);
