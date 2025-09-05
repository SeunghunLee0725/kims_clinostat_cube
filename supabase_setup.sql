-- Create table for MQTT data
CREATE TABLE IF NOT EXISTS mqtt_data (
  id BIGSERIAL PRIMARY KEY,
  topic VARCHAR(255) NOT NULL,
  payload TEXT NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index on timestamp for faster queries
CREATE INDEX IF NOT EXISTS idx_mqtt_data_timestamp ON mqtt_data(timestamp DESC);

-- Create index on topic for filtering
CREATE INDEX IF NOT EXISTS idx_mqtt_data_topic ON mqtt_data(topic);

-- Create table for commands
CREATE TABLE IF NOT EXISTS commands (
  id BIGSERIAL PRIMARY KEY,
  command TEXT NOT NULL,
  source VARCHAR(100),
  status VARCHAR(50) DEFAULT 'sent',
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index on commands timestamp
CREATE INDEX IF NOT EXISTS idx_commands_timestamp ON commands(timestamp DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE mqtt_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE commands ENABLE ROW LEVEL SECURITY;

-- Create policy for anonymous access (adjust based on your security needs)
CREATE POLICY "Allow anonymous read access" ON mqtt_data
  FOR SELECT USING (true);

CREATE POLICY "Allow anonymous insert access" ON mqtt_data
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow anonymous read access" ON commands
  FOR SELECT USING (true);

CREATE POLICY "Allow anonymous insert access" ON commands
  FOR INSERT WITH CHECK (true);

-- Function to clean old data (optional - keeps last 30 days)
CREATE OR REPLACE FUNCTION clean_old_mqtt_data()
RETURNS void AS $$
BEGIN
  DELETE FROM mqtt_data 
  WHERE timestamp < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;

-- Create a scheduled job to clean old data (requires pg_cron extension)
-- Uncomment if you have pg_cron enabled
-- SELECT cron.schedule('clean-mqtt-data', '0 2 * * *', 'SELECT clean_old_mqtt_data();');