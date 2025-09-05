-- Drop existing table if needed to recreate with new schema
DROP TABLE IF EXISTS mqtt_data CASCADE;

-- Create table for speed data only
CREATE TABLE mqtt_data (
  id BIGSERIAL PRIMARY KEY,
  device_id VARCHAR(50) NOT NULL DEFAULT 's25007/board1',
  current_spm INTEGER NOT NULL,
  timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better query performance
CREATE INDEX idx_mqtt_data_timestamp ON mqtt_data(timestamp DESC);
CREATE INDEX idx_mqtt_data_device_id ON mqtt_data(device_id);
CREATE INDEX idx_mqtt_data_device_timestamp ON mqtt_data(device_id, timestamp DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE mqtt_data ENABLE ROW LEVEL SECURITY;

-- Create policies for anonymous access
CREATE POLICY "Allow anonymous read access" ON mqtt_data
  FOR SELECT USING (true);

CREATE POLICY "Allow anonymous insert access" ON mqtt_data
  FOR INSERT WITH CHECK (true);

-- Function to clean old data (keeps last 30 days)
CREATE OR REPLACE FUNCTION clean_old_mqtt_data()
RETURNS void AS $$
BEGIN
  DELETE FROM mqtt_data 
  WHERE timestamp < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;

-- Optional: Create view for statistics
CREATE OR REPLACE VIEW mqtt_data_stats AS
SELECT 
  device_id,
  DATE_TRUNC('hour', timestamp) as hour,
  COUNT(*) as data_points,
  MIN(current_spm) as min_spm,
  MAX(current_spm) as max_spm,
  AVG(current_spm)::INTEGER as avg_spm
FROM mqtt_data
GROUP BY device_id, DATE_TRUNC('hour', timestamp)
ORDER BY hour DESC;