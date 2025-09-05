-- Supabase 데이터베이스 스키마 설정
-- 이 SQL을 Supabase Dashboard의 SQL Editor에서 실행하세요

-- MQTT 데이터 저장 테이블
CREATE TABLE IF NOT EXISTS mqtt_data (
  id BIGSERIAL PRIMARY KEY,
  topic TEXT NOT NULL,
  payload TEXT NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 명령 기록 테이블
CREATE TABLE IF NOT EXISTS commands (
  id BIGSERIAL PRIMARY KEY,
  command TEXT NOT NULL,
  source TEXT NOT NULL, -- 'dashboard', 'api', 'manual' 등
  status TEXT DEFAULT 'sent', -- 'sent', 'acknowledged', 'failed'
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  response TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 디바이스 상태 테이블
CREATE TABLE IF NOT EXISTS device_status (
  id BIGSERIAL PRIMARY KEY,
  device_id TEXT NOT NULL,
  status JSONB NOT NULL,
  is_online BOOLEAN DEFAULT false,
  last_seen TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 알림 설정 테이블
CREATE TABLE IF NOT EXISTS alert_settings (
  id BIGSERIAL PRIMARY KEY,
  parameter TEXT NOT NULL,
  threshold_min NUMERIC,
  threshold_max NUMERIC,
  is_enabled BOOLEAN DEFAULT true,
  notification_emails TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스 생성 (성능 최적화)
CREATE INDEX idx_mqtt_data_timestamp ON mqtt_data(timestamp DESC);
CREATE INDEX idx_mqtt_data_topic ON mqtt_data(topic);
CREATE INDEX idx_commands_timestamp ON commands(timestamp DESC);
CREATE INDEX idx_device_status_device_id ON device_status(device_id);

-- Row Level Security (RLS) 활성화
ALTER TABLE mqtt_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE commands ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE alert_settings ENABLE ROW LEVEL SECURITY;

-- RLS 정책 생성 (인증된 사용자만 접근 가능)
CREATE POLICY "Enable read access for all users" ON mqtt_data
  FOR SELECT USING (true);

CREATE POLICY "Enable insert for authenticated users only" ON mqtt_data
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Enable read access for all users" ON commands
  FOR SELECT USING (true);

CREATE POLICY "Enable insert for authenticated users only" ON commands
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Enable all access for authenticated users" ON device_status
  FOR ALL USING (true);

CREATE POLICY "Enable all access for authenticated users" ON alert_settings
  FOR ALL USING (true);

-- Real-time 구독을 위한 Publication 설정
ALTER PUBLICATION supabase_realtime ADD TABLE mqtt_data;
ALTER PUBLICATION supabase_realtime ADD TABLE commands;
ALTER PUBLICATION supabase_realtime ADD TABLE device_status;

-- 트리거 함수: updated_at 자동 업데이트
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 트리거 생성
CREATE TRIGGER update_device_status_updated_at BEFORE UPDATE ON device_status
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_alert_settings_updated_at BEFORE UPDATE ON alert_settings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 데이터 보관 정책 (선택적: 30일 이상 된 데이터 자동 삭제)
-- CREATE OR REPLACE FUNCTION delete_old_mqtt_data()
-- RETURNS void AS $$
-- BEGIN
--   DELETE FROM mqtt_data WHERE timestamp < NOW() - INTERVAL '30 days';
-- END;
-- $$ LANGUAGE plpgsql;

-- 정기적으로 오래된 데이터 삭제 (pg_cron 확장이 필요)
-- SELECT cron.schedule('delete-old-mqtt-data', '0 0 * * *', 'SELECT delete_old_mqtt_data();');