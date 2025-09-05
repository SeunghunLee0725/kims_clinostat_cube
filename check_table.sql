-- 현재 mqtt_data 테이블 구조 확인
SELECT 
  column_name, 
  data_type, 
  is_nullable, 
  column_default
FROM 
  information_schema.columns
WHERE 
  table_name = 'mqtt_data'
ORDER BY 
  ordinal_position;