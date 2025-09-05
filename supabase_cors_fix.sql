-- Supabase CORS 및 RLS 설정 스크립트
-- mqtt_data 테이블에 대한 접근 권한 설정

-- 1. RLS 비활성화 (테스트 목적)
ALTER TABLE mqtt_data DISABLE ROW LEVEL SECURITY;

-- 또는 RLS를 활성화하되, 모든 사용자에게 INSERT 권한 부여
-- ALTER TABLE mqtt_data ENABLE ROW LEVEL SECURITY;

-- 2. 기존 정책 삭제 (있는 경우)
DROP POLICY IF EXISTS "Enable insert for all users" ON mqtt_data;
DROP POLICY IF EXISTS "Enable read for all users" ON mqtt_data;

-- 3. 새로운 정책 생성 (RLS 활성화 시)
-- 모든 사용자(anonymous 포함)가 데이터 삽입 가능
CREATE POLICY "Enable insert for all users" ON mqtt_data
    FOR INSERT 
    TO anon, authenticated
    WITH CHECK (true);

-- 모든 사용자가 데이터 읽기 가능
CREATE POLICY "Enable read for all users" ON mqtt_data
    FOR SELECT 
    TO anon, authenticated
    USING (true);

-- 4. ANON 키 권한 확인
-- Supabase 대시보드에서 다음 확인:
-- Settings -> API -> anon public key가 제대로 설정되어 있는지
-- Authentication -> Policies -> mqtt_data 테이블 정책 확인