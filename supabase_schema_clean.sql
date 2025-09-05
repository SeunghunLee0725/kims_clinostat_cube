-- Supabase 데이터베이스 스키마 - 속도 데이터만 저장
-- 주의: 이 스크립트는 기존 mqtt_data 테이블을 삭제하고 새로 생성합니다!
-- 기존 데이터가 필요한 경우 먼저 백업하세요.

-- 1. 기존 정책 삭제
DROP POLICY IF EXISTS "Enable read access for all users" ON mqtt_data;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON mqtt_data;
DROP POLICY IF EXISTS "Enable read for all" ON mqtt_data;
DROP POLICY IF EXISTS "Enable insert for all" ON mqtt_data;
DROP POLICY IF EXISTS "Enable read for anon" ON mqtt_data;
DROP POLICY IF EXISTS "Enable insert for anon" ON mqtt_data;
DROP POLICY IF EXISTS "Enable all operations for authenticated users" ON mqtt_data;

-- 2. 기존 인덱스 삭제
DROP INDEX IF EXISTS idx_mqtt_data_timestamp;
DROP INDEX IF EXISTS idx_mqtt_data_topic;
DROP INDEX IF EXISTS idx_mqtt_data_device_timestamp;

-- 3. 기존 테이블 삭제 (주의: 모든 데이터가 삭제됩니다!)
DROP TABLE IF EXISTS mqtt_data CASCADE;

-- 4. 새로운 속도 데이터 전용 테이블 생성
CREATE TABLE mqtt_data (
  id BIGSERIAL PRIMARY KEY,
  device_id VARCHAR(50) NOT NULL DEFAULT 's25007/board1',
  current_spm INTEGER NOT NULL,
  timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 5. 새로운 인덱스 생성 (빠른 조회를 위함)
CREATE INDEX idx_mqtt_data_timestamp ON mqtt_data(timestamp DESC);
CREATE INDEX idx_mqtt_data_device_timestamp ON mqtt_data(device_id, timestamp DESC);

-- 6. Row Level Security 활성화
ALTER TABLE mqtt_data ENABLE ROW LEVEL SECURITY;

-- 7. 새로운 정책 생성 (모든 사용자가 읽고 쓸 수 있도록)
CREATE POLICY "Enable read for all" ON mqtt_data
  FOR SELECT USING (true);

CREATE POLICY "Enable insert for all" ON mqtt_data
  FOR INSERT WITH CHECK (true);

-- 8. Real-time 구독을 위한 Publication 설정 (이미 존재하면 무시)
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE mqtt_data;
EXCEPTION
  WHEN duplicate_object THEN
    -- Already exists, do nothing
    NULL;
END $$;

-- 9. 30일 이상 된 데이터를 자동 삭제하는 함수
CREATE OR REPLACE FUNCTION delete_old_mqtt_data()
RETURNS void AS $$
BEGIN
  DELETE FROM mqtt_data WHERE timestamp < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;

-- 10. 테스트용 샘플 데이터 삽입 (선택사항 - 주석 해제하여 실행)
-- INSERT INTO mqtt_data (device_id, current_spm) VALUES 
-- ('s25007/board1', 100),
-- ('s25007/board1', 150),
-- ('s25007/board1', 200);

-- 11. 테이블 구조 확인
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_name = 'mqtt_data'
-- ORDER BY ordinal_position;

-- 성공 메시지
DO $$
BEGIN
  RAISE NOTICE 'mqtt_data 테이블이 성공적으로 생성되었습니다.';
  RAISE NOTICE '컬럼: id, device_id, current_spm, timestamp, created_at';
END $$;