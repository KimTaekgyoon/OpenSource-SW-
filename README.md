# OpenSource-SW-
오픈소스분석 전용 레포지토리


## RocksDB 압축 및 컴팩션 성능 실험

이 리포지토리는 RocksDB의 `compression_type`과 `min_level_to_compress` 설정이 성능에 미치는 영향을 실험한 결과를 기반으로 구성되어 있습니다. `db_bench`를 사용하여 다양한 조합의 설정에서 쓰기 처리량(Throughput), 쓰기 증폭(Write Amplification), 공간 증폭(Space Amplification)을 측정하였습니다.

---

## 실험 목적

- RocksDB의 `min_level_to_compress`, `compression_type` 설정 변경이 성능에 미치는 영향을 파악
- 압축 방식에 따른 WAF, SA, Throughput 비교 분석

---

## 실험 구성 및 실행 방법

### 1. RocksDB 빌드 및 벤치마크 툴 준비

```bash
git clone https://github.com/facebook/rocksdb.git
cd rocksdb
make static_lib db_bench
```

### 2. 벤치마크 스크립트 작성

`run_experiments.sh` 파일을 만들고 아래 내용을 입력합니다:

```bash
#!/bin/bash

# 압축 방식과 압축 시작 레벨을 조합하여 RocksDB 성능 실험 자동화
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
  done
done
```

### 3. 실행 권한 부여 및 실행

```bash
chmod +x run_experiments.sh
./run_experiments.sh
```

위 스크립트는 `compression_type`과 `min_level_to_compress`의 모든 조합에 대해 총 9번의 실험을 자동으로 수행하며, 각각의 결과를 파일로 저장합니다.

---

## 주요 지표 및 결과 요약

| Compression Type | Min Level to Compress | Throughput (ops/sec) | WAF | SA |
|------------------|------------------------|-----------------------|-----|----|
| zstd             | 0                      | 129263                | 1.02| 0.37 |
| zstd             | 2                      | 92307                 | 1.02| 0.77 |
| zstd             | 4                      | 79950                 | 1.02| 0.90 |
| snappy           | 0                      | 148565                | 1.02| 0.50 |
| snappy           | 2                      | 137493                | 1.02| 0.90 |
| snappy           | 4                      | 110295                | 1.02| 0.77 |
| none             | 0                      | 142492                | 1.02| 0.90 |
| none             | 2                      | 138858                | 1.02| 0.90 |
| none             | 4                      | 133008                | 1.02| 0.90 |

---

## 인사이트 요약

- 공간 절약 효과(SA)는 `zstd > snappy > none` 순서로 확인되었음
- 쓰기 처리량(Throughput)은 압축 강도가 낮을수록 높았으며 `none > snappy > zstd`
- WAF는 모든 설정에서 1.02로 동일, compaction 트리거 부족으로 실제 쓰기 증폭 차이는 크지 않았음

---

## 결론 및 추천

- 저장 공간 최적화가 중요한 시스템 → `compression_type=zstd`, `min_level_to_compress=0`
- 쓰기 성능이 중요한 시스템 → `compression_type=snappy` 또는 `none` 추천

---

## 참고
- RocksDB GitHub: https://github.com/facebook/rocksdb
- 공식 벤치마크 문서: https://github.com/facebook/rocksdb/wiki/Performance-Benchmarks

---
