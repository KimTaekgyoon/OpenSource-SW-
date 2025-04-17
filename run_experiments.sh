#!/bin/bash

# RocksDB 압축 방식 및 압축 시작 레벨별 성능 측정 자동화 스크립트
# compression_type: zstd, snappy, none
# min_level_to_compress: 0, 2, 4

compression_types=("zstd" "snappy" "none")
min_levels=(0 2 4)

for comp in "${compression_types[@]}"; do
  for lvl in "${min_levels[@]}"; do
    echo "▶️ 실행 중: compression_type=$comp, min_level_to_compress=$lvl"

    ./db_bench \
      --benchmarks=fillrandom \
      --num=500000 \
      --value_size=1000 \
      --key_size=8 \
      --compression_type=$comp \
      --min_level_to_compress=$lvl \
      --statistics=true \
      --stats_interval_seconds=60 \
      --db=/tmp/rocksdb-${comp}-lvl${lvl} \
      > dbbench-${comp}-lvl${lvl}.txt

    echo "✅ 완료: 결과 저장 -> dbbench-${comp}-lvl${lvl}.txt"
    echo "------------------------------------------"
  done
done

echo "✅ 모든 실험이 완료되었습니다. 결과 파일들을 확인하세요."
