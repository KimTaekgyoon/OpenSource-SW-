#!/bin/bash

# 실험 파라미터 설정
DB_BENCH="./db_bench"
NUM_KEYS=2000000             # 키 수: 200만 개
KEY_SIZE=16
VALUE_SIZE=100
RECORD_SIZE=131              # Key + Value + 메타데이터 포함 추정
WRITE_BUFFER_SIZE=67108864   # 64MB
TARGET_FILE_SIZE_BASE=67108864
MAX_BYTES_FOR_LEVEL_BASE=268435456
DURATION=60                  # 테스트 시간 (초)
REPEAT=5

# 경로 초기화
mkdir -p logs repeat_results
rm -f repeat_results/*

# 공통 함수: 실험 반복 실행
run_experiment() {
  local style=$1        # 0: Leveled, 1: Universal
  local name=$2         # leveled or universal

  echo "▶️ $name 실험 시작 (총 ${REPEAT}회 반복)..."

  local total_bytes=0
  local user_data_bytes=$((NUM_KEYS * RECORD_SIZE))

  for i in $(seq 1 $REPEAT); do
    local db_path="./test_db_${name}_${i}"
    local log_file="logs/${name}_run${i}.txt"

    echo "  🔁 실험 $i ($name)..."
    rm -rf $db_path

    $DB_BENCH \
      --benchmarks="fillrandom" \
      --num=$NUM_KEYS \
      --key_size=$KEY_SIZE \
      --value_size=$VALUE_SIZE \
      --db=$db_path \
      --compaction_style=$style \
      --write_buffer_size=$WRITE_BUFFER_SIZE \
      --target_file_size_base=$TARGET_FILE_SIZE_BASE \
      --max_bytes_for_level_base=$MAX_BYTES_FOR_LEVEL_BASE \
      --compression_type=none \
      --use_direct_io_for_flush_and_compaction=true \
      --use_direct_reads=true \
      --statistics \
      --duration=$DURATION \
      2>&1 | tee $log_file

    # 결과 추출
    bytes_written=$(grep "rocksdb.bytes.written" "$log_file" | awk '{print $4}' | tr -d ,)
    echo "$bytes_written" >> repeat_results/${name}_bytes.txt

    if [[ "$bytes_written" =~ ^[0-9]+$ ]]; then
      waf=$(echo "scale=3; $bytes_written / $user_data_bytes" | bc)
      echo "$waf" >> repeat_results/${name}_waf.txt
      echo "    ✅ WAF: $waf"
    else
      echo "    ❌ WAF 계산 실패"
      echo "0" >> repeat_results/${name}_waf.txt
    fi

    rm -rf $db_path
  done

  # 평균 계산
  avg_bytes=$(awk '{sum += $1} END {if (NR > 0) print int(sum / NR)}' repeat_results/${name}_bytes.txt)
  avg_waf=$(awk '{sum += $1} END {if (NR > 0) printf "%.3f", sum / NR}' repeat_results/${name}_waf.txt)

  echo "📊 [$name] 평균 bytes.written: $avg_bytes bytes"
  echo "📊 [$name] 평균 WAF: $avg_waf"
  echo "----------------------------"
}

# 실험 실행
run_experiment 0 "leveled"
run_experiment 1 "universal"

echo "[DONE] 모든 실험 완료되었습니다."
